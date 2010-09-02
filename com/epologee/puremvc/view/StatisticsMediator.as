package com.epologee.puremvc.view {
	import com.epologee.navigator.integration.puremvc.NavigationProxy;
	import com.epologee.navigator.states.IHasStateUpdate;
	import com.epologee.navigator.states.NavigationState;
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
			NavigationProxy(facade.retrieveProxy(NavigationProxy.NAME)).addResponderUpdate(this, "");
		}

		public function updateState(inRemainder : NavigationState, inFull : NavigationState, inRegistered : NavigationState) : void {
			var ga : GoogleAnalyticsProxy = GoogleAnalyticsProxy(facade.retrieveProxy(GoogleAnalyticsProxy.NAME));
			
			if (!ga) {
				warning("GoogleAnalyticsProxy not registered at the facade");
				return;
			}
			ga.trackPageview(inFull.path);
		}
	}
}
