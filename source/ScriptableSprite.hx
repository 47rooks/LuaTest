package;

import ScriptableState.LuaStateRef;
// import ScriptableState.LuaStateRef; // FIXME looks like this is defined in the wrong place
import cpp.RawPointer;
import flixel.FlxSprite;
import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.Types;

@:autoBuild(Macros.registerLuaCallbacks())
class ScriptableSprite extends FlxSprite
{
	static var callbacks:Map<String, (Float) -> Void> = new Map<String, (Float) -> Void>();

	var _Lname:String;
	var _assetsDir:String;
	var _L:LuaStateRef;

	public function new(L:LuaStateRef, Lname:String, assetsDir:String, x:Float = 0.0, y:Float = 0.0)
	{
		super(x, y);
		_L = L;
		_Lname = Lname;
		_assetsDir = assetsDir;
		callbacks.set(_Lname + '_setX', setX);
	}

	// public function initToLua(L:cpp.RawPointer<Lua_State>):Void
	// {
	// 	// Push key sprite fields as a Lua table
	// 	Lua.createtable(L, 0, 4);
	// 	// push name
	// 	Lua.pushstring(L, 'Lname');
	// 	Lua.pushstring(L, _Lname + '_setX');
	// 	Lua.settable(L, -3);
	// 	// push x
	// 	Lua.pushstring(L, 'x');
	// 	Lua.pushnumber(L, x);
	// 	Lua.settable(L, -3);
	// 	// push y
	// 	Lua.pushstring(L, 'y');
	// 	Lua.pushnumber(L, y);
	// 	Lua.settable(L, -3);
	// 	Lua.setglobal(L, _Lname);
	// 	/* register our function */
	// 	Lua.register(L, _Lname + "_setX", cpp.Function.fromStaticFunction(f));
	// }

	public function updateToLua(L:cpp.RawPointer<Lua_State>):Void
	{
		// Find the table in Lua state and update its field values
	}

	// public static function setX(sf:ScriptableSprite):(cpp.RawPointer<Lua_State>) -> Int
	// {
	// 	return f.bind(sf);
	// }

	public function setX(x:Float):Void
	{
		this.x = x;
	}

	public static function f(L:cpp.RawPointer<Lua_State>):Int
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
					LuaL.error(L, 'Incorrect argument ${i + 1}', []);
			}
		}

		Lua.pop(L, n); /* clear the stack */

		trace('k=${k}');
		trace('v_x=${v_x}');
		trace('v_y=${v_y}');

		trace('known cbks');
		for (k => f in callbacks)
		{
			trace('k=f: ${k}=${f}');
		}
		var f = callbacks.get(k);
		trace('f=${f}');
		f(v_x);

		return 0;
	}
}
