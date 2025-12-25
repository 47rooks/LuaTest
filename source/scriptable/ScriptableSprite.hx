package scriptable;

import Lua.State;
import flixel.FlxSprite;

@:autoBuild(scriptable.Macros.createType())
class ScriptableSprite extends FlxSprite implements IScriptable
{
	var _Lname:String;
	var _assetsDir:String;
	var _L:State;
	var _syncedFields:Array<String>;
	var _dottedName:String;
	var _parent:String;
	var _scriptName:String;

	public function new(L:State, assetsDir:String, parent:String, name:String, scriptName:String, x:Float = 0.0, y:Float = 0.0)
	{
		super(x, y);
		_L = L;
		_assetsDir = assetsDir;
		_dottedName = '${parent}.${name}';
		_parent = parent;
		_scriptName = scriptName;

		initLua(L, parent, name);
	}

	public function setX(x:Float):Void
	{
		this.x = x;
	}

	public static function f(L:State):Int
	{
		final n:Int = Lua.gettop(L);

		/* loop through each argument */
		var k:String = '';
		var v_x:Float = 0.0;
		var v_y:Float = 0.0;

		for (i in 0...n)
		{
			switch (i + 1)
			{
				case 1:
					k = Lua.tostring(L, 1);
				case 2:
					v_x = Lua.tonumber(L, 2);
				case 3:
					v_y = Lua.tonumber(L, 3);
				case _:
					Lua.pushstring(L, 'Incorrect argument ${i + 1}');
					Lua.error(L);
			}
		}

		Lua.pop(L, n); /* clear the stack */

		return 0;
	}

	public function initLua(L:State, parent:String, name:String)
	{
		ScriptableGame.luaVM.getDottedName(ScriptableGame.luaVM.L, _parent);

		// Push this table
		Lua.pushstring(L, name);
		Lua.newtable(L);
		// // Put the table fields here
		// updateFlxGValues(L);
		// registerFunctions(L);

		Lua.settable(L, -3);

		Lua.pop(L, 1); // pop parent table

		// Push the sprite's script
		// FIXME UP TO HERE
	}

	public function updateToLua(L:State)
	{
		// Find the table in Lua state and update its field values
		ScriptableGame.luaVM.getDottedName(L, _dottedName);

		// Push the latest values
		// FIXME these need to come from the subclass via macro meta
		var values = ['x' => x, 'y' => y];

		for (k => v in values.keyValueIterator())
		{
			Lua.pushstring(L, k);
			Lua.pushnumber(L, v);
			Lua.settable(L, -3);
		}

		Lua.pop(L, 1); // pop parent table
	}

	public function updateFromLua(L:State) {}

	public function destroyLua() {}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		updateToLua(_L);
	}
}
