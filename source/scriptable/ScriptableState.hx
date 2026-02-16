package scriptable;

import Lua.LuaStatus;
import Lua.LuaType;
import Lua.State;
import LuaCode.CompileOptions;
import flixel.FlxG;
import flixel.FlxState;
import scriptable.ScriptableGame;

@:autoBuild(scriptable.Macros.createLuaHelperFns())
abstract class ScriptableState extends FlxState implements IScriptable
{
	var _assetsDir:String;

	var _L:State;

	var _debugScript:String;

	var _syncedFields:Array<String>;

	var _dottedName:String;
	var _parent:String;

	public function new(assetsDir:String, parent:String, name:String)
	{
		super();
		_assetsDir = assetsDir;
		_syncedFields = new Array<String>();
		_parent = parent;
		_dottedName = '${parent}.${name}';

		initLuaState(); // FIXME is this even a good idea - better to refer to the VM directly ?
		FlxG.signals.postStateSwitch.add(() -> initLua(_L, parent, name));
	}

	/**
	 * Once `create()` completes the Lua.State object will be initialized
	 * in the _L member variable. No Lua operations should be attempted
	 * in the subclass before this has been completed.
	 */
	override public function create()
	{
		super.create();
	}

	function initLuaState():Void
	{
		/* initialize Lua */
		_L = ScriptableGame.luaVM.L;
	}

	/**
	 * Subclasses will implement this indirectly via macros and metadata
	 * to control what member fields are replicated to Lua.
	 */
	abstract function setHaxeFunctions(L:State, dottedName:String):Void;

	abstract function updateLuaFields(L:State, dottedName:String):Void;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		// updateToLua(_L);

		// Check for hot-reload of scripts
		// if (FlxG.keys.justReleased.R && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.CONTROL)
		// {
		// 	Sys.println('Reloading Lua state');
		// 	_reloadLua();
		// }
		updateFromLua(_L);
	}

	public function initLua(L:State, parent:String, name:String)
	{
		// @formatter:off
		ScriptableGame.luaVM.callLuau("game.utils.newPongState", [
			{"type": "string", "value": "PongState"},
			{"type": "number", "value": 0}
		]);
		// @formatter:on
		// ScriptableGame.luaVM.getDottedName(ScriptableGame.luaVM.L, _dottedName);

		setHaxeFunctions(L, "game.state");

		// Put the table fields here
		updateFlxGValues(L);

		ScriptableGame.luaVM.dump('game');

		// Now add the paddles and ball
		// @formatter:off
		ScriptableGame.luaVM.callLuau("game.utils.newPaddle", [
			{"type": "string", "value": "leftPaddle"},
			{"type": "number", "value": 0}
		]);

		ScriptableGame.luaVM.callLuau("game.utils.newPaddle", [
				{"type": "string", "value": "rightPaddle"},
				{"type": "number", "value": 0}
		]);

		ScriptableGame.luaVM.callLuau("game.utils.newBall", [
			{"type": "string", "value": "ball"},
			{"type": "number", "value": 0}
		]);
		// @formatter:on
		trace('Dumping Lua state after creating paddles and ball:');
		ScriptableGame.luaVM.dump('game');

		updateToLua(_L);
	}

	/**
	 * Update the tables values to Lua.
	 * This assumes the FlxG table is on top of the stack, and that the caller
	 * will pop it.
	 * @param L 
	 */
	function updateFlxGValues(L:State):Void
	{
		// FIXME - we need a way to trigger specific fields to be updated when
		// they change rather than push every value every frame.For example
		// the width and height are constant so no need to push them every
		// frame.
		// Push global state values
		// var globals = ['leftPaddle' => _leftPaddle, 'rightPaddle' => _rightPaddle, "ball" => _ball];

		// for (k => v in globals.keyValueIterator())
		// {
		// 	Lua.pushstring(L, k);
		// 	Lua.pushnumber(L, v);
		// 	Lua.settable(L, -3);
		// }
	}

	public function updateToLua(L:State) {}

	public function updateFromLua(L:State) {}

	public function destroyLua() {}
}
