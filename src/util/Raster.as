package util 
{
	import flash.display.BitmapData;
	
	/**
	 * ...
	 * 
	 */
	public class Raster 
	{
		
		/**
		*   "Extremely Fast Line Algorithm"
		*   @author Po-Han Lin (original version: http://www.edepot.com/algorithm.html)
		*   @author Simo Santavirta (AS3 port: http://www.simppa.fi/blog/?p=521)
		*   @author Jackson Dunstan (minor formatting)
		*   @param x X component of the start point
		*   @param y Y component of the start point
		*   @param x2 X component of the end point
		*   @param y2 Y component of the end point
		*   @param color Color of the line
		*   @param bmd Bitmap to draw on
		*/
		public static function efla(x:int, y:int, x2:int, y2:int, color:uint, bmd:BitmapData): void
		{
			var shortLen:int = y2-y;
			var longLen:int = x2-x;
 
			if ((shortLen ^ (shortLen >> 31)) - (shortLen >> 31) > (longLen ^ (longLen >> 31)) - (longLen >> 31))
			{
				shortLen ^= longLen;
				longLen ^= shortLen;
				shortLen ^= longLen;
 
				var yLonger:Boolean = true;
			}
			else
			{
				yLonger = false;
			}
 
			var inc:int = longLen < 0 ? -1 : 1;
 
			var multDiff:Number = longLen == 0 ? shortLen : shortLen / longLen;
 
			if (yLonger)
			{
				for (var i:int = 0; i != longLen; i += inc)
				{
					bmd.setPixel32(x + i*multDiff, y+i, color);
				}
			}
			else
			{
				for (i = 0; i != longLen; i += inc)
				{
					bmd.setPixel32(x+i, y+i*multDiff, color);
				}
			}
		}
		
	}

}