package scriptable;

import haxe.io.Path;
import sys.FileSystem;

using StringTools;

/**
 * Virtual File System Navigator.
 * This class simulates navigation through a virtual file system for module
 * resolution.
 */
/**
 * Navigation status enumeration.
 */
enum NavigationStatus
{
	Success;
	Ambiguous;
	NotFound;
}

/**
 * Virtual File System Navigator.
 * This class is modelled on the Luau CLI VFSNavigator from its Requirer.
 * At present it's basically a port to Haxe. Thus a good deal of it is
 * not really required, and likely isn't even used in the current tests.
 */
class FlixelNavigator
{
	var realPath:String;
	var absoluteRealPath:String;
	var absolutePathPrefix:String;
	var modulePath:String;
	var absoluteModulePath:String;

	public function new()
	{
		// Constructor
	}

	public function resetToStdIn():NavigationStatus
	{
		var cwd = Sys.getCwd();
		if (cwd == null)
			return NotFound;

		realPath = "./stdin";
		absoluteRealPath = normalizePath(cwd + "/stdin");
		modulePath = "./stdin";
		absoluteModulePath = getModulePath(absoluteRealPath);

		var firstSlash = absoluteRealPath.indexOf("/");
		if (firstSlash == -1)
			throw "Assertion failed";
		absolutePathPrefix = absoluteRealPath.substr(0, firstSlash);

		return Success;
	}

	public function resetToPath(path:String):NavigationStatus
	{
		var normalizedPath = normalizePath(path);

		if (isAbsolutePath(normalizedPath))
		{
			modulePath = getModulePath(normalizedPath);
			absoluteModulePath = modulePath;

			var firstSlash = normalizedPath.indexOf("/");
			if (firstSlash == -1)
				throw "Assertion failed";
			absolutePathPrefix = normalizedPath.substr(0, firstSlash);
		}
		else
		{
			var cwd = Sys.getCwd();
			if (cwd == null)
				return NotFound;

			modulePath = getModulePath(normalizedPath);
			var joinedPath = normalizePath(cwd + "/" + normalizedPath);
			absoluteModulePath = getModulePath(joinedPath);

			var firstSlash = joinedPath.indexOf("/");
			if (firstSlash == -1)
				throw "Assertion failed";
			absolutePathPrefix = joinedPath.substr(0, firstSlash);
		}

		return updateRealPaths();
	}

	public function toParent():NavigationStatus
	{
		if (absoluteModulePath == "/")
			return NotFound;

		var numSlashes = 0;
		for (i in 0...absoluteModulePath.length)
		{
			if (absoluteModulePath.charAt(i) == '/')
				numSlashes++;
		}
		// TEMP FIX: allow no slashes
		// if (numSlashes == 0)
		// 	throw "Assertion failed";
		if (numSlashes == 1)
			return NotFound;

		modulePath = normalizePath(modulePath + "/..");
		absoluteModulePath = normalizePath(absoluteModulePath + "/..");

		return updateRealPaths();
	}

	public function toChild(name:String):NavigationStatus
	{
		modulePath = normalizePath(modulePath + "/" + name);
		absoluteModulePath = normalizePath(absoluteModulePath + "/" + name);

		return updateRealPaths();
	}

	public function getFilePath():String
	{
		return realPath;
	}

	public function getAbsoluteFilePath():String
	{
		return absoluteRealPath;
	}

	public function getLuaurcPath():String
	{
		var directory = realPath;

		var suffixes = ["/init.luau", "/init.lua"];
		for (suffix in suffixes)
		{
			if (directory.endsWith(suffix))
			{
				directory = directory.substr(0, directory.length - suffix.length);
				return directory + "/.luaurc";
			}
		}
		var suffixes2 = [".luau", ".lua"];
		for (suffix in suffixes2)
		{
			if (directory.endsWith(suffix))
			{
				directory = directory.substr(0, directory.length - suffix.length);
				return directory + "/.luaurc";
			}
		}

		return directory + "/.luaurc";
	}

	function updateRealPaths():NavigationStatus
	{
		var result = getRealPath(modulePath);
		if (result.status != Success)
		{
			#if HXLUAU_DEBUG
			trace('failed to get modulePath ${result.realPath}');
			#end
			return result.status;
		}

		var absoluteResult = getRealPath(absoluteModulePath);
		if (absoluteResult.status != Success)
		{
			#if HXLUAU_DEBUG
			trace('failed to get absoluteModulePath ${absoluteResult.realPath}');
			#end
			return absoluteResult.status;
		}

		realPath = isAbsolutePath(result.realPath) ? absolutePathPrefix + result.realPath : result.realPath;
		absoluteRealPath = absolutePathPrefix + absoluteResult.realPath;
		#if HXLUAU_DEBUG
		trace('absoluteRealPath=${absoluteRealPath}');
		#end
		return Success;
	}

	static function getRealPath(modulePath:String):{status:NavigationStatus, realPath:String}
	{
		var found = false;
		var suffix = "";

		#if HXLUAU_DEBUG
		trace('modulePath=${modulePath}');
		#end
		var lastSlash = modulePath.lastIndexOf("/");
		// TEMP FIX: allow no slashes
		// if (lastSlash == -1)
		// 	throw "Assertion failed";
		var lastComponent = modulePath.substr(lastSlash + 1);

		// FIXME - this does not handle the case where the require stmt
		//         inludes the extension.
		//             eg. local Animal = require('./Animal.luau')
		if (lastComponent != "init")
		{
			var suffixes = [".luau", ".lua"];
			for (potentialSuffix in suffixes)
			{
				var fullPath = modulePath + potentialSuffix;
				if (FileSystem.exists(fullPath) && !FileSystem.isDirectory(fullPath))
				{
					if (found)
						return {status: Ambiguous, realPath: ""};
					suffix = potentialSuffix;
					found = true;
				}
			}
		}
		if (FileSystem.exists(modulePath) && FileSystem.isDirectory(modulePath))
		{
			if (found)
				return {status: Ambiguous, realPath: ""};
			var suffixes = ["/init.luau", "/init.lua"];
			for (potentialSuffix in suffixes)
			{
				var fullPath = modulePath + potentialSuffix;
				if (FileSystem.exists(fullPath) && !FileSystem.isDirectory(fullPath))
				{
					if (found)
						return {status: Ambiguous, realPath: ""};
					suffix = potentialSuffix;
					found = true;
				}
			}
			found = true;
		}

		if (!found)
			return {status: NotFound, realPath: ""};

		return {status: Success, realPath: modulePath + suffix};
	}

	static function getModulePath(filePath:String):String
	{
		var path = new Path(filePath);
		path.backslash = false;
		filePath = path.toString();

		if (isAbsolutePath(filePath))
		{
			var firstSlash = filePath.indexOf("/");
			if (firstSlash == -1)
				throw "Assertion failed";
			filePath = filePath.substr(firstSlash);
		}

		var suffixes = ["/init.luau", "/init.lua"];
		for (suffix in suffixes)
		{
			if (filePath.endsWith(suffix))
			{
				return filePath.substr(0, filePath.length - suffix.length);
			}
		}
		var suffixes2 = [".luau", ".lua"];
		for (suffix in suffixes2)
		{
			if (filePath.endsWith(suffix))
			{
				return filePath.substr(0, filePath.length - suffix.length);
			}
		}

		return filePath;
	}

	static function normalizePath(path:String):String
	{
		return Path.normalize(path);
	}

	static function isAbsolutePath(path:String):Bool
	{
		return Path.isAbsolute(path);
	}
}
