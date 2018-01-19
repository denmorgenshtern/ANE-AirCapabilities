package com.freshplanet.ane.AirCapabilities.functions;

import android.hardware.Camera;
import com.adobe.fre.*;

public class GetAvailableDevicesFunction implements FREFunction {

	@Override
	public FREObject call(FREContext arg0, FREObject[] arg1) {

		try {
			FREArray array = FREArray.newArray("com.freshplanet.ane.AirCapabilities.CaptureDevice", Camera.getNumberOfCameras(), false);

			Camera.CameraInfo cameraInfo = new Camera.CameraInfo();

			for (int i = 0; i < Camera.getNumberOfCameras(); i++) {
				Camera.getCameraInfo(i, cameraInfo);

				FREObject info = FREObject.newObject("com.freshplanet.ane.AirCapabilities.CaptureDevice", null);

				info.setProperty("id", FREObject.newObject(i));
				info.setProperty("orientation", FREObject.newObject(cameraInfo.orientation));
				info.setProperty("facing", FREObject.newObject(cameraInfo.facing));

				array.setObjectAt(i, info);
			}

			return array;

		} catch (FREASErrorException e) {
			e.printStackTrace();
		} catch (FRENoSuchNameException e) {
			e.printStackTrace();
		} catch (FREWrongThreadException e) {
			e.printStackTrace();
		} catch (FREInvalidObjectException e) {
			e.printStackTrace();
		} catch (FRETypeMismatchException e) {
			e.printStackTrace();
		} catch (FREReadOnlyException e) {
			e.printStackTrace();
		}
		
		return null;
	}

}
