package;

import Game;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		// FIXME this name value looks like a problem here. I was expecting
		//       it should be a field name from the parent object
		addChild(new Game(0, 0, PongState.new.bind('assets', "game", "PongState"), 60, 60, false, false));
	}
}
