package scriptable;

import Lua.LuaDefines;
import Lua.LuaType;
import Lua.State;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;
import haxe.ValueException;

@:autoBuild(scriptable.Macros.createLuaHelperFns())
abstract class ScriptableG implements IScriptable
{
	public function new() {}

	public abstract function initLua(L:State, parent:String, name:String):Void;

	public abstract function updateToLua(L:State):Void;

	public abstract function destroyLua():Void;
}

class FlxG extends ScriptableG
{
	var _dottedName:String = null;

	public function new()
	{
		super();
	}

	@:luaCallback()
	public function keyPressed(L:State):Int
	{
		{
			final n:Int = Lua.gettop(L);

			/* loop through each argument */
			var key:String = '';

			key = Lua.tostring(L, 1);

			Lua.pop(L, n); /* clear the stack */

			if (flixel.FlxG.keys.checkStatus(FlxKey.fromString(key), FlxInputState.PRESSED))
			{
				return 1;
			}

			return 0;
		}
	}

	public function initLua(L:State, parent:String, name:String):Void
	{
		pushObject(L, parent, name);
	}

	function pushObject(L:State, parent:String, name:String):Void
	{
		if (_dottedName != null)
		{
			// FIXME - at some point in the future we could auto-move
			//         but not now.
			throw 'ScriptableG.FlxG already initialized as ${_dottedName}';
		}
		if (parent != null)
		{
			_dottedName = '${parent}.${name}';
			// getDottedName(L, parent); // get the parent table
		}
		else
		{
			throw new ValueException("parent may not be null");
		}

		setHaxeFunctions(L, _dottedName);
	}

	public function updateToLua(L:State):Void
	{
		ScriptableGame.luaVM.getDottedName(L, _dottedName);
		updateFlxGValues(L);
		Lua.pop(L, 1); // pop FlxG table
	}

	/**
	 * Update the tables values to Lua.
	 * This assumes the FlxG table is on top of the stack, and that the caller
	 * will pop it.
	 * @param L 
	 */
	public function updateFlxGValues(L:State):Void
	{
		// FIXME - we need a way to trigger specific fields to be updated when
		// they change rather than push every value every frame.For example
		// the width and height are constant so no need to push them every
		// frame.
		// Push global state values
		var globals = ['width' => flixel.FlxG.width, 'height' => flixel.FlxG.height];

		for (k => v in globals.keyValueIterator())
		{
			Lua.pushstring(L, k);
			Lua.pushnumber(L, v);
			Lua.settable(L, -3);
		}
	}

	public function updateFromLua(L:State):Void {}

	public function destroyLua() {}
}
