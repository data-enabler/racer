package states 
{
	import audio.*;
	import flash.filters.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.text.*;
	import com.adobe.serialization.json.*;
	import levels.Levels;
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
		
		[Embed(source = "../../res/sewing machine normal.mp3")]
		private var SewingMachine:Class;
		
		private var currentTrack:uint;
		private var tracks:Array;
		private var trackGroup:FlxGroup;
		private var wallGroup:FlxGroup;
		private var finished:Boolean;
		private var filter:BitmapFilter;
		private var needle:FlxSprite;
		private var wall:Wall;
		private var bgAudio:Sound;
		private var musicPlayer:MP3Player;
		private var x:Number;
		private var y:Number;
		private var dir:Number;
		private var speed:Number;
		
		private var txtHealth:TextField;
		private var txtX:TextField;
		private var txtY:TextField;
		private var txtSpeed:TextField;
		private var txtDir:TextField;
		
		override public function create():void
		{
			FlxG.bgColor = 0xff224466;
			//FlxG.visualDebug = true;
			
			filter = new BlurFilter(0, 0, BitmapFilterQuality.LOW);
			needle = new FlxSprite();
			needle.makeGraphic(4, 4);
			
			FlxG.camera.target = needle;
			FlxG.camera.zoom = ZOOM;
			FlxG.camera.antialiasing = true;
			FlxG.mouse.show();
			
			trackGroup = new FlxGroup();
			wallGroup  = new FlxGroup();
			loadTracks(["level1", "level3", "level2"]);
			resetMap();
			
			add(trackGroup);
			add(needle);
			add(wallGroup);
			
			musicPlayer = new MP3Player();
			bgAudio = new SewingMachine() as Sound;
			musicPlayer.playLoadedSound(bgAudio);
			
			txtHealth = new TextField();
			txtHealth.textColor = 0xFFFFFF;
			txtHealth.x = FlxG.width - 20;
			txtHealth.y = 0;
			FlxG.camera.getContainerSprite().parent.addChild(txtHealth);
			
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
			super.update();
			
			keyboardInput();
			mouseInput();
			
			var dx:Number = speed * SPEED_MULTIPLIER * Math.cos(dir / 180 * Math.PI);
			var dy:Number = speed * SPEED_MULTIPLIER * Math.sin(dir / 180 * Math.PI) * -1;
			
			// if not near track end
			if (!finished) {
				x += dx;
				y += dy;
				
				if (trackCollision()) {
					if (speed > 0.3)
						needle.health--;
					speed = 0;
					x -= (dx > 0)? 2 : -2;
					y -= (dy > 0)? 2 : -2;
					
					if (needle.health <= 0) {
						needle.health = 3;
						resetMap();
					}
				}
			}
			else {
				currentTrack = 0;
				needle.health = 3;
				resetMap();
			}
			
			txtHealth.text = needle.health.toString();
			
			// debug info display
			txtX.text = x.toString();
			txtY.text = y.toString();
			txtSpeed.text = speed.toString();
			txtDir.text = dir.toString();
			
			// update filter
			var blur:Number = Math.max(speed - 1.0, 0) * BLUR_RATIO;
			filter = new BlurFilter(blur, blur, BitmapFilterQuality.HIGH);
			var intX:int = Math.floor(x) - tracks[currentTrack].img.x;
			var intY:int = Math.floor(y) - tracks[currentTrack].img.y;
			tracks[currentTrack].img.framePixels.applyFilter(tracks[currentTrack].img.pixels, 
				new Rectangle(intX - DISP_RADIUS, intY - DISP_RADIUS, DISP_RADIUS * 2, DISP_RADIUS * 2), 
				new Point(intX - DISP_RADIUS, intY - DISP_RADIUS), filter);
			
			// move and rotate camera
			needle.x = x;
			needle.y = y;
			needle.angle = 360 - dir;
			FlxG.camera.angle = dir;
			
			// adjust audio speed
			musicPlayer.playbackSpeed = speed;
			//musicPlayer.playbackSpeed = 0;
			
			updateMap();
			
			// if collision with wall			
			for (var i:String in wallGroup.members) {
				for (var j:String in wallGroup.members[i].members) {
					var wall:Wall = wallGroup.members[i].members[j];
					if (wall.collides(needle)) {
						resetMap();
					}
				}
			}
		}
		
		private function loadTracks(names:Array):void
		{
			var trackX:int = 0;
			var trackY:int = 0;
			
			currentTrack = 0;
			needle.health = 3;
			finished = false;
			tracks = new Array(names.length);
			for (var i:uint = 0; i < names.length; i++) {
				tracks[i] = JSON.decode(new Levels[names[i]]);
				tracks[i].img = new FlxSprite(trackX - tracks[i].start.x, trackY - tracks[i].start.y, Levels[names[i] + "Img"]);
				tracks[i].wallGroup = new FlxGroup();
				for (var j:String in tracks[i].walls) {
					var w:Object = tracks[i].walls[j];
					var wall:Wall = new Wall(w.x + trackX - tracks[i].start.x, w.y + trackY - tracks[i].start.y, w.width, w.angle, w.openFor, w.closedFor);
					tracks[i].wallGroup.add(wall);
				}
				tracks[i].loc = new FlxPoint(trackX, trackY);
				trackX += tracks[i].end.x - tracks[i].start.x;
				trackY += tracks[i].end.y - tracks[i].start.y;
			}
		}
		
		private function resetMap():void
		{
			trackGroup.clear();
			wallGroup.clear();
			if (currentTrack > 0) {
				trackGroup.add(tracks[currentTrack - 1].img);
				wallGroup.add( tracks[currentTrack - 1].wallGroup);
			}
			trackGroup.add(tracks[currentTrack].img);
			wallGroup.add( tracks[currentTrack].wallGroup);
			if (currentTrack < tracks.length - 1) {
				trackGroup.add(tracks[currentTrack + 1].img);
				wallGroup.add( tracks[currentTrack + 1].wallGroup);
			}
			
			x = tracks[currentTrack].loc.x;
			y = tracks[currentTrack].loc.y;
			dir = tracks[currentTrack].startAngle;
			speed = 1.0;
			
			finished = false;
		}
		
		private function updateMap():void
		{
			if (!finished) {
				var end:FlxPoint = new FlxPoint(tracks[currentTrack].loc.x + tracks[currentTrack].end.x -tracks[currentTrack].start.x,
												tracks[currentTrack].loc.y + tracks[currentTrack].end.y -tracks[currentTrack].start.y);
				if (FlxU.getDistance(new FlxPoint(x, y), end) < 40 ) {
					if (currentTrack == tracks.length - 1) {
						finished = true;
					}
					else {
						currentTrack++;
						if (currentTrack > 1) {
							trackGroup.remove(tracks[currentTrack - 2].img);
							wallGroup.remove( tracks[currentTrack - 2].wallGroup, true);
						}
						if (currentTrack < tracks.length - 1) {
							trackGroup.add(tracks[currentTrack + 1].img);
							wallGroup.add( tracks[currentTrack + 1].wallGroup);
						}
					}
				}
			}
		}
		
		private function trackCollision():Boolean
		{
			return (tracks[currentTrack].img.pixels.getPixel(x - tracks[currentTrack].img.x, y - tracks[currentTrack].img.y) == 0x0000ff)
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
	}

}