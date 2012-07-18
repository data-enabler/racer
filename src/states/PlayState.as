package states 
{
	import flash.display.Sprite;
	import flash.filters.*;
	import flash.media.Sound;
	import org.flixel.*;
	import org.flixel.system.input.Mouse;
	import audio.*;
		
	/**
	 * ...
	 * @author Adrian Mullings
	 */
	public class PlayState extends FlxState 
	{
		private const MID_X:int = FlxG.width / 2;
		private const MID_Y:int = FlxG.height / 2;
		private const SPEED_MULTIPLIER:Number = 1.0;
		private const SPEED_MAX:Number = 5.0;
		private const SPEED_INCREMENT_KEYBOARD:Number = 0.01;
		private const SPEED_INCREMENT_MOUSE:Number = 0.003;
		private const DIR_INCREMENT_KEYBOARD:Number = 1;
		private const DIR_INCREMENT_MOUSE:Number = 0.5;
		private const BLUR_RATIO:Number = 5.0;
		
		[Embed(source="../../res/level.png")]
		private var levelMap:Class;
		[Embed(source = "../../res/sewing machine normal.mp3")]
		private var sewingMachine:Class;
		
		private var track:FlxSprite;
		private var filter:BitmapFilter;
		private var needle:FlxSprite;
		private var bgAudio:Sound;
		private var musicPlayer:MP3Player;
		private var x:Number;
		private var y:Number;
		private var dir:Number;
		private var speed:Number;
		
		private var txtX:FlxText;
		private var txtY:FlxText;
		private var txtSpeed:FlxText;
		private var txtDir:FlxText;
		
		override public function create():void
		{
			FlxG.bgColor = 0xff224466;
			track = new FlxSprite(MID_X, MID_Y, levelMap);
			filter = new BlurFilter(0, 0, BitmapFilterQuality.MEDIUM);
			needle = new FlxSprite();
			needle.makeGraphic(2, 2);
			needle.x = MID_X - 1;
			needle.y = MID_Y - 1;
			add(track);
			add(needle);
			x = 40;
			y = 40;
			dir = 350;
			speed = 1.0;
			
			FlxG.mouse.show();
			musicPlayer = new MP3Player();
			bgAudio = new sewingMachine() as Sound;
			musicPlayer.playLoadedSound(bgAudio);
			
			txtX = new FlxText(0, 0, 150);
			txtY = new FlxText(0, 12, 150);
			txtSpeed = new FlxText(0, 24, 150);
			txtDir = new FlxText(0, 36, 150);
			add(txtX);
			add(txtY);
			add(txtSpeed);
			add(txtDir);
		}
		
		override public function update():void
		{
			keyboardInput();
			mouseInput();
			
			var dx:Number = speed * SPEED_MULTIPLIER * Math.cos(dir / 180 * Math.PI);
			var dy:Number = speed * SPEED_MULTIPLIER * Math.sin(dir / 180 * Math.PI) * -1;
			
			// if not near track end
			if (track.width - x >= 40 && track.height - y >= 40) {
				x += dx;
				y += dy;
			}
			else {
				musicPlayer.stop();
			}
			
			// debug info display
			txtX.text = x.toString();
			txtY.text = y.toString();
			txtSpeed.text = speed.toString();
			txtDir.text = dir.toString();
			
			// move and rotate track
			track.x = MID_X - x;
			track.y = MID_Y - y;
			track.origin = new FlxPoint(x, y);
			track.angle = dir;
			
			// update filter
			filter = new BlurFilter(Math.abs(dx * BLUR_RATIO), Math.abs(dy * BLUR_RATIO), BitmapFilterQuality.MEDIUM);
			
			// adjust audio speed
			musicPlayer.playbackSpeed = speed;
			
			// if collision
			if (track.pixels.getPixel(x, y) == 0xff0000) {
				reset();
			}
		}
		
		private function keyboardInput():void
		{
			if (FlxG.keys.UP) {
				dir = (dir + DIR_INCREMENT_KEYBOARD) % 360;
			}
			else if (FlxG.keys.DOWN) {
				dir = (dir - DIR_INCREMENT_KEYBOARD) % 360;
			}
			
			if (FlxG.keys.RIGHT) {
				speed = Math.min(speed + SPEED_INCREMENT_KEYBOARD, SPEED_MAX);
			}
			else if (FlxG.keys.LEFT) {
				speed = Math.max(speed - SPEED_INCREMENT_KEYBOARD, 0.0);
			}
		}
		
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		private function mouseInput():void
		{
			if (FlxG.mouse.justPressed()) {
				lastMouseX = FlxG.mouse.screenX;
				lastMouseY = FlxG.mouse.screenY;
			}
			
			if (FlxG.mouse.pressed()) {
				dir = (dir + (FlxG.mouse.screenY - lastMouseY) * DIR_INCREMENT_MOUSE) % 360;
				speed = Math.min(SPEED_MAX, Math.max(0.0, speed + (lastMouseX - FlxG.mouse.screenX) * SPEED_INCREMENT_MOUSE));
				
				lastMouseX = FlxG.mouse.screenX;
				lastMouseY = FlxG.mouse.screenY;
			}
		}
		
		private function reset():void
		{
			x = 40;
			y = 40;
			dir = 350;
			speed = 1.0;
		}
	}

}