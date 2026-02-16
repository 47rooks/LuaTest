package scriptable;

/**
 * Requirer context object. This stores the state of the requirer between
 * API calls from Luau. Luau passes this to each callback function when
 * invoking operations on the requirer.
 * 
 * This is just a simple example.
 */
class RequireCtx
{
	/**
	 * The virtual file system navigator for this context.
	 */
	public var vfs:FlixelNavigator;

	public var number_of_calls:Int;

	public function new()
	{
		vfs = new FlixelNavigator();

		number_of_calls = 17;
	}
}
