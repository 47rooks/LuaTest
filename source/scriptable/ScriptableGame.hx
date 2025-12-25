package scriptable;

import Lua.State;
import flixel.FlxGame;
import flixel.util.typeLimit.NextState;
import openfl.Lib;
import scriptable.LuaVM;

class ScriptableGame extends FlxGame implements IScriptable
{
	public static var luaVM(default, null):LuaVM;

	private var luaFlxG:scriptable.ScriptableG.FlxG;

	public function new(width:Int, height:Int, ?initialState:InitialState, updateFramerate:Int = 60, drawFramerate = 60, skipSplash:Bool = false,
			startFullscreen = false, assetsDir:String, script:String)
	{
		super(width, height, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);

		Lib.current.stage.application.onExit.add(onExitHandler);

		luaVM = new LuaVM(assetsDir);
		luaVM.loadScript(script);
		luaFlxG = new scriptable.ScriptableG.FlxG();
		luaFlxG.initLua(luaVM.L, "game", "FlxG");
	}

	public function onExitHandler(_):Void
	{
		trace('shutting down VM');
		luaVM.shutdown();
		Lib.current.stage.application.onExit.remove(onExitHandler);
	}

	/**
	 * To facilitate the reloading of the Lua state this function is
	 * called before the existing LuaState is destroyed and a new one
	 * is created. Subclasses may override this and save any state they
	 * need so that it may be reasserted to the new LuaState in the
	 * `postLuaReload()` method.
	 */
	function preLuaReload():Void {}

	/**
	 * This function may be overriden by subclasses to reassert their desired
	 * Lua state after the LuaState has been recreated. If desired subclasses
	 * may save state before the existing state is destroyed by overiding
	 * `preLuaReload()` to store whatever may be necessary.
	 */
	function postLuaReload():Void {}

	// FIXME Reload functionality needs a lot of work.
	// function _reloadLua():Void
	// {
	// 	preLuaReload();
	// 	Lua.close(luaVM.L);
	// 	Lib.current.stage.application.onExit.remove(onExitHandler);
	// 	initLuaState();
	// 	postLuaReload();
	// }

	public function initLua(L:State, parent:String, name:String) {}

	public function updateToLua(L:State) {}

	public function updateFromLua(L:State) {}

	public function destroyLua() {}

	override public function update():Void
	{
		super.update();
		luaFlxG.updateToLua(luaVM.L);
	}
}
