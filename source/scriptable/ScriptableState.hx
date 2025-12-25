package scriptable;

import Lua.LuaStatus;
import Lua.State;
import LuaCode.CompileOptions;
import flixel.FlxG;
import flixel.FlxState;
import scriptable.ScriptableGame;

@:autoBuild(scriptable.Macros.createType())
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
		initLua(_L, parent, name);
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
	abstract function createType(L:State):Void;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		updateToLua(_L);

		if (FlxG.keys.justReleased.G)
		{
			// Dump values from Lua
			// Lua.dostring(_L, _debugScript);

			// Cannot pass null so use an empty struct.
			// Cannot instantiate {} directly as call site, so use a local variable.
			var options:CompileOptions = {};

			var byteCode = LuaCode.compile(_debugScript, _debugScript.length, options);
			trace('bytecode length: ${byteCode.size}');
			var r = Lua.load(_L, "code", byteCode, 0);
			if (r != LuaStatus.OK)
			{
				trace('Error loading chunk: ${Lua.tostring(_L, -1)}');
				Lua.pop(_L, 1); // remove error message
				Sys.exit(1);
			}
			Lua.call(_L, 0, 1); // call the loaded chunk
		}

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
		ScriptableGame.luaVM.getDottedName(ScriptableGame.luaVM.L, _parent);

		// Push this table
		Lua.pushstring(L, name);
		Lua.newtable(L);

		// // Put the table fields here
		updateFlxGValues(L);
		// registerFunctions(L); // FIXME this needs to be an abstract method
		//       in this class and macro gen in subs.

		Lua.settable(L, -3);

		Lua.pop(L, 1); // pop parent table
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
