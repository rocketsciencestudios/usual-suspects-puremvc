package com.epologee.puremvc.model.vo {
	import com.epologee.application.dvo.IParsable;

	/**
	 * @author Eric-Paul Lecluse (c) epologee.com
	 */
	public class EnvironmentValueVO implements IParsable {
		public var name : String;
		public var isURL : Boolean;
		public var hashCompatible : Boolean;
		//
		private var _value : String;

		public function EnvironmentValueVO(inName : String = "", inValue : String = "", inIsURL : Boolean = true, inHashCompatible : Boolean = true) {
			name = inName;
			_value = inValue;
			isURL = inIsURL;
			hashCompatible = inHashCompatible;
		}

		/**
		 * <value name="TEXT" hash="true|false" isurl="true|false">../xml/copydeck.xml</value>
		 * 
		 * isurl defaults to true
		 * hash defaults to false
		 */
		public function parseXML(inXML : XML) : void {
			name = inXML.@name;
			_value = inXML;
			isURL = (inXML.@isurl != "false");
			hashCompatible = (inXML.@hash == "true");
		}

		public function get value() : String {
			return _value;
		}

		public function suffixValueWithHash(inHash : String):String {
			if (!hashCompatible)
				return _value;

			if (_value.indexOf("?") >= 0) {
				return _value + "&" + inHash;
			}

			return _value + "?" + inHash;
		}
	}
}
