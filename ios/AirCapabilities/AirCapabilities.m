//
//  AirCapabilities.m
//  AirCapabilities
//
//  Created by Thibaut Crenn on 05/06/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AirCapabilities.h"
#import <sys/utsname.h>

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "DeviceUID.h"

#define DEFINE_ANE_FUNCTION(fn) FREObject (fn)(FREContext context, void* functionData, uint32_t argc, FREObject argv[])

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

FREContext myAirCapaCtx = nil;
bool doLogging = false;

@implementation AirCapabilities

@synthesize iTunesURL;

+(id) sharedInstance {
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    
    return sharedInstance;
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (myAirCapaCtx)
    {
        FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[@"DISMISS" UTF8String], (uint8_t*)[@"OK" UTF8String]);
    }
    
    id delegate = [[UIApplication sharedApplication] delegate];
    [[[delegate window] rootViewController] dismissModalViewControllerAnimated:NO];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)openReferralURL:(NSURL *)referralURL
{
    NSURLConnection *con = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:referralURL] delegate:self startImmediately:YES];
    [con release];
}

// Save the most recent URL in case multiple redirects occur
// "iTunesURL" is an NSURL property in your class declaration
- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    self.iTunesURL = [response URL];
    if( [self.iTunesURL.host hasSuffix:@"itunes.apple.com"])
    {
        [connection cancel];
        [self connectionDidFinishLoading:connection];
        return nil;
    }
    else
    {
        return request;
    }
}

// No more redirects; use the last URL saved
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    [[UIApplication sharedApplication] openURL:self.iTunesURL];
}

// Open an application (if installed on the device) or send the player to the appstore
//
// @param schemes : NSArray      - List of schemes (String) that the application accepts.  Examples : @"sms://", @"twit://".  You can find schemes in http://handleopenurl.com/
// @param appStoreURL : NSURL    - (optional) Link to the AppStore page for the Application for the player to download. URL can be generated via Apple's linkmaker (itunes.apple.com/linkmaker?)
- (void) openApplication:(NSArray*)schemes appStoreURL:(NSURL*)appStoreURL
{
    BOOL canOpenApplication;
    for (NSString* scheme in schemes)
    {
        canOpenApplication = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:scheme]];
        if (canOpenApplication)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:scheme]];
            break;
        }
    }
        
    if (!canOpenApplication)
    {
        if (appStoreURL != nil)
        {
            [[UIApplication sharedApplication] openURL:appStoreURL];
        }
    }
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [[UIApplication sharedApplication].delegate.window.rootViewController dismissModalViewControllerAnimated:YES];
    
    if (myAirCapaCtx)
        FREDispatchStatusEventAsync(myAirCapaCtx, (const uint8_t*)"CLOSED_MODAL_APP_STORE", (const uint8_t*)"");
}

- (void) openModalAppStore:(NSString*)appStoreID {
    
    if (!NSClassFromString(@"SKStoreProductViewController")) // if feature is not available
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", appStoreID]]];
    else
    {
        SKStoreProductViewController* storeController = [[SKStoreProductViewController alloc] init];
        storeController.delegate = self;
        
        [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:storeController animated:YES completion:nil];
        
        [storeController loadProductWithParameters:@{ SKStoreProductParameterITunesItemIdentifier: appStoreID }
                                   completionBlock:^(BOOL result, NSError *error) {
                                       
                                       if (!result) {
                                           
                                           [[UIApplication sharedApplication].delegate.window.rootViewController dismissModalViewControllerAnimated:YES];
                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", appStoreID]]];
                                       }
                                   }];
    }
}

@end


DEFINE_ANE_FUNCTION(hasSMS)
{
    BOOL value = [MFMessageComposeViewController canSendText];
    FREObject retBool = nil;
    FRENewObjectFromBool(value, &retBool);
    return retBool;
}


DEFINE_ANE_FUNCTION(hasTwitter)
{
    BOOL value = false;
    value =[TWTweetComposeViewController canSendTweet];
    
    if (!value)
    {
        NSArray* schemeArray = [NSArray arrayWithObjects:@"twitter:///post?message=Hello", @"twitterrific://", @"twit://", @"tweetbot://", @"twinkle://", nil];
        
        for (NSString* scheme in schemeArray) {
            value = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:scheme]];
            if (value)
            {
                break;
            }
        }

    }
    FREObject retBool = nil;
    FRENewObjectFromBool(value, &retBool);
    return retBool;
}

DEFINE_ANE_FUNCTION(sendSms)
{
    uint32_t string_length;
    const uint8_t *utf8_message;
    NSString* message;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_message) == FRE_OK)
    {
        message = [NSString stringWithUTF8String:(char*) utf8_message];
    }

    const uint8_t *utf8_recipient;
    NSString* recipientString = nil;
    if (FREGetObjectAsUTF8(argv[1], &string_length, &utf8_recipient) == FRE_OK)
    {
        recipientString = [NSString stringWithUTF8String:(char*) utf8_recipient];
    }

    
    
    if (message != nil)
    {
        MFMessageComposeViewController *viewController = [[MFMessageComposeViewController alloc] init];
        viewController.body = message;
        
        if (recipientString != nil)
        {
            viewController.recipients = [NSArray arrayWithObject:recipientString];
        }
        
        viewController.messageComposeDelegate = [AirCapabilities sharedInstance];
        id delegate = [[UIApplication sharedApplication] delegate];
        [[[delegate window] rootViewController] presentModalViewController:viewController animated:YES];
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(sendWithTwitter)
{
    uint32_t string_length;
    const uint8_t *utf8_message;
    NSString* message;
    NSString* urlEncodedMessage;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_message) == FRE_OK)
    {
        message = [NSString stringWithUTF8String:(char*) utf8_message];
        urlEncodedMessage = (NSString *)CFURLCreateStringByAddingPercentEscapes( NULL,	 (CFStringRef)message,	 NULL,	 (CFStringRef)@"!’\"();:@&=+$,/?%#[]% ", kCFStringEncodingISOLatin1);
    }
    
    if (message != nil)
    {
        
        if ([TWTweetComposeViewController canSendTweet])
        {
            TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
            
            // Set the initial tweet text. See the framework for additional properties that can be set.
            [tweetViewController setInitialText:message];            
            
            // Create the completion handler block.
            [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
                NSString *output;
                
                switch (result) {
                    case TWTweetComposeViewControllerResultCancelled:
                        // The cancel button was tapped.
                        output = @"Tweet cancelled.";
                        break;
                    case TWTweetComposeViewControllerResultDone:
                        // The tweet was sent.
                        output = @"Tweet done.";
                        break;
                    default:
                        break;
                }
                
                id delegate = [[UIApplication sharedApplication] delegate];
                // Dismiss the tweet composition view controller.
                [[[delegate window] rootViewController] dismissModalViewControllerAnimated:YES];
            }];
            
            // Present the tweet composition view controller modally.
            id delegate = [[UIApplication sharedApplication] delegate];
            [[[delegate window] rootViewController] presentModalViewController:tweetViewController animated:YES];

        } else
        {
//            NSArray* schemeArray = [NSArray arrayWithObjects:@"twitter://", @"twitterrific://", @"twit://", @"tweetbot://", @"twinkle://", nil];
//            for (NSString* scheme in schemeArray) {
//                NSString *fullScheme = [NSString stringWithFormat:@"%@/post?message=%@", scheme, urlEncodedMessage];
//                NSURL *url = [NSURL URLWithString:fullScheme];
//                if ([[UIApplication sharedApplication] canOpenURL:url])
//                {
//                    [[UIApplication sharedApplication] openURL:url];
//                    break;
//                }
//            }
            // Build our schemes
            NSArray* schemes = [NSArray arrayWithObjects:@"twitter://", @"twitterrific://", @"twit://", @"tweetbot://", @"twinkle://", nil];
            NSMutableArray* fullSchemes = [[NSMutableArray alloc] init];
            for (NSString *scheme in schemes) {
                [fullSchemes addObject:[NSString stringWithFormat:@"%@/post?message=%@", scheme, urlEncodedMessage]];
            }
            [[AirCapabilities sharedInstance] openApplication:fullSchemes appStoreURL:nil];
        }
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(redirectToRating)
{
    uint32_t string_length;
    const uint8_t *utf8_appId;
    
    NSString* url;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_appId) == FRE_OK)
    {
        if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
        {
            url = [NSString stringWithFormat: @"itms-apps://itunes.apple.com/app/id%@", [NSString stringWithUTF8String:(char*) utf8_appId]]; //@"518042655"
        } else
        {
            url = [NSString stringWithFormat: @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", [NSString stringWithUTF8String:(char*) utf8_appId]]; //@"518042655"

        }
    }

    if (url != nil)
    {
//        NSURL *urlScheme = [NSURL URLWithString:url];
//        if ([[UIApplication sharedApplication] canOpenURL:urlScheme])
//        {
//            [[UIApplication sharedApplication] openURL:urlScheme];
//        }
        [[AirCapabilities sharedInstance] openApplication:[NSArray arrayWithObject:url] appStoreURL:nil];
    }
    
    return nil;
}


DEFINE_ANE_FUNCTION(getDeviceModel)
{
    
    NSString *model = [[UIDevice currentDevice] model];
    
    const char *str = [model UTF8String];
    FREObject retStr;
	FRENewObjectFromUTF8(strlen(str)+1, (const uint8_t*)str, &retStr);

    return retStr;
}

DEFINE_ANE_FUNCTION(getMachineName) {
	struct utsname systemInfo;
	uname(&systemInfo);
	const char *str = systemInfo.machine;
	FREObject retStr;
	FRENewObjectFromUTF8(strlen(str)+1, (const uint8_t*)str, &retStr);
	return retStr;
}

DEFINE_ANE_FUNCTION(processReferralLink)
{
    
    uint32_t string_length;
    const uint8_t *utf8_itunesUrl;
    
    NSString* url;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_itunesUrl) == FRE_OK)
    {
        url = [NSString stringWithUTF8String:(char*) utf8_itunesUrl];
    }
    
    NSURL* nsUrl = [NSURL URLWithString:url];
    [[AirCapabilities sharedInstance] openReferralURL:nsUrl];
    
    return NULL;
}


DEFINE_ANE_FUNCTION(redirectToPageId)
{
    
    uint32_t string_length;
    const uint8_t *utf8_pageId;
    
    NSString* pageId;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_pageId) == FRE_OK)
    {
        pageId = [NSString stringWithUTF8String:(char*) utf8_pageId];
    }

    NSString* schemeString = [NSString stringWithFormat:@"fb://profile/%@", pageId];
    NSURL* schemeUrl = [NSURL URLWithString:schemeString];
    
    if(doLogging)
        NSLog(@"scheme: %@", schemeString);
    
    if (![[UIApplication sharedApplication] canOpenURL:schemeUrl])
    {
        if(doLogging)
            NSLog(@"%@", @"Cannot log");

        schemeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.facebook.com/%@", pageId]];
    }
    
    [[UIApplication sharedApplication] openURL:schemeUrl];
    
    return NULL;
}


DEFINE_ANE_FUNCTION(redirectToTwitterAccount)
{
    
    uint32_t string_length;
    const uint8_t *utf8_pageId;
    
    NSString* pageId;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_pageId) == FRE_OK)
    {
        pageId = [NSString stringWithUTF8String:(char*) utf8_pageId];
    }
    
    NSString* schemeString = [NSString stringWithFormat:@"twitter://user?screen_name=%@", pageId];
    NSURL* schemeUrl = [NSURL URLWithString:schemeString];
    if(doLogging)
        NSLog(@"scheme: %@", schemeString);

    if (![[UIApplication sharedApplication] canOpenURL:schemeUrl])
    {
        if(doLogging)
            NSLog(@"%@", @"Cannot log");

        schemeUrl = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.twitter.com/%@", pageId]];
    }
    
    [[UIApplication sharedApplication] openURL:schemeUrl];
    
    return NULL;
}


DEFINE_ANE_FUNCTION(canPostPictureOnTwitter)
{
    BOOL value = false;
    value = [TWTweetComposeViewController canSendTweet];
    FREObject retBool = nil;
    FRENewObjectFromBool(value, &retBool);
    return retBool;
}


DEFINE_ANE_FUNCTION(getOSVersion)
{
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    const uint8_t *utf8_message = (const uint8_t *)  [systemVersion UTF8String];
    uint32_t string_length = [systemVersion length];
    FREObject retString = nil;
    FRENewObjectFromUTF8(string_length, utf8_message, &retString);
    return retString;
}


DEFINE_ANE_FUNCTION(postPictureOnTwitter)
{
    
    uint32_t string_length;
    const uint8_t *utf8_message;
    
    NSString* message;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_message) == FRE_OK)
    {
        message = [NSString stringWithUTF8String:(char*) utf8_message];
    }

    FREBitmapData bitmapData;
    UIImage *rewardImage;
    if (FREAcquireBitmapData(argv[1], &bitmapData) == FRE_OK)
    {
        
        // make data provider from buffer
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bitmapData.bits32, (bitmapData.width * bitmapData.height * 4), NULL);
        
        // set up for CGImage creation
        int                     bitsPerComponent    = 8;
        int                     bitsPerPixel        = 32;
        int                     bytesPerRow         = 4 * bitmapData.width;
        CGColorSpaceRef         colorSpaceRef       = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo            bitmapInfo;
        
        if( bitmapData.hasAlpha )
        {
            if( bitmapData.isPremultiplied )
                bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst;
            else
                bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaFirst;
        }
        else
        {
            bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
        }
        
        CGColorRenderingIntent  renderingIntent     = kCGRenderingIntentDefault;
        CGImageRef              imageRef            = CGImageCreate(bitmapData.width, bitmapData.height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
        
        // make UIImage from CGImage
        rewardImage = [UIImage imageWithCGImage:imageRef];
        
        FREReleaseBitmapData( argv[1] );
    }

    
    
    TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
    
    // Set the initial tweet text. See the framework for additional properties that can be set.
    [tweetViewController setInitialText:message];
    [tweetViewController addImage:rewardImage];
    
    
    // Create the completion handler block.
    [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
        NSString *output;
        
        switch (result) {
            case TWTweetComposeViewControllerResultCancelled:
                // The cancel button was tapped.
                output = @"Tweet cancelled.";
                break;
            case TWTweetComposeViewControllerResultDone:
                // The tweet was sent.
                output = @"Tweet done.";
                break;
            default:
                break;
        }
        
        id delegate = [[UIApplication sharedApplication] delegate];
        // Dismiss the tweet composition view controller.
        [[[delegate window] rootViewController] dismissModalViewControllerAnimated:YES];
    }];
    
    // Present the tweet composition view controller modally.
    id delegate = [[UIApplication sharedApplication] delegate];
    [[[delegate window] rootViewController] presentModalViewController:tweetViewController animated:YES];

    return nil;
    
}


DEFINE_ANE_FUNCTION(openExternalApplication)
{
    uint32_t string_length;
    uint32_t arr_len; // array length

    const uint8_t *utf8_appStoreURL;
    
    FREObject arr = argv[0];
    FREGetArrayLength(arr, &arr_len);
    NSMutableArray* schemes = [[NSMutableArray alloc] init];
    for (int32_t i = 0; i < arr_len; i++)
    {
        // Get element at current index
        FREObject element;
        FREGetArrayElementAt(arr, i, &element);
        
        // check if element is valid
        const uint8_t *elementStr;
        if (FREGetObjectAsUTF8(element, &string_length, &elementStr) != FRE_OK)
        {
            continue;
        }
        
        // Convert to NSString and add it to schemes
        NSString* elem = [NSString stringWithUTF8String:(char*)elementStr];
        [schemes addObject:elem];
    }
    
    NSURL* appStoreURL = nil;
    if (FREGetObjectAsUTF8(argv[1], &string_length, &utf8_appStoreURL) == FRE_OK)
    {
        appStoreURL = [NSURL URLWithString:[NSString stringWithUTF8String:(char*) utf8_appStoreURL]];
    }

    
    bool canOpenApplication = false;
    
    for (NSString* scheme in schemes)
    {
        canOpenApplication = canOpenApplication || [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:scheme]];
    }

    
    if (myAirCapaCtx)
    {
        FREDispatchStatusEventAsync(context, (uint8_t*)[@"OPEN_URL" UTF8String], canOpenApplication ? (uint8_t*)[@"APP" UTF8String] : (uint8_t*)[@"STORE" UTF8String]);
    }
    
    
    [[AirCapabilities sharedInstance] openApplication:schemes appStoreURL:appStoreURL];
    
    return nil;
}

DEFINE_ANE_FUNCTION(AirCapabilitiesCanOpenURL)
{
    uint32_t stringLength;
    
    const uint8_t *urlString;
    NSURL *url;
    if (FREGetObjectAsUTF8(argv[0], &stringLength, &urlString) == FRE_OK)
    {
        url = [NSURL URLWithString:[NSString stringWithUTF8String:(const char *)urlString]];
    }
    
    BOOL canOpenURL = url ? [[UIApplication sharedApplication] canOpenURL:url] : NO;
    FREObject result;
    FRENewObjectFromBool(canOpenURL, &result);
    return result;
}

DEFINE_ANE_FUNCTION(AirCapabilitiesOpenURL)
{
    uint32_t stringLength;
    
    const uint8_t *urlString;
    NSURL *url;
    if (FREGetObjectAsUTF8(argv[0], &stringLength, &urlString) == FRE_OK)
    {
        url = [NSURL URLWithString:[NSString stringWithUTF8String:(const char *)urlString]];
    }
    
    BOOL canOpenURL = url ? [[UIApplication sharedApplication] canOpenURL:url] : NO;
    
    if (canOpenURL)
    {
        [[UIApplication sharedApplication] openURL:url];
    }
    
    return nil;
}

DEFINE_ANE_FUNCTION(AirCapabilitiesSetLogging)
{
    unsigned int loggingValue = 0;
    if (FREGetObjectAsBool(argv[0], &loggingValue) == FRE_OK)
        doLogging = (loggingValue != 0);
    
    return nil;
}

DEFINE_ANE_FUNCTION(traceLog)
{
    int32_t logLevel;
    if(FREGetObjectAsInt32(argv[0], &logLevel) != FRE_OK) {
        NSLog(@"[AirCapabilities] Error trying to call traceLog from flash");
        return nil;
    }
    
    uint32_t strlen;
    const uint8_t *tag;
    const uint8_t *msg;

    if((FREGetObjectAsUTF8(argv[1], &strlen, &tag) != FRE_OK) || (FREGetObjectAsUTF8(argv[2], &strlen, &msg) != FRE_OK)) {
        NSLog(@"[AirCapabilities] Error trying to call traceLog from flash");
        return nil;
    }
    
    NSString *formatString;

    switch (logLevel) {
        case 2:
            formatString = @"[Verbose][%s]: %s";
            break;
        case 3:
            formatString = @"[Debug][%s]: %s";
            break;
        case 4:
            formatString = @"[Info][%s]: %s";
            break;
        case 5:
            formatString = @"[Warn][%s]: %s";
            break;
        case 6:
            formatString = @"[Error][%s]: %s";
            break;
    }
    
    NSLog(formatString, tag, msg);
    return nil;
}

DEFINE_ANE_FUNCTION(AirCapabilitiesOpenModalAppStore)
{
    uint32_t stringLength;
    
    const uint8_t *appStoreIdString;
    NSString* appStoreID;
    
    if (FREGetObjectAsUTF8(argv[0], &stringLength, &appStoreIdString) == FRE_OK)
        appStoreID = [NSString stringWithUTF8String:(const char *)appStoreIdString];
    
    [[AirCapabilities sharedInstance] openModalAppStore:appStoreID];
    
    return nil;
}

DEFINE_ANE_FUNCTION(requestAccessForMediaType) {
    
    uint32_t string_length;
    const uint8_t *utf8_mediaType;
    NSString* mediaType;
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_mediaType) == FRE_OK)
    {
        mediaType = [NSString stringWithUTF8String:(char*) utf8_mediaType];
    }
    
    uint32_t requestAccess;
    FREGetObjectAsBool(argv[1], &requestAccess);
    
    NSLog(@"requestAccessForMediaType %@ requestAccess %d", mediaType, requestAccess);
    
    if([mediaType isEqual: @"ALAssetsLibrary"]) {
        ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
        
        if (status == ALAuthorizationStatusAuthorized)
        {
            NSLog(@"AuthorizationStatusAuthorized to %@", mediaType);
            FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusAuthorized" UTF8String]);
        }
        else if(status == ALAuthorizationStatusRestricted)
        {
            NSLog(@"AuthorizationStatusRestricted to %@", mediaType);
            FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusRestricted" UTF8String]);
        }
        else if(status == ALAuthorizationStatusDenied)
        {
            NSLog(@"AuthorizationStatusDenied to %@", mediaType);
            FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusDenied" UTF8String]);
        }
        else if(status == ALAuthorizationStatusNotDetermined)
        {
            if(requestAccess) {
                ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
                
                [lib enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                    NSLog(@"AuthorizationStatusAuthorized to %@", mediaType);
                    FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusAuthorized" UTF8String]);
                } failureBlock:^(NSError *error) {
                    if (error.code == ALAssetsLibraryAccessUserDeniedError) {
                        NSLog(@"AuthorizationStatusDenied to %@", mediaType);
                        FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusDenied" UTF8String]);
                    }else{
                        NSLog(@"AuthorizationStatusDenied to %@", mediaType);
                        FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusDenied" UTF8String]);
                    }
                }];
            }
            else
            {
                NSLog(@"AuthorizationStatusNotDetermined to %@", mediaType);
                FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusNotDetermined" UTF8String]);
            }
        }
        
        return NULL;
    }
    
    if([mediaType  isEqual: @"vide"])
        mediaType = AVMediaTypeVideo;
    else if([mediaType  isEqual: @"soun"])
        mediaType = AVMediaTypeAudio;
    else
        return NULL;
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus == AVAuthorizationStatusAuthorized)
    {
        NSLog(@"AuthorizationStatusAuthorized to %@", mediaType);
        FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusAuthorized" UTF8String]);
    }
    else if(authStatus == AVAuthorizationStatusNotDetermined)
    {
        if(requestAccess){
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted)
             {
                 if(granted)
                 {
                     NSLog(@"AuthorizationStatusAuthorized to %@", mediaType);
                     FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusAuthorized" UTF8String]);
                 }
                 else
                 {
                     NSLog(@"AuthorizationStatusDenied to %@", mediaType);
                     FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusDenied" UTF8String]);
                 }
             }];
        }else{
            NSLog(@"AuthorizationStatusNotDetermined to %@", mediaType);
            FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusNotDetermined" UTF8String]);
        }
    }
    else if (authStatus == AVAuthorizationStatusRestricted)
    {
        NSLog(@"AuthorizationStatusRestricted to %@", mediaType);
        FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusRestricted" UTF8String]);
    }
    else if (authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"AuthorizationStatusDenied to %@", mediaType);
        FREDispatchStatusEventAsync(myAirCapaCtx, (uint8_t*)[mediaType UTF8String], (uint8_t*)[@"AuthorizationStatusDenied" UTF8String]);
    }
    
    return NULL;
}

DEFINE_ANE_FUNCTION(openApplicationSetting) {
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0"))
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    
    return NULL;
}

DEFINE_ANE_FUNCTION(openApplication) {
    
    uint32_t string_length;
    const uint8_t *utf8_pageId;
    
    NSString* appID;
    
    if (FREGetObjectAsUTF8(argv[0], &string_length, &utf8_pageId) == FRE_OK)
        appID = [NSString stringWithUTF8String:(char*) utf8_pageId];
    else
        return NULL;
    
    BOOL canOpenURL = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:appID]];
    
    if(canOpenURL)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appID]];
    
    return NULL;
}

DEFINE_ANE_FUNCTION(uniqueID) {
    
    NSString *uid = [DeviceUID uid];
    
    NSLog(@"uniqueID %@", uid);
    
    const char *str = [uid UTF8String];
    FREObject retStr;
    FRENewObjectFromUTF8(strlen(str)+1, (const uint8_t*)str, &retStr);
    
    return retStr;
}

DEFINE_ANE_FUNCTION(getAvailableDevices) {
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    uint32_t i = 0;
    FREObject cameras = NULL;
    
    FRENewObject((const uint8_t*)"Vector.<com.freshplanet.ane.AirCapabilities.CaptureDevice>", 0, NULL, &cameras, nil);
    FRESetArrayLength(cameras, (int)devices.count);
    
    for (AVCaptureDevice *device in devices) {
        
        FREObject camera;
        // create an instance of Object and save it to FREObject position
        FRENewObject((const uint8_t*)"com.freshplanet.ane.AirCapabilities.CaptureDevice", 0, NULL, &camera, NULL);
        
        FREObject id;
        FREObject orientation;
        FREObject facing;
        
        FRENewObjectFromInt32(i, &id);
        FRENewObjectFromInt32(90, &orientation);
        
        if ([device position] == AVCaptureDevicePositionBack) {
            FRENewObjectFromInt32(0, &facing);
        } else {
            FRENewObjectFromInt32(1, &facing);
        }
        
        // fill properties of FREObject position
        FRESetObjectProperty(camera, (const uint8_t*)"id", id, NULL);
        FRESetObjectProperty(camera, (const uint8_t*)"orientation", orientation, NULL);
        FRESetObjectProperty(camera, (const uint8_t*)"facing", facing, NULL);
        
        // add position to the array
        FRESetArrayElementAt(cameras, i, camera);
        
        i++;
    }
    
    return cameras;
}

DEFINE_ANE_FUNCTION(setStatusBarHidden) {
    
    uint32_t hide;
    FREGetObjectAsBool(argv[0], &hide);
    
    [[UIApplication sharedApplication] setStatusBarHidden:hide withAnimation:UIStatusBarAnimationFade];
    
    return NULL;
}

DEFINE_ANE_FUNCTION(setStatusBarStyle) {
    
    uint32_t light;
    FREGetObjectAsBool(argv[0], &light);
    
    if(light) {
       [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent; 
    } else {
        [UIApplication sharedApplication].statusBarStyle = UIBarStyleBlack;
    }
    
    return NULL;
}

// AirBgMusicContextInitializer()
//
// The context initializer is called when the runtime creates the extension context instance.
void AirCapabilitiesContextInitializer(void* extData, const uint8_t* ctxType, FREContext ctx, 
                                  uint32_t* numFunctionsToTest, const FRENamedFunction** functionsToSet) 
{    
    // Register the links btwn AS3 and ObjC. (dont forget to modify the nbFuntionsToLink integer if you are adding/removing functions)
    NSInteger nbFuntionsToLink = 25;
    *numFunctionsToTest = (int)nbFuntionsToLink;
    
    FRENamedFunction* func = (FRENamedFunction*) malloc(sizeof(FRENamedFunction) * nbFuntionsToLink);
    func[0].name = (const uint8_t*) "hasSMS";
    func[0].functionData = NULL;
    func[0].function = &hasSMS;
    
    func[1].name = (const uint8_t*) "hasTwitter";
    func[1].functionData = NULL;
    func[1].function = &hasTwitter;

    func[2].name = (const uint8_t*) "sendWithSms";
    func[2].functionData = NULL;
    func[2].function = &sendSms;

    func[3].name = (const uint8_t*) "sendWithTwitter";
    func[3].functionData = NULL;
    func[3].function = &sendWithTwitter;

    func[4].name = (const uint8_t*) "redirectToRating";
    func[4].functionData = NULL;
    func[4].function = &redirectToRating;

    func[5].name = (const uint8_t*) "getDeviceModel";
    func[5].functionData = NULL;
    func[5].function = &getDeviceModel;
	
	func[6].name = (const uint8_t*) "getMachineName";
    func[6].functionData = NULL;
    func[6].function = &getMachineName;

    func[7].name = (const uint8_t*) "processReferralLink";
    func[7].functionData = NULL;
    func[7].function = &processReferralLink;
	
    func[8].name = (const uint8_t*) "redirectToPageId";
    func[8].functionData = NULL;
    func[8].function = &redirectToPageId;
    
    func[9].name = (const uint8_t*) "redirectToTwitterAccount";
    func[9].functionData = NULL;
    func[9].function = &redirectToTwitterAccount;

    func[10].name = (const uint8_t*) "canPostPictureOnTwitter";
    func[10].functionData = NULL;
    func[10].function = &canPostPictureOnTwitter;

    func[11].name = (const uint8_t*) "postPictureOnTwitter";
    func[11].functionData = NULL;
    func[11].function = &postPictureOnTwitter;
    
    func[12].name = (const uint8_t*) "openExternalApplication";
    func[12].functionData = NULL;
    func[12].function = &openExternalApplication;

    func[13].name = (const uint8_t*) "getOSVersion";
    func[13].functionData = NULL;
    func[13].function = &getOSVersion;
    
    func[14].name = (const uint8_t*) "canOpenURL";
    func[14].functionData = NULL;
    func[14].function = &AirCapabilitiesCanOpenURL;
    
    func[15].name = (const uint8_t*) "openURL";
    func[15].functionData = NULL;
    func[15].function = &AirCapabilitiesOpenURL;
    
    func[16].name = (const uint8_t*) "setLogging";
    func[16].functionData = NULL;
    func[16].function = &AirCapabilitiesSetLogging;
    
    func[17].name = (const uint8_t*) "traceLog";
    func[17].functionData = NULL;
    func[17].function = &traceLog;
    
    func[18].name = (const uint8_t*) "openModalAppStore";
    func[18].functionData = NULL;
    func[18].function = &AirCapabilitiesOpenModalAppStore;
    
    func[19].name = (const uint8_t*) "requestAccessForMediaType";
    func[19].functionData = NULL;
    func[19].function = &requestAccessForMediaType;
    
    func[20].name = (const uint8_t*) "openApplicationSetting";
    func[20].functionData = NULL;
    func[20].function = &openApplicationSetting;
    
    func[21].name = (const uint8_t*) "uniqueID";
    func[21].functionData = NULL;
    func[21].function = &uniqueID;
    
    func[22].name = (const uint8_t*) "getAvailableDevices";
    func[22].functionData = NULL;
    func[22].function = &getAvailableDevices;
    
    func[23].name = (const uint8_t*) "setStatusBarHidden";
    func[23].functionData = NULL;
    func[23].function = &setStatusBarHidden;
    
    func[24].name = (const uint8_t*) "setStatusBarStyle";
    func[24].functionData = NULL;
    func[24].function = &setStatusBarStyle;
    
    func[25].name = (const uint8_t*) "openApplication";
    func[25].functionData = NULL;
    func[25].function = &openApplication;
    
    *functionsToSet = func;
    
    myAirCapaCtx = ctx;
}

// AirBgMusicContextFinalizer()
//
// Set when the context extension is created.
void AirCapabilitiesContextFinalizer(FREContext ctx) {}



// AirBgMusicInitializer()
//
// The extension initializer is called the first time the ActionScript side of the extension
// calls ExtensionContext.createExtensionContext() for any context.

void AirCapabilitiesInitializer(void** extDataToSet, FREContextInitializer* ctxInitializerToSet, FREContextFinalizer* ctxFinalizerToSet ) 
{
    
    *extDataToSet = NULL;
    *ctxInitializerToSet = &AirCapabilitiesContextInitializer; 
    *ctxFinalizerToSet = &AirCapabilitiesContextFinalizer;
}

void AirCapabilitiesFinalizer(void *extData) { }
