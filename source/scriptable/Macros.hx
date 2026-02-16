package scriptable;

import haxe.macro.Context;
import haxe.macro.Expr;

final LUA_METHOD:String = ":luaCallback";
final LUA_FIELD:String = ":luaField";

#if macro
class Macros
{
	static function processFunctionFields(fields:Array<Field>):Array<Field>
	{
		var numLuaCbks = 0;

		var chunks = new Array<Expr>();
		chunks.push(macro @:mergeBlock
			{
				Sys.println('setHaxeFunctions entered, dottedName=' + dottedName);
				ScriptableGame.luaVM.getDottedName(_L, dottedName);
				Sys.println('got table for ' + dottedName + ', type=' + Lua.type(_L, -1));
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
									Sys.println('  Registered Haxe callback: ' + $v{field.name});
								});
							numLuaCbks++;
						}
					}
				default:
			}
		}
		// Pop the table to maintain Lua VM stack balance.
		chunks.push(macro @:mergeBlock
			{
				Sys.println('Registered Haxe callbacks for ' + $v{Context.getLocalClass().get().name});
				Lua.pop(_L, 1); // pop the table
			});
		var fnBody:Function = {
			args: [
				{
					name: '_L'
				},
				{
					name: 'dottedName'
				}
			],
			expr: macro $b{chunks}
		}

		var fn:Field = null;
		if (numLuaCbks > 0)
		{
			fn = {
				name: 'setHaxeFunctions',
				pos: Context.currentPos(),
				kind: FFun(fnBody)
			};
		}
		else
		{
			// Define an empty function if there are no Lua callbacks to avoid
			// compile errors from missing function.
			fn = {
				name: 'setHaxeFunctions',
				pos: Context.currentPos(),
				access: [APrivate],

				kind: FFun({
					args: [
						{
							name: '_L'
						},
						{
							name: 'dottedName'
						}
					],
					expr: macro {},
					ret: macro :Void
				})
			};
		}
		fields.push(fn);

		return fields;
	}

	static function processVarFields(fields:Array<Field>):Array<Field>
	{
		var numLuaVars = 0;

		// Generate updateLuaFields function
		var chunks = new Array<Expr>();
		chunks.push(macro @:mergeBlock
			{
				ScriptableGame.luaVM.getDottedName(_L, dottedName);
			});

		for (field in fields)
		{
			switch (field.kind)
			{
				case FVar(t, e):
					for (m in field.meta)
					{
						if (m.name == LUA_FIELD)
						{
							switch (t)
							{
								case TPath(p):
									var pushExpr:Expr;
									if (p.name == "Int" || p.name == "Float")
									{
										pushExpr = macro Lua.pushnumber(_L, $i{field.name});
									}
									else if (p.name == "Bool")
									{
										pushExpr = macro Lua.pushboolean(_L, $i{field.name});
									}
									else if (p.name == "String")
									{
										pushExpr = macro Lua.pushstring(_L, $i{field.name});
									}
									else
									{
										pushExpr = macro Lua.pushnil(_L);
									}
									chunks.push(macro @:mergeBlock
										{
											$pushExpr;
											Lua.setfield(_L, -2, $v{field.name});
										});
									numLuaVars++;
								default:
							}
						}
					}
				default:
			}
		}
		chunks.push(macro @:mergeBlock
			{
				Lua.pop(_L, 1);
			});
		var fn:Field = null;
		if (numLuaVars > 0)
		{
			fn = {
				name: 'updateLuaFields',
				pos: Context.currentPos(),
				access: [APrivate],
				kind: FFun({
					args: [
						{
							name: '_L'
						},
						{
							name: 'dottedName'
						}
					],
					expr: macro $b{chunks},
					ret: macro :Void
				})
			}
		}
		else
		{
			// Define an empty function if there are no Lua fields to avoid
			// compile errors from missing function.
			fn = {
				name: 'updateLuaFields',
				pos: Context.currentPos(),
				access: [APrivate],
				kind: FFun({
					args: [
						{
							name: '_L'
						},
						{
							name: 'dottedName'
						}
					],
					expr: macro {},
					ret: macro :Void
				})
			}
		};
		fields.push(fn);

		return fields;
	}

	public static macro function createLuaHelperFns():Array<Field>
	{
		var numLuaProps = 0;

		var fields = Context.getBuildFields();

		fields = processFunctionFields(fields);

		fields = processVarFields(fields);

		return fields;
	}
}
#end
