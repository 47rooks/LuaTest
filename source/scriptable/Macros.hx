package scriptable;

import haxe.macro.Context;
import haxe.macro.Expr;

final LUA_METHOD:String = ":luaCallback";
final LUA_FIELD:String = ":luaField";

#if macro
class Macros
{
	public static macro function createType():Array<Field>
	{
		var numLuaCbks = 0;
		var numLuaVars = 0;
		var numLuaProps = 0;

		var fields = Context.getBuildFields();

		var chunks = new Array<Expr>();
		chunks.push(macro @:mergeBlock
			{
				Lua.newtable(_L);
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
							chunks.push(macro @:mergeBlock
								{
									Lua.pushcfunction(_L, $i{field.name}, $v{field.name});
									Lua.setfield(_L, -2, $v{field.name});
									Sys.println('  Registered Lua callback: ' + $v{field.name});
								});
							numLuaCbks++;
						}
					}
				case FVar(t, e):
					for (m in field.meta)
					{
						if (m.name == LUA_FIELD)
						{
							switch (t)
							{
								case TNamed(name, t2):
									Sys.println('Found TNamed=${name}, ${t2}');
								// chunks.push(macro @:mergeBlock
								// 	{
								// 		Lua.pushcfunction(_L, $i{field.name}, $v{field.name});
								// 		Lua.setfield(_L, -2, $v{field.name});
								// 		Sys.println('  Registered Var callback: ' + $v{field.name});
								// 	});
								// numLuaVars++;
								case TPath(p):
									Sys.println('Found ${field.name}, TPath=${p}');
									chunks.push(macro @:mergeBlock
										{
											Lua.createtable(_L, 0, 0);
											Lua.setfield(_L, -2, $v{field.name});
											Sys.println('  Registered Var callback: ' + $v{field.name});
										});
									numLuaVars++;
								default:
							}
						}
					}
				default:
			}
		}
		// Give the table a name
		chunks.push(macro @:mergeBlock
			{
				Lua.setglobal(_L, $v{Context.getLocalClass().get().name});
				Sys.println('Registered Lua callbacks for ' + $v{Context.getLocalClass().get().name});
			});
		var fnBody:Function = {
			args: [
				{
					name: '_L'
				}
			],
			expr: macro $b{chunks}
		}
		var fn:Field = {
			name: 'createType',
			pos: Context.currentPos(),
			access: [APrivate],

			kind: FFun({
				args: [
					{
						name: '_L'
					}
				],
				expr: macro {},
				ret: macro :Void
			})
		};
		if (numLuaCbks > 0)
		{
			fn = {
				name: 'createType',
				pos: Context.currentPos(),
				kind: FFun(fnBody)
			};
		}
		fields.push(fn);
		return fields;
	}
}
#end
