package;

import Lua.State;
// import openfl.utils.Assets;
import scriptable.ScriptableSprite;

class Ball extends ScriptableSprite
{
	final SCRIPT_NAME = "ball.lua";

	public function new(L:State, assetsDir:String, parent:String, name:String, x:Float = 0.0, y:Float = 0.0)
	{
		super(L, assetsDir, parent, name, SCRIPT_NAME, x, y);

		_initLua();
	}

	function _initLua():Void
	{
		// Load library script
		// var s = Assets.getText('${_assetsDir}/scripts/Ball.lua');
		// LuaL.dostring(_L, s);

		// Register callbacks
		createType(_L);
	}
}
