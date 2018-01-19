package com.freshplanet.ane.AirCapabilities.functions;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREWrongThreadException;
import com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension;

public class GetReferrerFunction implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {
		
		FREObject retValue = null;
		
		try {
			retValue = FREObject.newObject(AirCapabilitiesExtension.referrer);
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return retValue;
	}

}
