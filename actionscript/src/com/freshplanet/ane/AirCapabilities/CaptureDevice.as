package com.freshplanet.ane.AirCapabilities
{
    [RemoteClass(alias="com.freshplanet.ane.AirCapabilities.CaptureDevice")]
    public class CaptureDevice
    {
        public static var CAMERA_FACING_BACK:int = 0;
        public static var CAMERA_FACING_FRONT:int = 1;

        public var id:int;
        public var orientation:int;
        public var facing:int;
    }
}