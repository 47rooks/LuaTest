package;

import ScriptableState.LuaStateRef;
import ScriptableState.StdVector;
import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.Types.LuaL_Reg;
import hxluajit.Types.Lua_State;
import openfl.utils.Assets;

class Paddle extends ScriptableSprite
{
	public function new(L:LuaStateRef, name:String, assetsDir:String, x:Float = 0.0, y:Float = 0.0)
	{
		super(L, name, assetsDir, x, y);

		_initLua();
	}

	function _initLua():Void
	{
		// Load library script
		// var s = Assets.getText('${_assetsDir}/scripts/Paddle.lua');
		// LuaL.dostring(_L, s); // FIXME this is going to be done twice - how do we make it idempotent or check and not do it if it's been done.

		// Register callbacks
		registerFunctions();
	}
}
