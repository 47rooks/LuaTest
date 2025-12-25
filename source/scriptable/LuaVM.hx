package scriptable;

import Lua.LuaDefines;
import Lua.LuaStatus;
import Lua.LuaType;
import Lua.State;
import LuaCode.CompileOptions;
import haxe.io.Path;
import openfl.utils.Assets;

class LuaVM
{
	public var L(default, null):Lua.State;

	private var _assetsDir:String;

	public function new(assetsDir:String)
	{
		_assetsDir = assetsDir;

		L = Lua.newstate();
		loadScriptableLib();
	}

	function loadScriptableLib()
	{
		var libs = ["ScriptableState.lua", "ScriptableSprite.lua"];

		for (l in libs)
		{
			_loadScript("scriptable", l);
		}
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

	function _loadScript(scriptPath:String, scriptName:String)
	{
		var s = Assets.getText('${_assetsDir}/${scriptPath}/${scriptName}');
		trace('Lua script is:\n${s}');
		// LuaL.dostring(_L, s);
		// Cannot pass null so use an empty struct.
		// Cannot instantiate {} directly as call site, so use a local variable.
		var options:CompileOptions = {};

		var byteCode = LuaCode.compile(s, s.length, options);
		trace('bytecode length: ${byteCode.size}');
		var r = Lua.load(L, "code", byteCode, 0);
		if (r != LuaStatus.OK)
		{
			trace('Error loading chunk: ${Lua.tostring(L, -1)}');
			Lua.pop(L, 1); // remove error message
			Sys.exit(1);
		}
		Lua.call(L, 0, 1); // call the loaded chunk
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
		for (idx => part in parts)
		{
			if (idx == 0)
			{
				var rv = Lua.getglobal(L, part);
				if (rv != LuaType.TABLE)
				{
					// Pop error return failure
					Lua.pop(L, 1);
					throw 'Could not find dotted name part: ${part} in ${dottedName}';
				}
				continue;
			}
			var rv = Lua.getfield(L, -1, part);
			if (rv == LuaDefines.NONE)
			{
				// Pop error return failure
				Lua.pop(L, 2);
				throw 'Could not find dotted name part: ${part} in ${dottedName}';
			}
			if (idx > 0)
			{
				Lua.remove(L, -2);
			}
		}
	}
}
