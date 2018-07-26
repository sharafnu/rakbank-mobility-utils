#import <Cordova/CDVPlugin.h>

@interface MobilityUtils : CDVPlugin 


// The hooks for our plugin commands
- (void)echo:(CDVInvokedUrlCommand *)command;
- (void)getDate:(CDVInvokedUrlCommand *)command;
- (void)loadProps:(CDVInvokedUrlCommand *)command;

@end