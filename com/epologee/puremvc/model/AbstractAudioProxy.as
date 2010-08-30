package nl.rocketsciencestudios.club15.model {
	import com.epologee.audio.AudioEngine;
	import com.epologee.audio.AudioEvent;
	import com.epologee.audio.IAudioSample;
	import com.epologee.development.logging.info;
	import com.epologee.development.logging.notice;
	import com.greensock.TweenMax;

	import org.puremvc.as3.multicore.patterns.proxy.Proxy;

	import flash.display.Sprite;
	import flash.net.SharedObject;

	/**
	 * @author Eric-Paul Lecluse (c) epologee.com
	 */
	public class AbstractAudioProxy extends Proxy {
		public static const MUTE_CHANGED : String = NAME + ":MUTE_CHANGED";
		//
		private static const MAX_VOLUME : Number = 1;
		private static const MUTE_COOKIE : String = "PERSISTENT_MUTE_DATA";
		private static const FADE_SPEED : Number = 2;
		//
		private var _engine : AudioEngine;
		private var _mute : Boolean;

		public function AbstractAudioProxy(inTimeline : Sprite) {
			super(NAME);
			
			// Listen to audio events bubbled on the timeline.
			inTimeline.addEventListener(AudioEvent.PLAY, handleAudioEvent);
			inTimeline.addEventListener(AudioEvent.STOP, handleAudioEvent);
		}

		override public function onRegister() : void {
			initialize();
		}

		private function initialize() : void {
			_engine = new AudioEngine();
			
			getMuteStatus();
			
			addSounds();
		}

		protected function addSounds() : void {
			info();
			
//			_engine.addSound(AudioNames.YELLOW_ROLL_OVER, new SoundYellowRollOver(), false, 0.4, -0.2);
//			_engine.addSound(AudioNames.YELLOW_CLICK, new SoundYellowClick(), false, 0.4, -0.4);
//			_engine.addSound(AudioNames.GREEN_ROLL_OVER, new SoundGreenRollOver(), false, 0.4, 0.2);
//			_engine.addSound(AudioNames.GREEN_CLICK, new SoundGreenClick(), false, 0.4, 0.4);
//			_engine.addSound(AudioNames.ANSWER_CORRECT, new SoundAnswerCorrect(), false, 0.4, 0.3);
//			_engine.addSound(AudioNames.ANSWER_WRONG, new SoundAnswerWrong(), false, 0.15, -0.3);
//			_engine.addSound(AudioNames.SWAP_PRODUCTS, new SoundSwapProducts(), false, 0.5);
//			_engine.addSound(AudioNames.FOCUS_CHANGE, new SoundFocusChange(), false, 0.3);
//			_engine.addSound(AudioNames.WAITING, new SoundWaiting(), true, 0.4);
//			_engine.addSound(AudioNames.TITLE_INTRO, new SoundTitleIntro(), false, 0.4);
		}

		private function handleAudioEvent(event : AudioEvent) : void {
			notice(event.name);
			
			switch (event.type) {
				case AudioEvent.PLAY:
					_engine.play(event.name);
					break;
				case AudioEvent.STOP:
					_engine.stop(event.name);
					break;
			}
		}

		public function addSound(inName : String, inSound : *, inLoop : Boolean = false) : IAudioSample {
			return _engine.addSound(inName, inSound, inLoop);
		}

		private function getMuteStatus() : void {
			// Get shared mute status;
			var so : SharedObject = SharedObject.getLocal(MUTE_COOKIE);
			_mute = so.data.muted;
			if (_mute) {
				setMasterVolume(0, true);
			}
		}

		/**
		 * The sound with this name needs to be added to the engine in the initialize() method.
		 */
		public function play(inSoundName : String) : void {
			_engine.play(inSoundName);
		}

		public function stop(inSoundName : String) : void {
			_engine.stop(inSoundName);
		}

		/**
		 * Use this one to display the correct mute-button state when starting up.
		 */
		public function isMuted() : Boolean {
			return _mute;
		}

		/**
		 * Toggles the mute status, tweens the sound and remembers the state for the next visit.
		 */
		public function toggleMute() : Boolean {
			notice();
			
			_mute = !_mute;
			var so : SharedObject = SharedObject.getLocal(MUTE_COOKIE);
			so.data.muted = _mute;
			so.flush(); 
		
			setMasterVolume(_mute ? 0 : MAX_VOLUME);	
			
			sendNotification(MUTE_CHANGED, isMuted());
			return _mute;
		}

		/**
		 * Will tween the volume to the new value of @param inVolume.
		 * Bypass the tween with the @param inInstant flag.
		 */
		public function setMasterVolume(inVolume : Number, inInstant : Boolean = false) : void {
			if (inInstant) {
				_engine.masterVolume = inVolume;
				return;
			}
			
			TweenMax.to(_engine, FADE_SPEED, {masterVolume: inVolume});
		}

		public function fadeOut(inSoundName : String, inSecondsToFade : Number) : void {
			var sound : IAudioSample = _engine.getSoundByName(inSoundName);
			if (!sound) return;
			
			TweenMax.to(sound, inSecondsToFade, {volume: 0, onComplete: sound.stop});
		}

		public function setVolumeForSound(inSoundName : String, inVolume : Number) : void {
			var sound : IAudioSample = _engine.getSoundByName(inSoundName);
			if (!sound) return;
			
			sound.volume = inVolume;
		}
	}
}
