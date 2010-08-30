package com.epologee.puremvc.model {

	/**
	 * @author Ralph Kuijpers @ Rocket Science Studios
	 */
	public interface IHasText {
		function getTextByID(inID : String) : String;
		function logDebugIDs() : void;
	}
}
