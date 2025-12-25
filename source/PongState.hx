package;

import Lua.LuaStatus;
import Lua.LuaType;
import Lua.State;
import LuaCode.CompileOptions;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.utils.Assets;
import scriptable.ScriptableSprite;
import scriptable.ScriptableState;

// @:autoBuild(Macros.registerLuaCallbacks())
class PongState extends ScriptableState
{
	@:luaField
	var _ball:ScriptableSprite;
	@:luaField
	var _leftPaddle:ScriptableSprite;
	@:luaField
	var _rightPaddle:ScriptableSprite;
	var _net:FlxSprite;
	var _leftScore:FlxText;
	var _rightScore:FlxText;

	final LEFT_X = 10;
	final RIGHT_X = FlxG.width - 20;
	final PADDLE_SPEED = 100;

	var _leftPoints = 0;
	var _rightPoints = 0;

	public function new(assetsDir:String, parent:String, name:String)
	{
		super(assetsDir, parent, name);
	}

	override public function create()
	{
		super.create();
		_syncedFields.concat(['_ball', '_leftPaddle', '_rightPaddle']);

		// Create the ball and paddles
		_ball = new Ball(_L, _assetsDir, _dottedName, "ball");
		_ball.makeGraphic(10, 10, FlxColor.RED);
		_ball.screenCenter();
		_ball.elasticity = 1.0;

		_leftPaddle = new Paddle(_L, _assetsDir, _dottedName, "leftPaddle", LEFT_X, FlxG.height / 2.0 - 20);
		_leftPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_leftPaddle.immovable = true;

		_rightPaddle = new Paddle(_L, _assetsDir, _dottedName, "rightPaddle", RIGHT_X, FlxG.height / 2.0 - 20);
		_rightPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_rightPaddle.immovable = true;

		_net = new FlxSprite();
		_net.loadGraphic('assets/images/PongNet.png');
		_net.screenCenter();
		_net.y = 0;

		_leftScore = new FlxText(FlxG.width / 4.0, 10, 20, '${_leftPoints}', 20);
		_leftScore.textField.antiAliasType = ADVANCED;
		_leftScore.textField.sharpness = 400;

		_rightScore = new FlxText(3 * FlxG.width / 4.0, 10, 20, '${_rightPoints}', 20);
		_rightScore.textField.antiAliasType = ADVANCED;
		_rightScore.textField.sharpness = 400;

		add(_leftPaddle);
		add(_rightPaddle);
		add(_ball);
		add(_net);
		add(_leftScore);
		add(_rightScore);

		// Push all required initial state to Lua
		_initLua();
	}

	function _initLua():Void
	{
		// Load library script
		var s = Assets.getText('${_assetsDir}/scripts/PongState.lua');
		trace('Lua script is:\n${s}');
		// LuaL.dostring(_L, s);
		// Cannot pass null so use an empty struct.
		// Cannot instantiate {} directly as call site, so use a local variable.
		var options:CompileOptions = {};

		var byteCode = LuaCode.compile(s, s.length, options);
		trace('bytecode length: ${byteCode.size}');
		var r = Lua.load(_L, "code", byteCode, 0);
		if (r != LuaStatus.OK)
		{
			trace('Error loading chunk: ${Lua.tostring(_L, -1)}');
			Lua.pop(_L, 1); // remove error message
			Sys.exit(1);
		}
		Lua.call(_L, 0, 1); // call the loaded chunk
		// Register callbacks
		createType(_L);
	}

	// override function postLuaReload()
	// {
	// 	_initLua();
	// }

	@:luaCallback()
	public function leftPaddleMove(L:State):Int
	{
		final n:Int = Lua.gettop(L);
		if (n != 2)
		{
			Lua.pushstring(L, 'invalid number of args (${n})');
			return 1;
		}

		var x = Lua.tonumber(L, 1);
		var y = Lua.tonumber(L, 2);

		_leftPaddle.x += x;
		_leftPaddle.y += y;

		if (_leftPaddle.y < 0)
		{
			_leftPaddle.y = 0;
		}
		if (_leftPaddle.y > FlxG.height - _leftPaddle.height)
		{
			_leftPaddle.y = FlxG.height - _leftPaddle.height;
		}
		Lua.pop(L, n); /* clear the stack */

		return 0;
	}

	@:luaCallback()
	public function rightPaddleMove(L:State):Int
	{
		trace('rightpaddle called');
		final n:Int = Lua.gettop(L);
		if (n != 2)
		{
			Lua.pushstring(L, 'invalid number of args (${n})');
			return 1;
		}

		var x = Lua.tonumber(L, 1);
		var y = Lua.tonumber(L, 2);
		_rightPaddle.x += x;
		_rightPaddle.y += y;
		if (_rightPaddle.y < 0)
		{
			_rightPaddle.y = 0;
		}
		if (_rightPaddle.y > FlxG.height - _rightPaddle.height)
		{
			_rightPaddle.y = FlxG.height - _rightPaddle.height;
		}
		Lua.pop(L, n); /* clear the stack */

		return 0;
	}

	@:luaCallback()
	public function serve(L:State):Int
	{
		final n:Int = Lua.gettop(L);
		if (n != 4)
		{
			Lua.pushstring(L, 'invalid number of args (${n})');
			return 1;
		}

		// Get initial position
		var x = Lua.tonumber(L, 1);
		var y = Lua.tonumber(L, 2);
		// Get speed and direction
		var speed = Lua.tonumber(L, 3);
		var degrees = Lua.tonumber(L, 4);

		_ball.x = x;
		_ball.y = y;
		_ball.velocity.setPolarDegrees(speed, degrees);

		Lua.pop(L, n); /* clear the stack */

		return 0;
	}

	function resetForNewServe():Void
	{
		_leftPaddle.x = LEFT_X;
		_leftPaddle.y = (FlxG.height - _leftPaddle.height) / 2.0;
		_rightPaddle.x = RIGHT_X;
		_rightPaddle.y = (FlxG.height - _rightPaddle.height) / 2.0;
		_ball.x = (FlxG.width - _ball.width) / 2.0;
		_ball.y = 0;
		_ball.velocity.set(0.0, 0.0);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.collide(_ball, _leftPaddle);
		FlxG.collide(_ball, _rightPaddle);

		_leftPaddle.updateToLua(_L);
		_rightPaddle.updateToLua(_L);
		_ball.updateToLua(_L);

		var rv = Lua.getglobal(_L, 'update');
		if (rv != LuaType.FUNCTION)
		{
			Sys.println('Lua update function not found. rv=${rv}');
			Lua.pop(_L, 1);
			return;
		}

		// Push elapsed time to Lua
		Lua.pushnumber(_L, elapsed);
		var e = Lua.pcall(_L, 1, 0, 0);
		if (e > 0)
		{
			Sys.println('Lua call (update) failed: ${Lua.tostring(_L, -1)}');
			Lua.pop(_L, 1);
		}

		if (_ball.y < 0)
		{
			_ball.velocity.bounce(FlxPoint.get(0, 1));
		}
		if (_ball.y > FlxG.height - 10)
		{
			_ball.velocity.bounce(FlxPoint.get(0, -1));
		}
		if (_ball.x < 0)
		{
			_rightPoints++;
			_rightScore.text = '${_rightPoints}';
			_rightScore.textField.antiAliasType = ADVANCED;
			_rightScore.textField.sharpness = 400;

			resetForNewServe();
		}
		if (_ball.x > FlxG.width)
		{
			_leftPoints++;
			_leftScore.text = '${_leftPoints}';
			_leftScore.textField.antiAliasType = ADVANCED;
			_leftScore.textField.sharpness = 400;
			resetForNewServe();
		}
	}
}
