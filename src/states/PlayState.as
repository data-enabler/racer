package states 
{
	import audio.*;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.filters.*;
	import flash.geom.*;
	import flash.media.*;
	import flash.text.*;
	import com.adobe.serialization.json.*;
	import util.Raster;
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
		private const SPEED_MAX_WALK:Number = 0.75;
		private const SPEED_MAX_SLOW:Number = 0.5;
		private const SPEED_INCREMENT_KEYBOARD:Number = 0.01;
		private const SPEED_INCREMENT_MOUSE:Number = 0.003;
		private const DIR_INCREMENT_KEYBOARD:Number = 1;
		private const DIR_INCREMENT_MOUSE:Number = 0.5;
		private const STARTING_THREAD:uint = 9999;
		private const THREAD_COMSUMPTION_MULTIPLIER:Number = 1.0;
		private const THREAD_COMSUMPTION_MAX:Number = 3.0;
		private const BLUR_RATIO:Number = 10.0;
		private const BUMP_DIST:Number = 5.0;
		private const CRASH_SPEED_MED:Number = 0.5;
		private const CRASH_SPEED_FAST:Number = 2.5;
		private const MAX_CRASH_SLOW:uint = 1;
		private const MAX_CRASH_MED:uint  = 5;
		private const MAX_CRASH_FAST:uint = 7;
		private const SLOWDOWN_PENALTY_DURATION:uint = 10000;
		private const STITCH_LENGTH:Number = 10.0;
		private const STITCH_THRESH:Number = 10.0; // how close you have to be to undo a stitch
		private const STITCH_COLOR:uint = 0xff999999;
		private const STITCH_WIDTH:Number = 2.0;
		private const TRACK_WIDTH:uint = 80;	// for creating tracks programmatically
		private const NEEDLE_SIZE:uint = 4;
		
		[Embed(source = "../../res/sewing machine normal.mp3")]
		private var SewingMachine:Class;
		[Embed(source = "../../res/knot.png")]
		private var ImgKnot:Class;
		
		private var _state:uint;
		private var currentTrack:uint;
		private var tracks:Array;
		private var trackNames:Array;
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
		private var thread:Number;
		private var slowdownStartTime:uint;
		private var crashSlow:uint;
		private var crashMed:uint;
		private var crashFast:uint;
		private var path:Array;
		private var lastStitch:FlxPoint;
		private var stitchAboveSurface:Boolean;
		private var stitchSprite:FlxSprite;
		private var stitchSurface:FlxSprite;
		private var knotGroup:FlxGroup;
		
		private var txtThread:TextField;
		private var txtSlow:TextField;
		private var txtMed:TextField;
		private var txtFast:TextField;
		
		private var txtX:TextField;
		private var txtY:TextField;
		private var txtSpeed:TextField;
		private var txtDir:TextField;
		
		override public function create():void
		{
			FlxG.bgColor = 0xff224466; 
			//FlxG.visualDebug = true;
			
			filter = new BlurFilter(0, 0, BitmapFilterQuality.HIGH);
			needle = new FlxSprite();
			needle.makeGraphic(NEEDLE_SIZE, NEEDLE_SIZE);
			stitchSprite = new FlxSprite();
			stitchSurface = new FlxSprite();
			
			FlxG.camera.target = needle;
			FlxG.camera.zoom = ZOOM;
			FlxG.camera.antialiasing = true;
			FlxG.camera.getContainerSprite().parent.scrollRect = new Rectangle(0, 0, FlxG.width, FlxG.height);
			FlxG.mouse.show();
			
			trackGroup = new FlxGroup();
			knotGroup  = new FlxGroup();
			wallGroup  = new FlxGroup();
			trackNames = ["level1", "level3", "level2"];
			loadTracks(trackNames);
			resetMap();
			
			add(trackGroup);
			add(knotGroup);
			add(stitchSurface);
			add(stitchSprite);
			add(needle);
			add(wallGroup);
			
			musicPlayer = new MP3Player();
			bgAudio = new SewingMachine() as Sound;
			musicPlayer.playLoadedSound(bgAudio);
			
			txtThread = new TextField();
			txtSlow   = new TextField();
			txtMed    = new TextField();
			txtFast   = new TextField();
			txtThread.textColor = 0xFFFFFF;
			txtSlow.textColor   = 0xFFFFFF;
			txtMed.textColor    = 0xFFFFFF;
			txtFast.textColor   = 0xFFFFFF;
			txtThread.width = 120;
			txtSlow.width   = 120;
			txtMed.width    = 120;
			txtFast.width   = 120;
			txtThread.x = FlxG.width - 120;
			txtSlow.x   = FlxG.width - 120;
			txtMed.x    = FlxG.width - 120;
			txtFast.x   = FlxG.width - 120;
			txtThread.y = 0;
			txtSlow.y   = 12;
			txtMed.y    = 24;
			txtFast.y   = 36;
			FlxG.camera.getContainerSprite().parent.addChild(txtThread);
			FlxG.camera.getContainerSprite().parent.addChild(txtSlow);
			FlxG.camera.getContainerSprite().parent.addChild(txtMed);
			FlxG.camera.getContainerSprite().parent.addChild(txtFast);
			
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
			
			if (state == RaceState.SLOW)      speed = Math.min(speed, SPEED_MAX_SLOW);
			if (state == RaceState.BACKWARDS) speed = Math.min(speed, SPEED_MAX_WALK);
			
			var dx:Number = speed * SPEED_MULTIPLIER * Math.cos(dir / 180 * Math.PI);
			var dy:Number = speed * SPEED_MULTIPLIER * Math.sin(dir / 180 * Math.PI) * -1;
			
			// if not near track end
			if (!finished) {
				if (thread > 0)  {
					if (state != RaceState.BACKWARDS) {
						x += dx;
						y += dy;
						
						// collisions
						if (trackCollision()) handleCollision(dx, dy);
						
						for (var i:String in wallGroup.members) {
							for (var j:String in wallGroup.members[i].members) {
								var wall:Wall = wallGroup.members[i].members[j];
								if (wall.collides(needle)) {
									handleCollision(dx, dy);
								}
							}
						}
						if (speed > 0) thread = Math.max(0, thread - THREAD_COMSUMPTION_MULTIPLIER * Math.min(THREAD_COMSUMPTION_MAX, 1 / Math.sqrt(speed)));
					}
					else {
						// angles for rotating sprites aren't the same as what FlxU.getAngle returns, hence the 90-angle
						var angleDiff:Number = ((90 - FlxU.getAngle(new FlxPoint(x, y), path[path.length - 1])) - dir) % 360;
						if (angleDiff >=  180) angleDiff -= 360;
						if (angleDiff <= -180) angleDiff += 360;
						if (Math.abs(angleDiff) <= 90) {
							x += dx;
							y += dy;
							
							if (trackCollision()) {
								x -= dx;
								y -= dy;
								speed = 0.0;
							}
						}
						else speed = 0.0;
					}
				}
				else speed = 0.0
			}
			else {
				if (tracks.length > 1) {
					createTrack(path);
				}
				else {
					loadTracks(trackNames);
				}
				resetMap();
			}
			
			// draw HUD info
			txtThread.text = "Thread Remaining: " + thread.toString();
			var s:uint = (state == RaceState.SLOW)? SLOWDOWN_PENALTY_DURATION - (FlxU.getTicks() - slowdownStartTime) : crashSlow;
			txtSlow.text = "Slow Crashes: " + s.toString();
			txtMed.text  = "Medium Crashes: " + crashMed.toString() + "/" + MAX_CRASH_MED.toString();
			txtFast.text = "Fast Crashes: " + crashFast.toString() + "/" + MAX_CRASH_FAST.toString();
			
			// draw stitches
			updatePath();
			
			// keep track of slowdown time, etc
			updateState();
			
			// update filter
			var blur:Number = Math.max(speed - 1.0, 0) * BLUR_RATIO;
			(filter as BlurFilter).blurX = blur;
			var intX:int = Math.floor(x) - tracks[currentTrack].img.x;
			var intY:int = Math.floor(y) - tracks[currentTrack].img.y;
			var tmp1:BitmapData = new BitmapData(DISP_RADIUS * 2, DISP_RADIUS * 2, true, 0x00000000);
			var tmp2:BitmapData = new BitmapData(DISP_RADIUS * 2, DISP_RADIUS * 2, true, 0x00000000);
			var tmp3:BitmapData = new BitmapData(DISP_RADIUS * 2, DISP_RADIUS * 2, true, 0x00000000);
			var mat:Matrix = new Matrix();
			mat.translate( -DISP_RADIUS, -DISP_RADIUS);
			mat.rotate(dir / 180 * Math.PI);
			mat.translate(DISP_RADIUS, DISP_RADIUS);
			tmp1.copyPixels(tracks[currentTrack].img.pixels, 
				new Rectangle(intX - DISP_RADIUS, intY - DISP_RADIUS, DISP_RADIUS * 2, DISP_RADIUS * 2), new Point(0, 0));
			tmp2.draw(tmp1, mat, null, null, null, true);
			tmp3.applyFilter(tmp2, new Rectangle(0, 0, DISP_RADIUS * 2, DISP_RADIUS * 2), new Point(0, 0), filter);
			mat.invert();
			mat.translate(intX - DISP_RADIUS, intY - DISP_RADIUS);
			tracks[currentTrack].img.framePixels.draw(tmp3, mat, null, null, null, true);
			
			/* Makes some freaky effects
			var bmd:BitmapData = tracks[currentTrack].img.framePixels;
			bmd.draw(bmd, mat);
			bmd.applyFilter(bmd, new Rectangle( -DISP_RADIUS, -DISP_RADIUS, DISP_RADIUS * 2, DISP_RADIUS * 2), new Point(0, 0), filter);
			mat.invert();
			bmd.draw(bmd, mat);*/
			
			// move and rotate camera
			needle.x = x - needle.width  / 2;
			needle.y = y - needle.height / 2;
			needle.angle = 360 - dir;
			FlxG.camera.angle = dir;
			stitchSurface.x = int(x - DISP_RADIUS);
			stitchSurface.y = int(y - DISP_RADIUS);
			
			// adjust audio speed
			musicPlayer.playbackSpeed = speed;
			//musicPlayer.playbackSpeed = 0;
			
			// update track
			updateMap();
			
			// debug info display
			txtX.text = x.toString();
			txtY.text = y.toString();
			txtSpeed.text = speed.toString();
			txtDir.text = dir.toString();
		}
		
		private function loadTracks(names:Array):void
		{
			var trackX:int = 0;
			var trackY:int = 0;
			
			currentTrack = 0;
			resetStats();
			state = RaceState.FORWARDS;
			path = new Array();
			stitchAboveSurface = true;
			finished = false;
			knotGroup.kill();
			knotGroup.revive();
			stitchSurface.makeGraphic(DISP_RADIUS * 2, DISP_RADIUS * 2, 0);
			thread = STARTING_THREAD;
			
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
		
		private function createTrack(prevPath:Array):void
		{
			currentTrack = 0;
			resetStats();
			state = RaceState.FORWARDS;
			finished = false;
			knotGroup.kill();
			knotGroup.revive();
			stitchSurface.makeGraphic(DISP_RADIUS * 2, DISP_RADIUS * 2, 0);
			thread = STARTING_THREAD;
			
			var len:uint = prevPath.length;
			if (len > 1) 
			{
				var maxX:Number = Number.MIN_VALUE;
				var maxY:Number = Number.MIN_VALUE;
				var minX:Number = Number.MAX_VALUE;
				var minY:Number = Number.MAX_VALUE;
				
				for (var i:uint = 0; i < len; i++) {
					if (prevPath[i].x > maxX) maxX = prevPath[i].x;
					if (prevPath[i].y > maxY) maxY = prevPath[i].y;
					if (prevPath[i].x < minX) minX = prevPath[i].x;
					if (prevPath[i].y < minY) minY = prevPath[i].y;
				}
				
				var width:uint  = (maxX - minX) + 2 * TRACK_WIDTH;
				var height:uint = (maxY - minY) + 2 * TRACK_WIDTH;
				
				var img:BitmapData = new BitmapData(width, height, true, 0xff0000ff);
				var shape:Shape = new Shape();
				var canvas:Graphics = shape.graphics;
				canvas.lineStyle(TRACK_WIDTH, 0x00ff00);
				
				for (var j:uint = 0; j < len - 1; j++) {
					canvas.moveTo(prevPath[j].x + TRACK_WIDTH,     prevPath[j].y + TRACK_WIDTH); // offset from edges
					canvas.lineTo(prevPath[j + 1].x + TRACK_WIDTH, prevPath[j + 1].y + TRACK_WIDTH);
				}
				
				img.draw(shape);
				tracks = new Array(1);
				tracks[0] = new Object();
				tracks[0].start = new FlxPoint(prevPath[0].x - minX + TRACK_WIDTH,
											   prevPath[0].y - minY + TRACK_WIDTH);
				tracks[0].startAngle = 90 - FlxU.getAngle(new FlxPoint(prevPath[0].x, prevPath[0].y),
														  new FlxPoint(prevPath[1].x, prevPath[1].y));
				tracks[0].end = new FlxPoint(prevPath[len - 1].x - minX + TRACK_WIDTH,
											 prevPath[len - 1].y - minY + TRACK_WIDTH);
				tracks[0].img = new FlxSprite(-TRACK_WIDTH, -TRACK_WIDTH);
				tracks[0].img.pixels = img;
				tracks[0].wallGroup = new FlxGroup();
				tracks[0].loc = new FlxPoint(0, 0);
			}
			
			path = new Array();
			stitchAboveSurface = true;
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
			lastStitch = new FlxPoint(x, y);
			path.push(new FlxPoint(x, y));
			
			state = RaceState.FORWARDS;
			finished = false;
		}
		
		private function resetStats():void
		{
			crashSlow = 0;
			crashMed  = 0;
			crashFast = 0;
		}
		
		private function updateMap():void
		{
			if (!finished) {
				var end:FlxPoint   = new FlxPoint(tracks[currentTrack].loc.x + tracks[currentTrack].end.x - tracks[currentTrack].start.x,
												  tracks[currentTrack].loc.y + tracks[currentTrack].end.y - tracks[currentTrack].start.y);
				var start:FlxPoint = new FlxPoint(tracks[currentTrack].loc.x,
												  tracks[currentTrack].loc.y);
				if (state != RaceState.BACKWARDS) {
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
				else {
					if (FlxU.getDistance(new FlxPoint(x, y), start) < 40 ) {
						state = RaceState.FORWARDS;
					}
				}
			}
		}
		
		private function trackCollision():Boolean
		{
			return (tracks[currentTrack].img.pixels.getPixel(x - tracks[currentTrack].img.x, y - tracks[currentTrack].img.y) == 0x0000ff)
		}
		
		private function handleCollision(dx:Number, dy:Number):void
		{
			if (speed <= CRASH_SPEED_MED) crashSlow++;
			else if (speed <= CRASH_SPEED_FAST) crashMed++;
			else {
				crashFast++;
				var knot:FlxSprite = knotGroup.recycle(FlxSprite) as FlxSprite;
				knot.loadGraphic(ImgKnot);
				knot.color = STITCH_COLOR;
				knot.x = x - knot.width  / 2;
				knot.y = y - knot.height / 2;
				knotGroup.add(knot);
			}
				
			// backwards movement
			var newdx:Number = BUMP_DIST * Math.cos(dir / 180 * Math.PI) * -1;
			var newdy:Number = BUMP_DIST * Math.sin(dir / 180 * Math.PI);
			speed = 0;
			x -= dx;
			x += newdx;
			x -= dy;
			y += newdy;
			
			if (crashSlow >= MAX_CRASH_SLOW) {
				crashSlow = 0;
				state = RaceState.SLOW;
			}
			if (crashMed >= MAX_CRASH_MED) {
				crashMed = 0;
				state = RaceState.BACKWARDS;
			}
			if (crashFast >= MAX_CRASH_FAST) {
				if (currentTrack < tracks.length - 1) {
					currentTrack++;
					crashFast = 0;
					resetMap();
				}
			}
		}
		
		
		private function updatePath():void
		{
			var current:FlxPoint = new FlxPoint(x, y);
			
			if (state != RaceState.BACKWARDS) {
				if (FlxU.getDistance(current, lastStitch) >= STITCH_LENGTH) {
					if (stitchAboveSurface) stitchSprite.makeGraphic(1, 1, 0x00000000);
					stitchAboveSurface = !stitchAboveSurface;
					lastStitch = new FlxPoint(x, y);
					path.push(new FlxPoint(x, y));
				}
			}
			else {
				if (FlxU.getDistance(current, lastStitch) <= STITCH_THRESH) {
					if (stitchAboveSurface) stitchSprite.makeGraphic(1, 1, 0x00000000);
					stitchAboveSurface = !stitchAboveSurface;
					path.pop();
					lastStitch.copyFrom(path[path.length - 1]);
				}
			}
			
			drawStitches();
			
			if (stitchAboveSurface) {
				stitchSprite.makeGraphic(2 * STITCH_LENGTH, 2 * STITCH_LENGTH, 0x00000000, true);
				var mid:FlxPoint = new FlxPoint(stitchSprite.width / 2, stitchSprite.height / 2);
				stitchSprite.x = lastStitch.x - mid.x;
				stitchSprite.y = lastStitch.y - mid.y;
				Raster.efla(mid.x, mid.y,
							x - lastStitch.x + mid.x, 
							y - lastStitch.y + mid.y,
							STITCH_COLOR, stitchSprite.framePixels);
			}
		}
		
		private function drawStitches():void
		{
			var w:uint = FlxG.width;
			var h:uint = FlxG.height;
			var shape:Shape = new Shape();
			var canvas:Graphics = shape.graphics;
			canvas.lineStyle(STITCH_WIDTH, STITCH_COLOR);
			
			for (var i:int = 0; i < path.length - 1; i += 2) {
				canvas.moveTo(path[i].x,     path[i].y);
				canvas.lineTo(path[i + 1].x, path[i + 1].y);
			}
			stitchSurface.framePixels.fillRect(stitchSurface.framePixels.rect, 0);
			var m:Matrix = new Matrix();
			m.translate(int(DISP_RADIUS - x), int(DISP_RADIUS - y));
			stitchSurface.framePixels.draw(shape, m);
		}
		
		private function updateState():void
		{
			if (state == RaceState.SLOW) {
				if (FlxU.getTicks() - slowdownStartTime > SLOWDOWN_PENALTY_DURATION) {
					state = RaceState.FORWARDS;
				}
			}
		}
		
		private function set state(newState:uint):void
		{
			switch(newState) {
				case RaceState.FORWARDS:
					needle.makeGraphic(NEEDLE_SIZE, NEEDLE_SIZE, 0xffffffff);
					break;
				case RaceState.BACKWARDS:
					needle.makeGraphic(NEEDLE_SIZE, NEEDLE_SIZE, 0xffff9999);
					break;
				case RaceState.SLOW:
					needle.makeGraphic(NEEDLE_SIZE, NEEDLE_SIZE, 0xff6666ff);
					slowdownStartTime = FlxU.getTicks();
					break;
			}
			_state = newState;
		}
		
		private function get state():uint
		{
			return _state;
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

final class RaceState
{ 
	public static const FORWARDS:uint = 0; 
	public static const BACKWARDS:uint = 1;
	public static const SLOW:uint = 2;
}