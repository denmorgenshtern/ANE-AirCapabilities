package com.freshplanet.ane.AirCapabilities.functions;

import android.content.Intent;
import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;

public class OpenApplicationFunction implements FREFunction
{
	@Override
	public FREObject call(FREContext context, FREObject[] args)
	{
		try
		{
			String id = args[0].getAsString();

			Intent launchIntent = context.getActivity().getPackageManager().getLaunchIntentForPackage(id);

			if (launchIntent != null) {
				context.getActivity().startActivity(launchIntent);
			}
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		
		return null;
	}
}
