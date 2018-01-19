package com.freshplanet.ane.AirCapabilities.functions;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;
import com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension;
import com.google.android.gms.analytics.CampaignTrackingReceiver;

public class CustomCampaignTrackingReceiver extends BroadcastReceiver {

	private static final String PLAY_STORE_REFERRER_KEY = "referrer";

	@Override
	public void onReceive(Context context, Intent intent) {
		//
		AirCapabilitiesExtension.referrer = intent.getStringExtra(PLAY_STORE_REFERRER_KEY);
		if(AirCapabilitiesExtension.doLogging)
			Log.d(AirCapabilitiesExtension.TAG, "onReceive: "+AirCapabilitiesExtension.referrer);
		// When you're done, pass the intent to the Google Analytics receiver.
	    new CampaignTrackingReceiver().onReceive(context, intent);
	}

}
