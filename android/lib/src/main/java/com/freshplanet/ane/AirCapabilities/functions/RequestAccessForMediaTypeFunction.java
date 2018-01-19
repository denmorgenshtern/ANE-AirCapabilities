package com.freshplanet.ane.AirCapabilities.functions;

import android.util.Log;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

import static com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension.TAG;
import static com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension.context;

public class RequestAccessForMediaTypeFunction implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) 
	{
		try {
			String mediaType = arg1[0].getAsString();
			Boolean requestAccess = arg1[1].getAsBool();
			
			context.dispatchStatusEventAsync(mediaType, "AuthorizationStatusAuthorized");
		} catch (Exception e) {
			Log.wtf(TAG, e);
		}
		return null;
	}

}
