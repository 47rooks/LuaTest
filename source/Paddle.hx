package;

import Lua.State;
import openfl.utils.Assets;
import scriptable.ScriptableSprite;

class Paddle extends ScriptableSprite
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
		// var s = Assets.getText('${_assetsDir}/scripts/Paddle.lua');
		// LuaL.dostring(_L, s); // FIXME this is going to be done twice - how do we make it idempotent or check and not do it if it's been done.

		// Register callbacks
		createType(_L);
	}
}
