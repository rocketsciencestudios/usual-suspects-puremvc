package com.epologee.puremvc.view {
	import com.epologee.development.logging.warn;
	import com.epologee.navigator.NavigationState;
	import com.epologee.navigator.behaviors.IHasStateUpdate;
	import com.epologee.navigator.behaviors.NavigationBehaviors;
	import com.epologee.navigator.integration.puremvc.NavigationProxy;
	import com.epologee.puremvc.analytics.GoogleAnalyticsProxy;

	import org.puremvc.as3.multicore.patterns.mediator.Mediator;

	import flash.utils.getQualifiedClassName;

	/**
	 * @author Eric-Paul Lecluse (c) epologee.com
	 */
	public class StatisticsMediator extends Mediator implements IHasStateUpdate {
		public static const NAME : String = getQualifiedClassName(StatisticsMediator);

		public function StatisticsMediator() {
			super(NAME);
		}

		override public function onRegister() : void {
			NavigationProxy(facade.retrieveProxy(NavigationProxy.NAME)).add(this, "", NavigationBehaviors.UPDATE);
		}

		public function updateState(inTruncated : NavigationState, inFull : NavigationState) : void {
			var ga : GoogleAnalyticsProxy = GoogleAnalyticsProxy(facade.retrieveProxy(GoogleAnalyticsProxy.NAME));
			
			if (!ga) {
				warn("GoogleAnalyticsProxy not registered at the facade");
				return;
			}
			ga.trackPageview(inFull.path);
		}
	}
}
