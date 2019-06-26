#import "CDVCookieEmperor.h"
#import <WebKit/WebKit.h>

// Experimental, not full solution
@implementation CDVCookieEmperor

- (void)getCookieValue:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    
    NSString* urlString = [command.arguments objectAtIndex:0];
    __block NSString* cookieName = [command.arguments objectAtIndex:1];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (urlString != nil)
        {
            __block NSString *cookieValue;
            
            [[[WKWebsiteDataStore defaultDataStore] httpCookieStore] getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull cookies) {
                
                [cookies enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    NSHTTPCookie *cookie = obj;
                    
                    if([cookie.name isEqualToString:cookieName])
                    {
                        cookieValue = cookie.value;
                        *stop = YES;
                    }
                }];
                
                if (cookieValue != nil)
                {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:@{@"cookieValue":cookieValue}];
                }
                else
                {
                    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"No cookie found"];
                }
            }];
        }
        else
        {
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"URL was null"];
        }
        
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    });
}

- (void)setCookieValue:(CDVInvokedUrlCommand*)command
{
    __block CDVPluginResult* pluginResult = nil;
    
    NSString* urlString = [command.arguments objectAtIndex:0];
    NSString* cookieName = [command.arguments objectAtIndex:1];
    NSString* cookieValue = [command.arguments objectAtIndex:2];
    
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    
    [cookieProperties setObject:cookieName forKey:NSHTTPCookieName];
    [cookieProperties setObject:cookieValue forKey:NSHTTPCookieValue];
    [cookieProperties setObject:urlString forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    
    [[[WKWebsiteDataStore defaultDataStore] httpCookieStore] setCookie:cookie completionHandler:^{
        
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Set cookie executed"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }];
}

- (void)clearCookies:(CDVInvokedUrlCommand*)command
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        NSSet *dataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateStart = [NSDate dateWithTimeIntervalSince1970:0];
        
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:dataTypes modifiedSince:dateStart completionHandler:^{
            
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    });
}

@end
