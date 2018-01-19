package com.freshplanet.ane.AirCapabilities.functions;

import android.content.pm.PackageManager;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREWrongThreadException;
import com.freshplanet.ane.AirCapabilities.AirCapabilitiesExtension;

public class GetInstallerPackageName implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {
		
		FREObject retValue = null;

        PackageManager pm = AirCapabilitiesExtension.context.getActivity().getPackageManager();
		String appId = AirCapabilitiesExtension.context.getActivity().getPackageName();
		String appInstallerId = pm.getInstallerPackageName(appId);

		try {
			retValue = FREObject.newObject(appInstallerId);
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		return retValue;
	}

}
