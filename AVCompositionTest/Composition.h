
#import <Foundation/Foundation.h>

#import "AddSubtitleViewController.h"
#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>



@interface Composition : NSObject

- (void)create:(void (^)(NSURL *url))handler;

@end
