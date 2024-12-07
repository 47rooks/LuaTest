package;

import haxe.macro.Context;
import haxe.macro.Expr;

final LUA_METHOD:String = ":luaCallback";

#if macro
class Macros
{
	public static macro function registerLuaCallbacks():Array<Field>
	{
		var numLuaCbks = 0;

		var fields = Context.getBuildFields();

		var chunks = new Array<Expr>();
		chunks.push(macro @:mergeBlock
			{
				var fns:StdVector<LuaL_Reg> = new StdVector<LuaL_Reg>();
				fns.reserve(5);
			});
		for (field in fields)
		{
			switch (field.kind)
			{
				case FFun(f):
					for (m in field.meta)
					{
						if (m.name == LUA_METHOD)
						{
							// var wrapperArg1:cpp.RawPointer<Lua_State> = f.args[0];
							// var wrapper:Field = {
							// 	name: '${field.name}Wrapper',
							// 	access: [Access.APublic, Access.AStatic],
							// 	pos: Context.currentPos(),
							// 	kind: FFun({
							// 		args: f.args,
							// 		expr: macro {}
							// 	})
							// };

							chunks.push(macro @:mergeBlock
								{
									var f = LuaL_Reg.alloc();
									f.name = $v{field.name};
									// var p:(cpp.Pointer<Lua_State>) -> Int = $i{field.name};
									f.func = Function.fromStaticFunction($i{field.name});
									fns.push_back(f);
								});
							numLuaCbks++;
						}
					}
				default:
			}
		}
		chunks.push(macro @:mergeBlock
			{
				var f = LuaL_Reg.alloc();
				f.name = null;
				f.func = null;
				fns.push_back(f);
			});
		chunks.push(macro @:mergeBlock
			{
				Lua.newtable(_L);
				LuaL.setfuncs(_L, untyped fns.data(), 0);
				Lua.setglobal(_L, $v{Context.getLocalClass().get().name});
			});
		var fnBody:Function = {
			args: [],
			expr: macro $b{chunks}
		}

		var fn:Field = {
			name: 'registerFunctions',
			pos: Context.currentPos(),
			kind: FFun({
				args: [],
				expr: macro {}
			})
		};
		if (numLuaCbks > 0)
		{
			fn = {
				name: 'registerFunctions',
				pos: Context.currentPos(),
				kind: FFun(fnBody)
			};
		}
		fields.push(fn);
		return fields;
	}
}
#end
