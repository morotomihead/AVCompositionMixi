//
//  AddSubtitleViewController.m
//  AVCompositionTest
//
//  Created by morotomihead on 2016/05/12.
//  Copyright © 2016年 hiruma-kazuya. All rights reserved.
//

#import "AddSubtitleViewController.h"

@interface AddSubtitleViewController ()
// - (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size;
@end

@implementation AddSubtitleViewController

//- (IBAction)loadAsset:(id)sender {
//    [self startMediaBrowserFromViewController:self usingDelegate:self];
//}
//
//- (IBAction)generateOutput:(id)sender {
//    [self videoOutput];
//}
//
//-(BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    [textField resignFirstResponder];
//    return YES;
//}
- (void)videoOutput{
    
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition size:(CGSize)size
{
    // 1 - Set up the text layer
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFont:@"Helvetica-Bold"];
    [subtitle1Text setFontSize:45];
    [subtitle1Text setFrame:CGRectMake(0, 0, size.width, size.height/2)];
    [subtitle1Text setString:@"本日は晴天なり"];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}


@end
