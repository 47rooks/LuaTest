package;

import flixel.util.typeLimit.NextState;
import scriptable.ScriptableGame;

class Game extends ScriptableGame
{
	final ASSETS_DIR = 'assets';
	final LUA_SCRIPT = 'game.lua';

	public function new(width:Int, height:Int, ?initialState:InitialState, updateFramerate:Int = 60, drawFramerate = 60, skipSplash:Bool = false,
			startFullscreen = false)
	{
		super(width, height, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen, ASSETS_DIR, LUA_SCRIPT);
	}
}
