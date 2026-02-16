package scriptable;

import Lua.LuaDefines;
import Lua.LuaStatus;
import Lua.LuaType;
import Lua.State;
import LuaCode.CompileOptions;
import Lualib;
import haxe.io.Path;
import openfl.utils.Assets;

// Parameter type for callLuau().
typedef CallParameter =
{
	var type:String; // type of the parameter
	var value:Dynamic; // the parameter value itself
}

class LuaVM
{
	public var L(default, null):Lua.State;

	private var _assetsDir:String;

	public function new(assetsDir:String)
	{
		_assetsDir = assetsDir;

		var luaPath = Sys.getEnv("LUA_PATH");
		if (luaPath != null)
		{
			trace('Setting LUA_PATH to: ${luaPath}');
		}
		else
		{
			trace('LUA_PATH not set');
		}
		L = Lua.newstate();
		dumpStack();
		var cbks = new RequireCallbacks();
		cbks.isRequireAllowed = Requirer.isRequireAllowed;
		cbks.reset = Requirer.reset;
		cbks.to_parent = Requirer.toParent;
		cbks.to_child = Requirer.toChild;
		cbks.is_module_present = Requirer.isModulePresent;
		cbks.get_chunkname = Requirer.getChunkname;
		cbks.get_loadname = Requirer.getLoadname;
		cbks.get_cache_key = Requirer.getCacheKey;
		cbks.load = Requirer.load;
		Require.openrequire(L, cbks, new RequireCtx());
		dumpStack();
		Lualib.openlibs(L);
		dumpStack();
		#if GAME_DEBUG
		// Note debug library occupies stack slot 1 and so the top of stack
		// is never 0 after this is loaded.
		Lualib.opendebug(L);
		trace('Finished loading Lua libraries, gettop=${Lua.gettop(L)}');
		#end
	}

	public function loadScript(script:String):Void
	{
		var scriptPath = new Path(script);
		if (scriptPath.dir != null)
		{
			throw 'Script name must not contain a path.';
		}
		_loadScript("scripts", script);
	}

	function _errHandler(L:State):Int
	{
		var msg = Lua.tostring(L, -1);
		trace('initial message=${msg}');
		// Get debug.traceback function
		// If debug is not loaded, and it shouldn't be in production,
		// this debug function will not run.
		var t = Lua.getglobal(L, "debug");
		if (t != LuaType.TABLE)
		{
			trace('debug is not a table');
			// return with original error message still on stack
			Lua.pop(L, 1); // remove the getglobal error value
			return 1;
		}

		Lua.getfield(L, -1, "traceback");
		if (Lua.isfunction(L, -1) != 1)
		{
			trace('debug.traceback is not a function');
			Lua.pop(L, 2); // remove the getfield error value and debug table
			return 1;
		}

		Lua.pushvalue(L, 1); // Pass the original error message to traceback
		Lua.pushinteger(L, 2); // Level 2: skip the traceback function itself
		Lua.call(L, 2, 1); // Call traceback(msg, 2)
		Lua.remove(L, -2); // Remove the debug table

		msg = Lua.tostring(L, -1);
		trace('post-errhandler message=${msg}');

		return 1; // number of return values
	}

	function _loadScript(scriptPath:String, scriptName:String)
	{
		var fullScriptPath = '${_assetsDir}/${scriptPath}/${scriptName}';
		var s = Assets.getText(fullScriptPath);
		trace('Lua script (${fullScriptPath}) is:\n${s}');

		Lua.pushcfunction(L, _errHandler, "errHandler");

		var options:CompileOptions = CompileOptions.create();
		options.debugLevel = 2;

		var byteCode = LuaCode.compile(s, s.length, options);
		trace('bytecode length: ${byteCode.size}');
		var r = Lua.load(L, fullScriptPath, byteCode, 0);
		if (r != LuaStatus.OK)
		{
			trace('Error loading chunk: ${Lua.tostring(L, -1)}');
			Lua.pop(L, 1); // remove error message
			Sys.exit(1);
		}

		var pcallStatus = Lua.pcall(L, 0, 1, -2); // call the loaded chunk
		if (pcallStatus != LuaStatus.OK)
		{
			trace('Error loading chunk: ${Lua.tostring(L, -1)}');
			Lua.pop(L, 1); // remove error message
			// FIXME - raise exception or just exit ?
		}
		Lua.pop(L, 2); // remove return value
	}

	/**
	 * Call a Luau function with a list of arguments.
	 * Currently this expects the function to NOT return anything.
	 * @param functionName the absolute dotted name of the function to call
	 * @param args an Array of CallParameter objects. Parameters must be in
	 * the order required by functionName.
	 */
	public function callLuau(functionName:String, args:Array<CallParameter>)
	{
		Lua.pushcfunction(L, _errHandler, "errHandler");

		// trace('pushing function name ' + functionName);
		getDottedName(L, functionName);

		// trace('pushing ${args.length} arguments');
		for (arg in args)
		{
			switch (arg.type)
			{
				case "luaGetField":
					// trace('pushing getfield ' + cast(arg.value, String));
					getDottedName(L, cast(arg.value, String));
				case "number":
					// trace('pushing number ' + cast(arg.value, Float));
					Lua.pushnumber(L, cast(arg.value, Float));
				case "string":
					// trace('pushing string ' + cast(arg.value, String));
					Lua.pushstring(L, cast(arg.value, String));
				case "boolean":
					// trace('pushing boolean ' + cast(arg.value, Bool));
					Lua.pushboolean(L, cast(arg.value, Bool));
				default:
					throw 'Unknown argument type: ${arg.type}';
			}
		}

		var pcallStatus = Lua.pcall(L, args.length, 0, -(args.length + 2));
		if (pcallStatus != LuaStatus.OK)
		{
			trace('Error calling function: ${Lua.tostring(L, -1)}');
			Lua.pop(L, 1); // remove error message
			// FIXME - raise exception or just exit ?
		}
		Lua.pop(L, 1); // pop errorhandler
		#if GAME_DEBUG
		trace('Finished calling Lua function: ${functionName}, gettop=${Lua.gettop(L)}');
		#end
	}

	public function shutdown():Void
	{
		Lua.close(L);
		L = null;
	}

	/**
	 * Get a dotted name from the Lua state. Leaving the first part and the
	 * final part on the stack - this should be game. All intermediate parts
	 * are removed.
	 * @param L 
	 * @param dottedName 
	 */
	public function getDottedName(L:State, dottedName:String):Void
	{
		var parts = dottedName.split(".");
		var nameSoFar = "";
		for (idx => part in parts)
		{
			if (idx == 0)
			{
				var rv = Lua.getglobal(L, part);
				if (rv != LuaType.TABLE)
				{
					// Pop error return failure
					Lua.pop(L, 1);
					throw 'Could not find global name part: ${part} in ${dottedName}';
				}
				nameSoFar = part;
				continue;
			}
			var rv = Lua.getfield(L, -1, part);
			if (rv == LuaType.NIL)
			{
				// Pop error return failure
				Lua.pop(L, idx + 1);
				throw 'Could not find dotted name part: ${part} in ${nameSoFar}';
			}
			nameSoFar += "." + part;
			if (idx > 0)
			{
				Lua.remove(L, -2);
			}
		}
	}

	// FIXME this is massively hacky - and no error checking
	public function dump(dottedName:String):Void
	{
		// @formatter:off
		callLuau("game.utils.dumpTable", [
			{"type" : "string", "value" : dottedName},
			{"type" : "number", "value" : 0}
		]);
		// @formatter:on
	}

	public function dumpStack():Void
	{
		var top = Lua.gettop(L);
		trace('Lua stack (top=${top}):');
		for (i in 1...top + 1)
		{
			var t = cast(Lua.type(L, i), Int);
			if (t == LuaType.NIL)
				trace('  ${i}: nil');
			else if (t == LuaType.BOOLEAN)
			{
				var v = Lua.toboolean(L, i);
				trace('  ${i}: type=${t}, value=${v}');
			}
			else if (t == LuaType.NUMBER)
			{
				var v = Lua.tonumber(L, i);
				trace('  ${i}: type=${t}, value=${v}');
			}
			else if (t == LuaType.STRING)
			{
				var v = Lua.tostring(L, i);
				trace('  ${i}: type=${t}, value=${v}');
			}
			else if (t == LuaType.FUNCTION)
			{
				trace('  ${i}: type=${t}, function');
			}
			else if (t == LuaType.TABLE)
			{
				trace('  ${i}: type=${t}, table');
			}
			else
			{
				trace('  ${i}: type=${t}');
			}
		}
	}
}
