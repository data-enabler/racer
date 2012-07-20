package states 
{
	import audio.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.text.*;
	import objects.*;
	import org.flixel.*;
		
	/**
	 * ...
	 * @author Adrian Mullings
	 */
	public class PlayState extends FlxState 
	{
		private const ZOOM:Number = 2;
		private const DISP_RADIUS:int = Math.sqrt((FlxG.width / ZOOM) * (FlxG.width / ZOOM) + (FlxG.height / ZOOM) * (FlxG.height / ZOOM)) / 2;
		private const SPEED_MULTIPLIER:Number = 1.0;
		private const SPEED_MAX:Number = 5.0;
		private const SPEED_INCREMENT_KEYBOARD:Number = 0.01;
		private const SPEED_INCREMENT_MOUSE:Number = 0.003;
		private const DIR_INCREMENT_KEYBOARD:Number = 1;
		private const DIR_INCREMENT_MOUSE:Number = 0.5;
		private const BLUR_RATIO:Number = 10.0;
		
		[Embed(source = "../../res/level.png")]
		private var LevelMap:Class;
		[Embed(source = "../../res/sewing machine normal.mp3")]
		private var SewingMachine:Class;
		
		private var track:FlxSprite;
		private var filter:BitmapFilter;
		private var needle:FlxSprite;
		private var wall:Wall;
		private var bgAudio:Sound;
		private var musicPlayer:MP3Player;
		private var x:Number;
		private var y:Number;
		private var dir:Number;
		private var speed:Number;
		
		private var txtX:TextField;
		private var txtY:TextField;
		private var txtSpeed:TextField;
		private var txtDir:TextField;
		
		override public function create():void
		{
			FlxG.bgColor = 0xff224466;
			//FlxG.visualDebug = true;
			
			track = new FlxSprite(0, 0, LevelMap);
			filter = new BlurFilter(0, 0, BitmapFilterQuality.LOW);
			needle = new FlxSprite();
			needle.makeGraphic(4, 4);
			FlxG.camera.target = needle;
			FlxG.camera.zoom = ZOOM;
			FlxG.camera.antialiasing = true;
			add(track);
			add(needle);
			
			x = 40;
			y = 40;
			dir = 350;
			speed = 1.0;
			
			FlxG.mouse.show();
			
			musicPlayer = new MP3Player();
			bgAudio = new SewingMachine() as Sound;
			musicPlayer.playLoadedSound(bgAudio);
			
			wall = new Wall(310, 125, 100, 225, 2000, 500);
			add(wall);
			
			// debug info
			txtX = new TextField();
			txtY = new TextField();
			txtSpeed = new TextField();
			txtDir = new TextField();
			txtX.textColor = 0xFFFFFF;
			txtY.textColor = 0xFFFFFF;
			txtSpeed.textColor = 0xFFFFFF;
			txtDir.textColor = 0xFFFFFF;
			txtX.x = 0;
			txtX.y = 0;
			txtY.x = 0;
			txtY.y = 12;
			txtSpeed.x = 0;
			txtSpeed.y = 24;
			txtDir.x = 0;
			txtDir.y = 36;
			FlxG.camera.getContainerSprite().parent.addChild(txtX);
			FlxG.camera.getContainerSprite().parent.addChild(txtY);
			FlxG.camera.getContainerSprite().parent.addChild(txtSpeed);
			FlxG.camera.getContainerSprite().parent.addChild(txtDir);
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
			
			// update filter
			var blur:Number = Math.max(speed - 1.0, 0) * BLUR_RATIO;
			filter = new BlurFilter(blur, blur, BitmapFilterQuality.HIGH);
			var intX:int = Math.floor(x);
			var intY:int = Math.floor(y);
			track.framePixels.applyFilter(track.pixels, new Rectangle(intX - DISP_RADIUS, intY - DISP_RADIUS, DISP_RADIUS*2, DISP_RADIUS*2), new Point(intX - DISP_RADIUS, intY - DISP_RADIUS), filter);
			
			// move and rotate camera
			needle.x = x;
			needle.y = y;
			needle.angle = 360 - dir;
			FlxG.camera.angle = dir;
			
			// adjust audio speed
			musicPlayer.playbackSpeed = speed;
			
			wall.update();
			
			// if collision
			if (track.pixels.getPixel(x, y) == 0x0000ff) {
				reset();
			}
			if (wall.collides(needle)) {
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