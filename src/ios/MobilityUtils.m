#import "MobilityUtils.h"

#import <Cordova/CDVAvailability.h>

#import <MobileCoreServices/MobileCoreServices.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

static NSString* const kCryptKey = @"";
static NSString* const kCryptIv = @"";

@implementation MobilityUtils

- (void)pluginInitialize {
}

- (void)echo:(CDVInvokedUrlCommand *)command {
  NSString* phrase = [command.arguments objectAtIndex:0];
  NSLog(@"%@", phrase);
}

- (void)getDate:(CDVInvokedUrlCommand *)command {
  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
  [dateFormatter setLocale:enUSPOSIXLocale];
  [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

  NSDate *now = [NSDate date];
  NSString *iso8601String = [dateFormatter stringFromDate:now];

  CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:iso8601String];
  [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}



- (void)loadProps:(CDVInvokedUrlCommand *)command{

    CDVPluginResult* pluginResult = nil;
     NSString *wwwPath = [[NSBundle mainBundle].resourcePath stringByAppendingString:@"/www/assets/props.json"];
    NSURL *url = [NSURL URLWithString: [NSString stringWithFormat: @"%@",wwwPath]];

   // if ([[self class] checkCryptFile:url]) {
        NSString *mimeType = [self getMimeType:url];
        NSError* error;
        NSString* content = [[NSString alloc] initWithContentsOfFile:url.path encoding:NSUTF8StringEncoding error:&error];
        if (!error) {
            NSData* data = [self decryptAES256WithKey:kCryptKey iv:kCryptIv data:content];
            NSString *formattedResult = [NSString stringWithUTF8String:[data bytes]];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:formattedResult];
        }else{
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
            NSLog(@"Errorr in decrypting data :: %@", error);
        }
         [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    //}
}

- (NSData *)decryptAES256WithKey:(NSString *)key iv:(NSString *)iv data:(NSString *)base64String {
     
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ivData = [iv dataUsingEncoding:NSUTF8StringEncoding];
    
    CCCryptorStatus status = CCCrypt(kCCDecrypt,
                                     kCCAlgorithmAES128,
                                     kCCOptionPKCS7Padding,
                                     keyData.bytes,
                                     kCCKeySizeAES256,
                                     ivData.bytes,
                                     data.bytes,
                                     data.length,
                                     buffer,
                                     bufferSize,
                                     &numBytesDecrypted);
    
    if (status == kCCSuccess) {
        return [NSData dataWithBytes:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

- (NSString*)getMimeType:(NSURL *)url
{
    NSString *fullPath = url.path;
    NSString *mimeType = nil;
    if (fullPath) {
        CFStringRef typeId = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[fullPath pathExtension], NULL);
        if (typeId) {
            mimeType = (__bridge_transfer NSString*)UTTypeCopyPreferredTagWithClass(typeId, kUTTagClassMIMEType);
            if (!mimeType) {
                // special case for m4a
                if ([(__bridge NSString*)typeId rangeOfString : @"m4a-audio"].location != NSNotFound) {
                    mimeType = @"audio/mp4";
                } else if ([[fullPath pathExtension] rangeOfString:@"wav"].location != NSNotFound) {
                    mimeType = @"audio/wav";
                } else if ([[fullPath pathExtension] rangeOfString:@"css"].location != NSNotFound) {
                    mimeType = @"text/css";
                }
            }
            CFRelease(typeId);
        }
    }
    return mimeType;
}


@end
