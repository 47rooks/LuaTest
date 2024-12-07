package;

import cpp.Pointer;
import cpp.RawPointer;
import cpp.Reference;
import flixel.FlxG;
import flixel.FlxState;
import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.Types.Lua_State;
import openfl.Lib;

abstract LuaStateRef(cpp.Pointer<Lua_State>)
{
	inline function new(p:Pointer<Lua_State>)
	{
		this = p;
	}

	@:from
	static public function fromPointer(p:cpp.Pointer<Lua_State>)
	{
		return new LuaStateRef(p);
	}

	@:to
	public function toPointer():cpp.Pointer<Lua_State>
	{
		return this;
	}

	@:from
	static public function fromRawPointer(p:cpp.RawPointer<Lua_State>)
	{
		return new LuaStateRef(Pointer.fromRaw(p));
	}

	@:to
	public function toRawPointer():cpp.RawPointer<Lua_State>
	{
		return this.raw;
	}
}

// abstract LuaFnCbk((L:LuaStateRef) -> Int)
// {
// 	inline function new(f:(L:LuaStateRef) -> Int)
// 	{
// 		this = f;
// 	}
// 	@:to
// 	public function toLuaRefCbk():(L:cpp.RawPointer<Lua_State>) -> Int {
// 		var f:(L:cpp.RawPointer<Lua_State>) -> Int = function {
// 			this.
// 		}
// 		return
// 	}
// }

@:autoBuild(Macros.registerLuaCallbacks())
abstract class ScriptableState extends FlxState
{
	var _Lname:String;

	var _assetsDir:String;

	var _L:LuaStateRef;

	var _debugScript:String;

	public function new(assetsDir:String)
	{
		super();
		_assetsDir = assetsDir;
	}

	/**
	 * Once `create()` completes the LuaState object will be initialized
	 * in the _L member variable. No Lua operations should be attempted
	 * in the subclass before this has been completed.
	 */
	override public function create()
	{
		super.create();
		initLuaState();
	}

	function initLuaState():Void
	{
		/* initialize Lua */
		_L = LuaL.newstate();

		/* load Lua base libraries */
		LuaL.openlibs(_L);

		// FIXME There is a mismatch here - this is a game/app
		//       exit handler but it's set in the state.
		//       This should probably be in startOutro or the
		//       states need to be stored in the game or globals
		//       Hmmm....
		/* add exit handler to clean up the Lua VM */
		Lib.current.stage.application.onExit.add(onExitHandler);
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

	public function onExitHandler(_):Void
	{
		trace('shutting down VM');
		Lua.close(_L);
		_L = null;
	}

	function _reloadLua():Void
	{
		preLuaReload();

		Lua.close(_L);
		_L = null;
		Lib.current.stage.application.onExit.remove(onExitHandler);
		initLuaState();

		postLuaReload();
	}

	function setFlxG(rows:Map<String, Any>):Void
	{
		var size = 0;
		for (k in rows.keys())
		{
			size++;
		}
		Lua.createtable(_L, 0, 4);
		for (k => v in rows.keyValueIterator())
		{
			Lua.pushstring(_L, k);
			Lua.pushnumber(_L, v);
			Lua.settable(_L, -3);
		}
		Lua.setglobal(_L, 'FlxG');
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justReleased.G)
		{
			// Dump values from Lua
			LuaL.dostring(_L, _debugScript);
		}

		// Check for hot-reload of scripts
		if (FlxG.keys.justReleased.R && FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.CONTROL)
		{
			Sys.println('Reloading Lua state');
			_reloadLua();
		}
	}
}

@:include('vector')
@:native('std::vector')
@:nativeArrayAccess
@:unreflective
@:structAccess
extern class StdVector<T> implements ArrayAccess<Reference<T>>
{
	@:overload(function(size:Int):Void {})
	function new():Void;

	function at(index:Int):T;
	function front():T;
	function back():T;
	function data():RawPointer<T>;

	function empty():Bool;
	function size():Int;
	function capacity():Int;
	function reserve(newCapacity:Int):Void;

	function clear():Void;
	function push_back(value:T):Void;
	function pop_back():Void;
	function resize(newSize:Int):Void;
}
