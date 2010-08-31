package com.epologee.puremvc.model {
	import nl.rocketsciencestudios.club15.model.constants.EnvironmentNames;

	import com.epologee.application.loaders.LoaderEvent;
	import com.epologee.application.loaders.LoaderItem;
	import com.epologee.application.loaders.LoaderQueue;
	import com.epologee.application.loaders.XMLLoaderItem;
	import com.epologee.application.preloader.IPreloadable;
	import com.epologee.development.logging.debug;
	import com.epologee.development.logging.error;
	import com.epologee.development.logging.fatal;
	import com.epologee.development.logging.info;
	import com.epologee.development.logging.warn;
	import com.epologee.process.Process;
	import com.epologee.puremvc.model.vo.EnvironmentValueVO;

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
		// 2
		private var _timeline : DisplayObject;
		private var _loaderURL : String;
		private var _environment : Dictionary;
		private var _preloaded : Array;
		private var _versionHash : String;
		private var _initializationProcess : Process;

		public function EnvironmentProxy(inTimeline : DisplayObjectContainer, inVersionHash : String, inEnvironmentURL : String = null) {
			super(NAME);

			_timeline = inTimeline;
			_versionHash = inVersionHash;
			_loaderURL = inTimeline.loaderInfo.loaderURL;

			_environment = new Dictionary();
			_environment[NAME] = new EnvironmentValueVO(NAME, inEnvironmentURL ? inEnvironmentURL : "../xml/environment.xml");

			debug("Loading environment url: " + getValueByName(NAME));
		}

		public function getValueByName(inName : String) : String {
			var value : EnvironmentValueVO = _environment[inName] as EnvironmentValueVO;

			if (!value) {
				error("getValueByName value not set for: " + inName);
				return "";
			}

			if (!value.isURL) {
				info("Returning non-url value");
				return value.value;
			}

			return value.suffixValueWithHash(_versionHash);
		}

		public function getParameterByName(inName : String) : String {
			if (_timeline == null)
				return null;
			return _timeline.loaderInfo.parameters[inName];
		}

		public function getPreloadedByName(inName : String) : LoaderItem {
			for each (var element : LoaderItem in _preloaded) {
				if (element.name == inName)
					return element;
			}

			return null;
		}

		public function initialize(inCallback : Function) : void {
			_initializationProcess ||= new Process("initialization");
			_initializationProcess.addCallback(inCallback);
			if (!_initializationProcess.start()) return;
			
			var loader : XMLLoaderItem = new XMLLoaderItem(getValueByName(NAME), handleLoaderComplete, null, true);
			loader.addEventListener(LoaderEvent.ERROR, handleLoaderComplete);
		}

		public function get bytesToPreload() : Number {
			return 1024;
		}

		public function navigateToByName(inName : String, inWindow : String = "_blank") : void {
			var request : URLRequest = new URLRequest(getValueByName(inName));
			navigateToURL(request, inWindow);
		}

		private function handleLoaderComplete(event : LoaderEvent) : void {
			try {
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

				var values : XMLList = filteredValues.children();
				for each (var valueNode : XML in values) {
					var value : EnvironmentValueVO = new EnvironmentValueVO();
					value.parseXML(valueNode);
					_environment[value.name] = value;
				}

				preloadXML();
			} catch(error : Error) {
			}
		}

		private function preloadXML() : void {
			var preloadQueue : LoaderQueue = new LoaderQueue();
			preloadQueue.addEventListener(LoaderEvent.COMPLETE, handlePreloadElementComplete);
			preloadQueue.addEventListener(LoaderEvent.QUEUE_EMPTY, handlePreloadQueueComplete);
			preloadQueue.addEventListener(LoaderEvent.ERROR, handleLoaderError);
			//
			// XMLs:
			preloadQueue.addXMLRequest(getValueByName(EnvironmentNames.TEXT), EnvironmentNames.TEXT);
		}

		private function handlePreloadElementComplete(event : LoaderEvent) : void {
			_preloaded ||= [];
			_preloaded.push(event.item);
		}

		private function handlePreloadQueueComplete(event : LoaderEvent) : void {
			_initializationProcess.finish();
		}

		private function handleLoaderError(event : LoaderEvent) : void {
			fatal("ERROR_INITIALIZATION: " + event.errorMessage);
			clearListeners(event.target);
			_initializationProcess.finish(false);
		}

		private function clearListeners(inTarget : Object) : void {
			inTarget.removeEventListener(LoaderEvent.COMPLETE, handleLoaderComplete);
			inTarget.removeEventListener(LoaderEvent.ERROR, handleLoaderError);
		}

		private function getEnvironmentDomain() : String {
			if (!new RegExp("^http:/{2}", "i").test(_loaderURL))
				return LOCALHOST;

			var domain : RegExp = new RegExp("http:\/\/(?:www\.)?([^\/]+)", "i");
			var result : Array = _loaderURL.match(domain);

			info("getEnvironmentDomain:\n" + result.join("\n"));
			// if (!result) {
			// /** TODO: There must be a way to do this in ONE regexp. :S */
			// domain = new RegExp("(?<=http:\/\/)([^/]*)", "i");
			// result = _loaderURL.match(domain);
			// }
			return result[1];
		}
	}
}
