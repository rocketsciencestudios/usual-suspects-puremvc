package com.epologee.puremvc.model {
	import nl.rocketsciencestudios.adidas.constants.EnvironmentNames;

	import com.epologee.application.loaders.XMLLoaderItem;
	import com.epologee.puremvc.model.vo.TextVO;

	import org.puremvc.as3.multicore.patterns.proxy.Proxy;

	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;

	/**
	 * @author Eric-Paul Lecluse (c) epologee.com
	 */
	public class TextProxy extends Proxy implements IHasText {
		public static const NAME : String = getQualifiedClassName(TextProxy);
		//
		private var _textById : Dictionary;
		private var _debug : Boolean;
		private var _callback : Function;

		public function TextProxy(inDebug : Boolean) {
			super(NAME);
			
			_debug = inDebug;
			_textById = new Dictionary();
		}

		public function getTextByID(inID : String) : String {
			if (_debug && !_textById[inID]) {
				var d : TextVO = new TextVO();
				d.id = inID;
				d.text = "tx@" + inID; 
				_textById[inID] = d;
			}
			
			var text : TextVO = _textById[inID] as TextVO;
			if (text) {
				return text.text;
			}
			
			return "";
		}

		public function logDebugIDs() : void {
			var sorted : Array = [];
			
			for each (var t : TextVO in _textById) {
				sorted.push(t);
			}
			
			sorted.sortOn("id");
			debug(sorted.join("\n"));
		}

		public function initialize(inReadyCallback : Function) : void {
			_callback = inReadyCallback;
			
			var ep : EnvironmentProxy = EnvironmentProxy(facade.retrieveProxy(EnvironmentProxy.NAME));
			var copydeckName : String = EnvironmentNames.TEXT;
			var preloaded : XMLLoaderItem = ep.getPreloadedByName(copydeckName) as XMLLoaderItem;
			
			parseXML(preloaded.responseAsXML);
		}

		private function parseXML(inXML : XML) : void {
			for each (var node : XML in inXML.text) {
				var text : TextVO = new TextVO();
				text.parseXML(node);
				_textById[text.id] = text;
			}
			
			_callback();
		}
	}
}
