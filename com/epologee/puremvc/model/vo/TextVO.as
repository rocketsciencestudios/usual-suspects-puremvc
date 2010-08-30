package com.epologee.puremvc.model.vo {
	import com.epologee.application.dvo.IParsable;

	/**
	 * @author Eric-Paul Lecluse (c) epologee.com
	 */
	public class TextVO implements IParsable {
		public var id : String;
		public var text : String;

		public function parseXML(inXML : XML) : void {
			id = inXML.@id;
			text = inXML;
		}
		
		public function toString() : String {
			return 	"<text id=\""+id+"\"><![CDATA["+text+"]]></text>";

		}
	}
}
