package scriptable;

import Lua.State;

// @:autoBuild(Macros.registerLuaCallbacks())
interface IScriptable
{
	function initLua(L:State, parent:String, name:String):Void;
	function updateToLua(L:State):Void;
	function updateFromLua(L:State):Void;
	function destroyLua():Void;
}
