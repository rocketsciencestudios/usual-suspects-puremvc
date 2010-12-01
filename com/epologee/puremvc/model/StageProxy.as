package com.epologee.puremvc.model {
	import com.epologee.util.ShortcutManager;
	import com.epologee.util.stage.StageSettings;

	import org.puremvc.as3.multicore.patterns.proxy.Proxy;

	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.geom.Point;
	import flash.utils.getQualifiedClassName;

	/**
	 * @author epologee
	 */
	public class StageProxy extends Proxy {
		public static const NAME : String = getQualifiedClassName(StageProxy);
		public static const RESIZE : String = NAME + ":RESIZE";
		//
		private var _timeline : Sprite;
		private var _dimensions : Point = new Point();
		private var _fullscreen : Boolean;

		public function StageProxy(inTimeline : Sprite, inScaleMode : String = null) {
			super(NAME);
			_timeline = inTimeline;
			
			if (inScaleMode) {
				StageSettings.apply(_timeline, inScaleMode);
			}
			
			if (_timeline.stage) {
				addListeners();
			} else {
				_timeline.addEventListener(Event.ADDED_TO_STAGE, addListeners);
			}
		}

		public function set fullscreen(inValue : Boolean) : void {
			if (inValue) {
				try {
					_timeline.stage.displayState = "fullScreenInteractive";
				} catch (e : Error) {
					try {
						_timeline.stage.displayState = StageDisplayState.FULL_SCREEN;
					} catch (e : Error) {
						error(e.message);
						return;
					}
				}
			} else {
				try {
					_timeline.stage.displayState = StageDisplayState.NORMAL;
				} catch (e : Error) {
					return;
					error(e.message);
				}
			}
		}

		public function get fullscreen() : Boolean {
			return _fullscreen;
		}

		public function ping() : void {
			if (_timeline.stage) {
				handleStageResize();
				return;				
			}
			
			warn("Too early, stage not yet available!");
		}

		public function get stage() : Stage {
			return _timeline.stage;
		}

		public function get timeline() : Sprite {
			return _timeline;
		}

		public function get dimensions() : Point {
			return _dimensions;
		}

		public function get frameRate() : Number {
			return _timeline.stage.frameRate;
		}

		public function set frameRate(framerate : Number) : void {
			_timeline.stage.frameRate = framerate;
		}

		private function addListeners(event : Event = null) : void {
			_timeline.stage.addEventListener(FullScreenEvent.FULL_SCREEN, handleFullScreenEvent);
			_timeline.stage.addEventListener(Event.RESIZE, handleStageResize);
			_dimensions.x = _timeline.stage.stageWidth;
			_dimensions.y = _timeline.stage.stageHeight;
			ShortcutManager.setStage(_timeline.stage);
			
			frameRate = 24;
		}

		private function handleFullScreenEvent(event : FullScreenEvent) : void {
			_fullscreen = event.fullScreen;
			handleStageResize();
		}

		private function handleStageResize(event : Event = null) : void {
			_dimensions.x = _timeline.stage.stageWidth;
			_dimensions.y = _timeline.stage.stageHeight;
			sendNotification(RESIZE, _dimensions);
		}
	}
}
