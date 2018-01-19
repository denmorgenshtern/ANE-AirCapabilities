
package com.freshplanet.ane.AirCapabilities.functions;

import android.provider.Settings.Secure;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREWrongThreadException;

import static com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension.context;

public class UniqueIDFunction implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {

		String uniqueID = Secure.getString(context.getActivity().getContentResolver(), Secure.ANDROID_ID);
		
		FREObject retValue = null;
		
		try {
			retValue = FREObject.newObject(uniqueID);
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return retValue;
	}

}
