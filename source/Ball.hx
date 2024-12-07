package;

import ScriptableState.LuaStateRef;
import ScriptableState.StdVector;
import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.Types.LuaL_Reg;
import hxluajit.Types.Lua_State;
import openfl.utils.Assets;

class Ball extends ScriptableSprite
{
	public function new(L:LuaStateRef, name:String, assetsDir:String, x:Float = 0.0, y:Float = 0.0)
	{
		super(L, name, assetsDir, x, y);

		_initLua();
	}

	function _initLua():Void
	{
		// Load library script
		// var s = Assets.getText('${_assetsDir}/scripts/Ball.lua');
		// LuaL.dostring(_L, s);

		// Register callbacks
		registerFunctions();
	}
}
