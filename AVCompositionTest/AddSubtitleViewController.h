//
//  AddSubtitleViewController.h
//  AVCompositionTest
//
//  Created by morotomihead on 2016/05/12.
//  Copyright © 2016年 hiruma-kazuya. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
//#import "Composition.h"

@interface AddSubtitleViewController : NSObject

@property (weak, nonatomic) IBOutlet UITextField *subTitle1;

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size;
- (void)videoOutput;

@end