
@import MediaPlayer;
#import "ViewController.h"
#import "Composition.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    Composition *comp = [[Composition alloc] init];
    [comp create:^(NSURL *url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, NULL, NULL);
            MPMoviePlayerViewController *vc = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            [self presentMoviePlayerViewControllerAnimated:vc];
        });
    }];
}

@end
