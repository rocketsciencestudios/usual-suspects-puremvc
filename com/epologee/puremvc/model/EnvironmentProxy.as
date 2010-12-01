package com.epologee.puremvc.model {
	import nl.rocketsciencestudios.RSSVersion;
	import com.epologee.application.loaders.LoaderEvent;
	import com.epologee.application.loaders.LoaderItem;
	import com.epologee.application.loaders.LoaderQueue;
	import com.epologee.application.loaders.XMLLoaderItem;
	import com.epologee.application.preloader.IPreloadable;
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
		private var _preloadNames : Array;
		private var _domain : String;

		public function EnvironmentProxy(inTimeline : DisplayObjectContainer, inVersionHash : String, inPreloadNames : Array = null, inEnvironmentURL : String = null) {
			super(NAME);

			_preloadNames = inPreloadNames;
			_timeline = inTimeline;
			_versionHash = inVersionHash;
			_loaderURL = inTimeline.loaderInfo.loaderURL;

			_environment = new Dictionary();
			_environment[NAME] = new EnvironmentValueVO(NAME, inEnvironmentURL ? inEnvironmentURL : "../xml/environment.xml");

			debug("Loading environment url: " + getValueByName(NAME));
		}

		public function get domain() : String {
			return _domain;
		}

		public function getValueByName(inName : String, inAppendVariables : Object = null) : String {
			var value : EnvironmentValueVO = _environment[inName] as EnvironmentValueVO;

			if (!value) {
				error("getValueByName value not set for: " + inName);
				return "";
			}

			if (!value.isURL) {
				info("Returning non-url value");
				return value.value;
			}

			var suffix : String = "";

			if (inAppendVariables) {
				for (var key : String in inAppendVariables) {
					suffix += key + "=" + escape(inAppendVariables[key]) + "&";
				}
				suffix = suffix.substring(0, suffix.length - 1);
			}

			if (value.hashCompatible) {
				suffix += _versionHash;
			}

			return value.suffixURL(suffix);
		}

		public function getURLRequestByName(inName : String, inAppendVariables : Object = null) : URLRequest {
			var url : String = getValueByName(inName, inAppendVariables);
			if (url == "") return null;

			return new URLRequest(url);
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
			if (!_initializationProcess.start())
				return;

			var loader : XMLLoaderItem = new XMLLoaderItem(getValueByName(NAME), handleLoaderComplete, null, true);
			loader.addEventListener(LoaderEvent.ERROR, handleLoaderComplete);
		}

		public function get bytesToPreload() : Number {
			return 1024;
		}

		public function navigateToByName(inName : String, inWindow : String = "_blank", inAppendVariables : Object = null) : void {
			var request : URLRequest = new URLRequest(getValueByName(inName, inAppendVariables));
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
			_domain = getEnvironmentDomain();
			var groupedValues : XMLList = getGroupedValues(environment.group, _domain);

			if (groupedValues.length()) {
				filteredValues.appendChild(groupedValues);
			}

			var values : XMLList = filteredValues.children();
			for each (var valueNode : XML in values) {
				var value : EnvironmentValueVO = new EnvironmentValueVO();
				value.parseXML(valueNode);
				_environment[value.name] = value;
			}

			if (_preloadNames) {
				preloadXML();
			} else {
				_initializationProcess.finish();
			}
		}

		private function getGroupedValues(inGroups : XMLList, inDomain : String) : XMLList {
			if (!inGroups)
				return null;

			var groupedValues : XMLList;
			var localhost : XMLList;

			var leni : int = inGroups.length();
			for (var i : int = 0; i < leni ; i++) {
				var group : XML = inGroups[i] as XML;
				var domains : Array = String(group.@domain).split(",");
				for each (var domain : String in domains) {
					if (domain == inDomain) {
						info(RSSVersion.HASH + " Using environment domain ["+domains+"] in "+_loaderURL);
						groupedValues = group.value;
						break;
					} else if (domain == LOCALHOST) {
						localhost = group.value;
					}
				}
			}

			if (!groupedValues) {
				warn("Could not find a group for domain [" + domain + "], defaulting to [" + LOCALHOST + "] in " + _loaderURL);
				groupedValues = localhost;
			}

			return groupedValues;
		}

		private function preloadXML() : void {
			var preloadQueue : LoaderQueue = new LoaderQueue();
			preloadQueue.addEventListener(LoaderEvent.COMPLETE, handlePreloadElementComplete);
			preloadQueue.addEventListener(LoaderEvent.QUEUE_EMPTY, handlePreloadQueueComplete);
			preloadQueue.addEventListener(LoaderEvent.ERROR, handleLoaderError);
			//
			// XMLs:
			for each (var preloadName : String in _preloadNames) {
				preloadQueue.addXMLRequest(getValueByName(preloadName), preloadName);
			}
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

			// if (!result) {
			// /** TODO: There must be a way to do this in ONE regexp. :S */
			// domain = new RegExp("(?<=http:\/\/)([^/]*)", "i");
			// result = _loaderURL.match(domain);
			// }
			return result[1];
		}
	}
}
