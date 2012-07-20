package objects
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.display.BlendMode;
	
	import org.flixel.FlxPoint;
	import org.flixel.FlxSprite;
	import org.flixel.FlxGroup;
	import org.flixel.FlxU;
	import org.flixel.FlxG;
	import org.flixel.FlxCamera;
	import org.flixel.plugin.photonstorm.FlxCollision;
	
	/**
	 * ...
	 * @author Adrian Mullings
	 */
	public class Wall extends FlxGroup
	{
		private const THICKNESS:int = 6;
		private const TRAVEL_DIST:int = 30;
		
		[Embed(source="../../res/wall.png")]
		private var WallGraphic:Class;
		
		private var shadow:FlxSprite;
		private var wall:MovingWall;
		private var baseAngle:int;
		private var baseX:int;
		private var baseY:int;
		private var closeFor:uint;
		private var openFor:uint;
		private var interval:uint;
		
		public function Wall(centerX:int, centerY:int, width:uint, angle:int, interval:uint, closeFor:uint)
		{
			super();
			
			this.baseX = centerX - width / 2;
			this.baseY = centerY;
			this.baseAngle = angle;
			this.closeFor = closeFor;
			this.interval = Math.max(interval, closeFor);
			this.openFor = Math.max(0, this.interval - closeFor);
			
			this.shadow = new FlxSprite(centerX - width / 2, centerY - THICKNESS / 2);
			this.shadow.makeGraphic(width, THICKNESS, 0x44000000);
			this.shadow.origin = new FlxPoint(width / 2, THICKNESS / 2);
			this.shadow.angle = this.baseAngle + 90;
			this.wall = new MovingWall(centerX - width / 2, centerY, WallGraphic);
			var scale:Number = width / this.wall.width;
			this.wall.scale = new FlxPoint(scale, scale);
			this.wall.height = this.wall.height * scale;
			this.wall.width = width;
			this.wall.origin = new FlxPoint(width / 2, 0);
			this.wall.angle = this.baseAngle + 90;
			
			this.add(shadow);
			this.add(wall);
		}
		
		override public function update():void
		{
			var time:uint = FlxU.getTicks() % interval;
			
			if (time < openFor)
			{
				var pos:Number = 1.0 - Math.abs(2 * time / openFor - 1.0);
				wall.x = baseX + pos * Math.cos((baseAngle + 90) / 180 * Math.PI) * TRAVEL_DIST;
				wall.y = baseY + pos * Math.sin((baseAngle + 90) / 180 * Math.PI) * TRAVEL_DIST * -1;
			}
			else
			{
				wall.x = baseX;
				wall.y = baseY;
			}
			
			super.update();
		}
		
		public function collides(sprite:FlxSprite):Boolean
		{
			if (FlxU.getTicks() % interval < openFor) return false;
			else return pixelPerfectCheck(sprite, shadow, 215);
		}
	
		/*public function collidesPoint(x:uint, y:uint):Boolean
		{
			if (FlxU.getTicks() % interval < openFor) return false;
			else return FlxCollision.pixelPerfectPointCheck(x, y, shadow, 1);
		}*/
		
		public static function pixelPerfectCheck(contact:FlxSprite, target:FlxSprite, alphaTolerance:int = 255, camera:FlxCamera = null):Boolean
		{
			// Blatantly copied from PhotonStorm's FlxCollision. Fixed Rotation support, ignores bounds-checking.
			
			var pointA:Point = new Point;
			var pointB:Point = new Point;
			
			if (camera)
			{
				pointA.x = contact.x - int(camera.scroll.x * contact.scrollFactor.x) - contact.offset.x;
				pointA.y = contact.y - int(camera.scroll.y * contact.scrollFactor.y) - contact.offset.y;
				
				pointB.x = target.x - int(camera.scroll.x * target.scrollFactor.x) - target.offset.x;
				pointB.y = target.y - int(camera.scroll.y * target.scrollFactor.y) - target.offset.y;
			}
			else
			{
				pointA.x = contact.x - int(FlxG.camera.scroll.x * contact.scrollFactor.x) - contact.offset.x;
				pointA.y = contact.y - int(FlxG.camera.scroll.y * contact.scrollFactor.y) - contact.offset.y;
				
				pointB.x = target.x - int(FlxG.camera.scroll.x * target.scrollFactor.x) - target.offset.x;
				pointB.y = target.y - int(FlxG.camera.scroll.y * target.scrollFactor.y) - target.offset.y;
			}
			
			var boundsA:Rectangle = new Rectangle(pointA.x, pointA.y, contact.framePixels.width, contact.framePixels.height);
			var boundsB:Rectangle = new Rectangle(pointB.x, pointB.y, target.framePixels.width, target.framePixels.height);
			
			var intersect:Rectangle = boundsA;
			
			//	Normalise the values or it'll break the BitmapData creation below
			intersect.x = Math.floor(intersect.x);
			intersect.y = Math.floor(intersect.y);
			intersect.width = Math.ceil(intersect.width);
			intersect.height = Math.ceil(intersect.height);
			
			var matrixA:Matrix = new Matrix;
			if (contact.angle != 0) {
				matrixA.translate(-contact.origin.x, -contact.origin.y);
				matrixA.rotate(contact.angle * 0.017453293);
				matrixA.translate(contact.origin.x, contact.origin.y);
			}
			
			var matrixB:Matrix = new Matrix;
			if (target.angle != 0) {
				matrixB.translate(-target.origin.x, -target.origin.y);
				matrixB.rotate(target.angle * 0.017453293);
				matrixB.translate(target.origin.x, target.origin.y);
			}
			matrixB.translate( -(intersect.x - boundsB.x), -(intersect.y - boundsB.y));
			
			var testA:BitmapData = contact.framePixels;
			var testB:BitmapData = target.framePixels;
			var overlapArea:BitmapData = new BitmapData(intersect.width, intersect.height, false);
			
			overlapArea.draw(testA, matrixA, new ColorTransform(1, 1, 1, 1, 255, -255, -255, alphaTolerance), BlendMode.NORMAL);
			overlapArea.draw(testB, matrixB, new ColorTransform(1, 1, 1, 1, 255, 255, 255, alphaTolerance), BlendMode.DIFFERENCE);
			
			var overlap:Rectangle = overlapArea.getColorBoundsRect(0xffffffff, 0xff00ffff);
			overlap.offset(intersect.x, intersect.y);
			
			if (overlap.isEmpty())
			{
				return false;
			}
			else
			{
				return true;
			}
		}
	}

}

import org.flixel.*;

class MovingWall extends FlxSprite
{
	public function MovingWall(X:Number=0,Y:Number=0,SimpleGraphic:Class=null)
	{
		super(X, Y, SimpleGraphic);
	}
	
	override public function draw():void
	{
		// Almost an exact copy of FlxSprite.draw, with a small fix for rotation
		
		if (_flickerTimer != 0)
		{
			_flicker = !_flicker;
			if (_flicker)
				return;
		}
		
		if (dirty) //rarely 
			calcFrame();
		
		if (cameras == null)
			cameras = FlxG.cameras;
		var camera:FlxCamera;
		var i:uint = 0;
		var l:uint = cameras.length;
		while (i < l)
		{
			camera = cameras[i++];
			if (!onScreen(camera))
				continue;
			_point.x = x - int(camera.scroll.x * scrollFactor.x) - offset.x;
			_point.y = y - int(camera.scroll.y * scrollFactor.y) - offset.y;
			_point.x += (_point.x > 0) ? 0.0000001 : -0.0000001;
			_point.y += (_point.y > 0) ? 0.0000001 : -0.0000001;
			if (((angle == 0) || (_bakedRotation > 0)) && (scale.x == 1) && (scale.y == 1) && (blend == null))
			{ //Simple render
				_flashPoint.x = _point.x;
				_flashPoint.y = _point.y;
				camera.buffer.copyPixels(framePixels, _flashRect, _flashPoint, null, null, true);
			}
			else
			{ //Advanced render
				_matrix.identity();
				_matrix.scale(scale.x, scale.y);         // swapped this line with the one below
				_matrix.translate(-origin.x, -origin.y); // so that we can scale and rotate without headaches
				if ((angle != 0) && (_bakedRotation <= 0))
					_matrix.rotate(angle * 0.017453293);
				_matrix.translate(_point.x + origin.x, _point.y + origin.y);
				camera.buffer.draw(framePixels, _matrix, null, blend, null, antialiasing);
			}
			//_VISIBLECOUNT++;
			if (FlxG.visualDebug && !ignoreDrawDebug)
				drawDebug(camera);
		}
	}
}