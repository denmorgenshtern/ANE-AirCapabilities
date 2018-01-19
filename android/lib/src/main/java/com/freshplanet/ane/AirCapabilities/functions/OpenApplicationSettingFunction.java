package com.freshplanet.ane.AirCapabilities.functions;

import android.content.Intent;
import android.net.Uri;
import android.provider.Settings;
import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

import static com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension.TAG;
import static com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension.context;

public class OpenApplicationSettingFunction implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) 
	{
		try {
			Log.d(TAG, "OpenApplicationSettingFunction");

			final Intent i = new Intent();
			i.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
			i.addCategory(Intent.CATEGORY_DEFAULT);
			i.setData(Uri.parse("package:" + context.getActivity().getPackageName()));
			i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			i.addFlags(Intent.FLAG_ACTIVITY_NO_HISTORY);
			i.addFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
			context.getActivity().startActivity(i);

		} catch (Exception e) {
			Log.wtf(TAG, e);
		}
		
		return null;
	}

}
