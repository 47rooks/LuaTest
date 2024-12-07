package;

import flixel.FlxGame;
import lime.utils.Assets;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(0, 0, PongState.new.bind('assets'), true));
	}
}
