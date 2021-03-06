/**
 * Copyright 2017 FreshPlanet
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>
#import "FlashRuntimeExtensions.h"

#define DEFINE_ANE_FUNCTION(fn) FREObject fn(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define MAP_FUNCTION(fn, data) { (const uint8_t*)(#fn), (data), &(fn) }

#define ROOT_VIEW_CONTROLLER [[[UIApplication sharedApplication] keyWindow] rootViewController]

void AirCapabilities_FPANE_DispatchEvent(FREContext context, NSString *eventName);
void AirCapabilities_FPANE_DispatchEventWithInfo(FREContext context, NSString *eventName, NSString *eventInfo);
void AirCapabilities_FPANE_Log(FREContext context, NSString *message);

NSString * AirCapabilities_FPANE_FREObjectToNSString(FREObject object);
NSArray * AirCapabilities_FPANE_FREObjectToNSArrayOfNSString(FREObject object);
NSDictionary * AirCapabilities_FPANE_FREObjectsToNSDictionaryOfNSString(FREObject keys, FREObject values);
BOOL AirCapabilities_FPANE_FREObjectToBool(FREObject object);
NSInteger AirCapabilities_FPANE_FREObjectToInt(FREObject object);

FREObject AirCapabilities_FPANE_BOOLToFREObject(BOOL boolean);
FREObject AirCapabilities_FPANE_IntToFREObject(NSInteger i);
FREObject AirCapabilities_FPANE_DoubleToFREObject(double d);
FREObject AirCapabilities_FPANE_NSStringToFREObject(NSString *string);

FREObject AirCapabilities_FPANE_CreateError( NSString* error, NSInteger* id );
