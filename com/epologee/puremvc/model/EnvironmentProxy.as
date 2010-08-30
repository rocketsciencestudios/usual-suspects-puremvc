package com.epologee.puremvc.model {
	import nl.rocketsciencestudios.RSSVersion;
	import nl.rocketsciencestudios.club15.model.constants.EnvironmentNames;

	import com.epologee.application.loaders.LoaderEvent;
	import com.epologee.application.loaders.LoaderItem;
	import com.epologee.application.loaders.LoaderQueue;
	import com.epologee.application.loaders.XMLLoaderItem;
	import com.epologee.application.preloader.IPreloadable;
	import com.epologee.development.logging.error;
	import com.epologee.development.logging.fatal;
	import com.epologee.development.logging.info;
	import com.epologee.development.logging.warn;

	import org.puremvc.as3.multicore.patterns.proxy.Proxy;

	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	/**
	 * @author Eric-Paul Lecluse (c) epologee.com
	 */
	public class EnvironmentProxy extends Proxy implements IPreloadable {
		public static const NAME : String = getQualifiedClassName(EnvironmentProxy);
		//
		private static const LOCALHOST : String = "localhost";
		//2
		private var _timeline : DisplayObject;
		private var _loaderURL : String;
		private var _initialized : Boolean = false;
		private var _environment : Dictionary;
		private var _environmentURL : String = "../xml/environment.xml?" + RSSVersion.HASH;
		private var _callback : Function;
		private var _preloaded : Array;

		public function EnvironmentProxy(inTimeline : DisplayObjectContainer, inEnvironmentURL : String = null) {
			super(NAME);
			
			_timeline = inTimeline;
			_loaderURL = inTimeline.loaderInfo.loaderURL;
			
			if (inEnvironmentURL != null) {
				_environmentURL = inEnvironmentURL;
			}
		}

		public function getValueByName(inName : String) : String {
			if (!isInitialized()) return "";
			
			if (_environment[inName] == null) {
				error("getValueByName value not set for: " + inName);
			}
			
			return _environment[inName];
		}

		public function getParameterByName(inName : String) : String {
			if (_timeline == null) return null;
			return _timeline.loaderInfo.parameters[inName];
		}

		public function getPreloadedByName(inName : String) : LoaderItem {
			for each (var element : LoaderItem in _preloaded) {
				if (element.name == inName) return element;
			}
			
			return null;
		}

		public function initialize(inCallback : Function) : void {
			_callback = inCallback;
			
			var loader : XMLLoaderItem = new XMLLoaderItem(_environmentURL, handleLoaderComplete, null, true);
			loader.addEventListener(LoaderEvent.ERROR, handleLoaderComplete);
		}

		public function get bytesToPreload() : Number {
			return 1024;
		}

		public function isInitialized() : Boolean {
			if (!_initialized) warn("checkInitialized: not yet initialized!");
			return _initialized;
		}

		public function navigateToByName(inName : String, inWindow : String = "_blank") : void {
			var request : URLRequest = new URLRequest(getValueByName(inName));
			navigateToURL(request, inWindow);
		}

		private function handleLoaderComplete(event : LoaderEvent) : void {
			clearListeners(event.target);
			
			var environment : XML = XMLLoaderItem(event.item).responseAsXML;
			var filteredValues : XML = <values />;
			
			// Values outside of <group> tags are shared in all environments:
			var sharedValues : XMLList = environment.value;
			if (sharedValues && sharedValues.length()) {
				filteredValues.appendChild(sharedValues);
			}

			// Values within <group> tags are only used if the group corresponds with the required mode:
			var domain : String = getEnvironmentDomain();
			var groupedValues : XMLList = environment.group.(@domain == domain).value;

			if (!groupedValues.length()) {
				warn("Could not find a group for domain [" + domain + "], defaulting to [" + LOCALHOST + "] in " + _loaderURL);
				groupedValues = environment.group.(@domain == LOCALHOST).value;
			} else {
				info("Using environment domain [" + domain + "] in " + _loaderURL);
			}
			
			if (groupedValues.length()) {
				filteredValues.appendChild(groupedValues);
			}
			
			_environment = new Dictionary();
			var values : XMLList = filteredValues.children();
			for each (var value : XML in values) {
				_environment[value.@name.toString()] = value;
			}

			/** Only used for debugging the passed in environment settings:
			for (var name : String in _environment) {
			temp(" * [" + name + "] = " + _environment[name]);
			}
			 */
			_initialized = true;
			
			preloadXML();
		}

		private function preloadXML() : void {
			var preloadQueue : LoaderQueue = new LoaderQueue();
			preloadQueue.addEventListener(LoaderEvent.COMPLETE, handlePreloadElementComplete);
			preloadQueue.addEventListener(LoaderEvent.QUEUE_EMPTY, handlePreloadQueueComplete);
			//
			// XMLs:
			preloadQueue.addXMLRequest(getValueByName(EnvironmentNames.TEXT) + "?" + RSSVersion.HASH, EnvironmentNames.TEXT);
		}

		private function handlePreloadElementComplete(event : LoaderEvent) : void {
			_preloaded ||= [];
			_preloaded.push(event.item);
		}

		private function handlePreloadQueueComplete(event : LoaderEvent) : void {
			_callback();
		}

		private function handleLoaderError(event : LoaderEvent) : void {
			clearListeners(event.target);
			
			fatal("ERROR_INITIALIZATION: " + event.errorMessage);
		}

		private function clearListeners(inTarget : Object) : void {
			inTarget.removeEventListener(LoaderEvent.COMPLETE, handleLoaderComplete);
			inTarget.removeEventListener(LoaderEvent.ERROR, handleLoaderError);
		}

		private function getEnvironmentDomain() : String {
			if (!new RegExp("^http:/{2}", "i").test(_loaderURL)) return LOCALHOST;
			
			var domain : RegExp = new RegExp("http:\/\/(?:www\.)?([^\/]+)", "i");
			var result : Array = _loaderURL.match(domain);
			
			info("getEnvironmentDomain:\n" + result.join("\n"));
			//			if (!result) {
			//				/** TODO: There must be a way to do this in ONE regexp. :S */
			//				domain = new RegExp("(?<=http:\/\/)([^/]*)", "i");
			//				result = _loaderURL.match(domain);
			//			}
			return result[1];
		}
	}
}
