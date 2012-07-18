package 
{
	import org.flixel.*;
	import states.*;
	[SWF(width="640", height="480", backgroundColor="#333333")]
	
	/**
	 * ...
	 * @author Adrian Mullings
	 */
	public class Main extends FlxGame
	{
		
		public function Main():void 
		{
			super(320,240,PlayState,2);
		}
		
	}
	
}