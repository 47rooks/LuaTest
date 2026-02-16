package;

import Lua.LuaStatus;
import Lua.LuaType;
import Lua.State;
import LuaCode.CompileOptions;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.debug.completion.CompletionListEntry;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.NativeWindow;
import openfl.utils.Assets;
import scriptable.LuaVM;
import scriptable.ScriptableGame;
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

	function _initLua() {}

	// override function postLuaReload()
	// {
	// 	_initLua();
	// }

	@:luaCallback()
	public function leftPaddleMove(L:State):Int
	{
		trace('leftpaddle called');
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
		trace('serve called');
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

		// @formatter:off
		ScriptableGame.luaVM.callLuau("game.state.update", [
			{"type": "luaGetField", "value": _dottedName},
			{"type": "number", "value": elapsed}
		]);
		// @formatter:on
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
		if (FlxG.keys.justReleased.N)
		{
			ScriptableGame.luaVM.dump("game");
		}
	}

	public override function updateToLua(L:State):Void
	{
		// Find the table in Lua state and update its field values
		ScriptableGame.luaVM.getDottedName(L, _dottedName);

		_ball.updateToLua(L);
		_leftPaddle.updateToLua(L);
		_rightPaddle.updateToLua(L);

		Lua.pop(L, 1); // pop parent table
	}
}
