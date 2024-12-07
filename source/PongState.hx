package;

import ScriptableState.LuaStateRef;
import ScriptableState.StdVector;
import cpp.Function;
import flixel.FlxG;
import flixel.FlxState;
import flixel.input.FlxInput.FlxInputState;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import hxluajit.Lua;
import hxluajit.LuaL;
import hxluajit.Types.LuaL_Reg;
import openfl.Lib;
import openfl.utils.Assets;

class PongState extends ScriptableState
{
	var _ball:ScriptableSprite;
	var _leftPaddle:ScriptableSprite;
	var _rightPaddle:ScriptableSprite;
	var _net:ScriptableSprite;
	var _leftScore:FlxText;
	var _rightScore:FlxText;

	final LEFT_X = 10;
	final RIGHT_X = FlxG.width - 20;
	final PADDLE_SPEED = 100;

	var _leftPoints = 0;
	var _rightPoints = 0;

	public function new(assetsDir:String)
	{
		super(assetsDir);
	}

	override public function create()
	{
		super.create();

		// Create the ball and paddles
		_ball = new ScriptableSprite('ball');
		_ball.makeGraphic(10, 10, FlxColor.RED);
		_ball.screenCenter();
		_ball.elasticity = 1.0;

		_leftPaddle = new ScriptableSprite('leftPaddle', LEFT_X, FlxG.height / 2.0 - 20);
		_leftPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_leftPaddle.immovable = true;

		_rightPaddle = new ScriptableSprite('rightPaddle', RIGHT_X, FlxG.height / 2.0 - 20);
		_rightPaddle.makeGraphic(10, 40, FlxColor.WHITE);
		_rightPaddle.immovable = true;

		_net = new ScriptableSprite('net');
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
		_leftPaddle.initToLua(_L);
		_rightPaddle.initToLua(_L);
		_ball.initToLua(_L);
	}

	function _initLua():Void
	{
		// Load library script
		var s = Assets.getText('${_assetsDir}/scripts/lib.lua');
		LuaL.dostring(_L, s);

		// Register callbacks
		registerFunctions();

		// Push global state values
		var globals = ['width' => FlxG.width, 'height' => FlxG.height];
		setFlxG(globals);
	}

	override function postLuaReload()
	{
		_initLua();
	}

	@:luaCallback()
	public static function keyPressed(L:LuaStateRef):Int
	{
		{
			final n:Int = Lua.gettop(L);

			/* loop through each argument */
			var key:String = '';

			key = Lua.tostring(L, 1);

			Lua.pop(L, n); /* clear the stack */

			if (FlxG.keys.checkStatus(FlxKey.fromString(key), FlxInputState.PRESSED))
			{
				return 1;
			}

			return 0;
		}
	}

	@:luaCallback()
	public static function leftPaddleMove(L:LuaStateRef):Int
	{
		var s = cast(FlxG.state, PongState);
		final n:Int = Lua.gettop(L);
		if (n != 2)
		{
			Lua.pushstring(L, 'invalid number of args (${n})');
			return 1;
		}

		var x = Lua.tonumber(L, 1);
		var y = Lua.tonumber(L, 2);
		s._leftPaddle.x += x;
		s._leftPaddle.y += y;
		if (s._leftPaddle.y < 0)
		{
			s._leftPaddle.y = 0;
		}
		if (s._leftPaddle.y > FlxG.height - s._leftPaddle.height)
		{
			s._leftPaddle.y = FlxG.height - s._leftPaddle.height;
		}
		Lua.pop(L, n); /* clear the stack */

		return 0;
	}

	@:luaCallback()
	public static function rightPaddleMove(L:LuaStateRef):Int
	{
		var s = cast(FlxG.state, PongState);
		final n:Int = Lua.gettop(L);
		if (n != 2)
		{
			Lua.pushstring(L, 'invalid number of args (${n})');
			return 1;
		}

		var x = Lua.tonumber(L, 1);
		var y = Lua.tonumber(L, 2);
		s._rightPaddle.x += x;
		s._rightPaddle.y += y;
		if (s._rightPaddle.y < 0)
		{
			s._rightPaddle.y = 0;
		}
		if (s._rightPaddle.y > FlxG.height - s._rightPaddle.height)
		{
			s._rightPaddle.y = FlxG.height - s._rightPaddle.height;
		}
		Lua.pop(L, n); /* clear the stack */

		return 0;
	}

	@:luaCallback()
	public static function serve(L:LuaStateRef):Int
	{
		var s = cast(FlxG.state, PongState);
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

		s._ball.x = x;
		s._ball.y = y;
		s._ball.velocity.setPolarDegrees(speed, degrees);

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

		Lua.getglobal(_L, 'update');
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
