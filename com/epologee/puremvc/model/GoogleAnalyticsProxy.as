package com.epologee.puremvc.model {
	import com.epologee.navigator.NavigationState;
	import com.google.analytics.GATracker;
	import com.google.analytics.core.TrackerMode;
	import com.google.analytics.v4.GoogleAnalyticsAPI;

	import org.puremvc.as3.multicore.patterns.proxy.Proxy;

	import flash.display.DisplayObjectContainer;
	import flash.utils.getQualifiedClassName;

	/**
	 * @author Eric-Paul Lecluse (c) epologee.com
	 */
	public class GoogleAnalyticsProxy extends Proxy {
		public static const NAME : String = getQualifiedClassName(GoogleAnalyticsProxy);
		//
		private static const FIRST_PAGE_VIEW : String = "app/flash";
		//
		private var _timeline : DisplayObjectContainer;
		//		private var _tracker : GoogleAnalyticsAPI;
		private var _pathPrefix : String;
		private var _accounts : Array;
		private var _trackers : Array;

		public function GoogleAnalyticsProxy(inTimeline : DisplayObjectContainer, inAccounts : *, inPathPrefix : String = "/") {
			super(NAME);
			_timeline = inTimeline;
			_accounts = (inAccounts is Array) ? inAccounts : [inAccounts];
			_pathPrefix = inPathPrefix;
		}

		override public function onRegister() : void {
			_trackers = [];
			
			debug("Using accounts: \n*\t" + _accounts.join("\n*\t") + "\n");
			if (_accounts.length) {
				for each (var account : String in _accounts) {
					if (account) {
						var tracker : GATracker = new GATracker(_timeline, account, TrackerMode.AS3, false);
						_trackers.push(tracker);
					}
				}
			}
			
			trackPageview(FIRST_PAGE_VIEW);
		}

		public function trackPageview(inPath : String) : void {
			var path : String = new NavigationState(_pathPrefix, inPath).path;
			if (!_trackers.length) {
				warn("trackPageview: BLOCKED: " + path);
				return;
			}
			
			info("trackPageview: " + path);
			for each (var tracker : GoogleAnalyticsAPI in _trackers) {
				tracker.trackPageview(path);
			}
		}

		public function trackEvent(inCategory : String, inAction : String, inLabel : String = "", inValue : Number = NaN) : void {
			var path : String = new NavigationState(_pathPrefix + "/" + inCategory).path;
			if (!_trackers.length) {
				warn("trackEvent: BLOCKED: " + [path, inAction, inLabel, inValue]);
				return;
			}
			
			notice("trackEvent: " + [path, inAction, inLabel, inValue]);
			for each (var tracker : GoogleAnalyticsAPI in _trackers) {
				tracker.trackEvent(path, inAction, inLabel, inValue);
			}
		}		
	}
}