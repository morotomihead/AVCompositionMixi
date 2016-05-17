
@import UIKit;
@import AVFoundation;
@import MediaPlayer;

#import "Composition.h"

@interface Composition ()
@property (nonatomic, copy) void (^handler)(NSURL *url);
@property(nonatomic, strong) AVAsset *videoAsset;

@end


// WIP 自身での書き出しについて、慣れる！

//AVFoundationフレームワークの仕様調査
    //ざっと読み解き完了。（引き続き何度も読み返しておく）
    // その情報を基に、コードをいじり下記をテストします。


    // OK サウンドの長さ主体で、動画を切る
    // OK ビデオ環境音を合成した動画の書き出し　（合わせて音量バランス調整）
    // OK 画像から動画を生成して撮影動画ラストにインサートしてコンバート
    // OK ビデオ上に指定した秒数よりテキストを重ねて動画生成
    // OK

// AV08ViewController:CrossFade

/*
 
 // Text
 // Icon
 
 //動画の最終フレームから画像を取得する >> 手法は見えました。
 //取得した画像にブラーをかける　 >>iOS9Samplerをチェック > 可能だが少々時間かかりそう。
 //加工した画像の上にText, 画像素材を重ねる
 //画像を1秒の動画にする

 
 
 AVMutableComposition       : iMovieで言うプロジェクト。このProject内で、各トラックを編集する。
 AVMutableCompositionTrack  : ビデオトラックとオーディオトラックが設定
 AVMutableVideoComposition  : AVMutableCompositionに対する付加情報を設定：フレームの長さやレンダリングサイズ
 AVAssetExportSession       : AVMutableComposition,AVMutableVideoCompositionの情報をAVAssetExportSessionに代入→ビデオのクオリティやアウトプット用のパスなどを設定すればビデオファイルの出来上がり
 
 _____

 AVMutableVideoCompositionをAVPlayerやExportのクラスに渡す事でビデオに付加情報がセットされる。
 */

@implementation Composition

const int kVideoFPS = 30;

- (void)create:(void (^)(NSURL *url))handler
{
    
    Float64 duration = 26;
    Float64 startTimeOfTitleDisplay = 22;
    CMTime rangeDuration = CMTimeMakeWithSeconds(duration, kVideoFPS);
    
    self.handler = handler;
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順1
    
    // Compositionを生成
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順2
    
    //WIP
    //prepare the in and outfiles
    //AVAudioFile* inFile = [[AVAudioFile alloc] initForReading:self.movieFile1 error:nil];
    //http://stackoverflow.com/questions/35581531/cant-reverse-avasset-audio-properly-the-only-result-is-white-noise
    
//AVAsset: 各ビデオ素材の入れ物、テイクトラックと思って良い。
    
//    // AVAssetをURLから取得
//    AVURLAsset *videoAsset1 = [[AVURLAsset alloc] initWithURL:self.movieFile1 options:nil];
//    AVURLAsset *videoAsset2 = [[AVURLAsset alloc] initWithURL:self.movieFile2 options:nil];
    
    // AVAssetをURLから取得
    AVURLAsset *videoAsset1 = [[AVURLAsset alloc] initWithURL:self.movieFileMain options:nil];  //15.93s(約16s）
    AVURLAsset *videoAsset2 = [[AVURLAsset alloc] initWithURL:self.movieFileLast options:nil];  //movieFileLast
    
    AVURLAsset *videoAsset3 = [[AVURLAsset alloc] initWithURL:self.videoFileFromRecSample options:nil];
    AVURLAsset *videoAsset4 = [[AVURLAsset alloc] initWithURL:self.videoFileFromFieldRec options:nil];
    
    // アセットから動画・音声トラックをそれぞれ取得
    AVAssetTrack *videoAssetTrack1  = [videoAsset1 tracksWithMediaType:AVMediaTypeVideo][0];
    //AVAssetTrack *audioAssetTrack1 = [videoAsset1 tracksWithMediaType:AVMediaTypeAudio][0];   //動画音声を扱う際に使用
    
    AVAssetTrack *videoAssetTrack2  = [videoAsset2 tracksWithMediaType:AVMediaTypeVideo][0];
    //AVAssetTrack *audioAssetTrack2 = [videoAsset2 tracksWithMediaType:AVMediaTypeAudio][0];   //動画音声を使う際はこちらを。
    
    AVAssetTrack *audioAssetTrackBGM    = [videoAsset3 tracksWithMediaType:AVMediaTypeAudio][0];
    AVAssetTrack *audioAssetTrackField  = [videoAsset4 tracksWithMediaType:AVMediaTypeAudio][0];
    /////////////////////////////////////////////////////////////////////////////
    
    // 手順3
    
    // 動画合成用の`AVMutableCompositionTrack`を生成 (mutableComposition にaddもしている）
    AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
    // 音声合成用の`AVMutableCompositionTrack`を生成
    AVMutableCompositionTrack *compositionAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
    // 環境音合成用の`AVMutableCompositionTrack`を生成
    AVMutableCompositionTrack *compositionFieldTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
    /////////////////////////////////////////////////////////////////////////////
    // 手順4
    
//VideoTrackの並びを編集する
    // ひとつめの動画をトラックに追加
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack1.timeRange.duration)
                                   ofTrack:videoAssetTrack1
                                    atTime:kCMTimeZero
                                     error:nil];
    
    // ふたつめの動画をトラックに追加
        //長さを調整(TEST・オーディオの尺に合わせ動画をトリム）ケースとしては最後のタイトル文言の動画を挿入
        Float64 audioDuration = CMTimeGetSeconds(audioAssetTrackBGM.timeRange.duration);
        Float64 mainVideoDuration = CMTimeGetSeconds(videoAssetTrack1.timeRange.duration);
        Float64 dulation = audioDuration - mainVideoDuration;
        CMTime endingVideoRangeDuration = CMTimeMakeWithSeconds(dulation, kVideoFPS);
    
    //`videoAssetTrack2`の動画の長さ分を`videoAssetTrack1`の終了時間の後ろに"BGMが終わる残り尺の分"挿入
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, endingVideoRangeDuration)
                                   ofTrack:videoAssetTrack2
                                    atTime:videoAssetTrack1.timeRange.duration
                                     error:nil];
    
    //※↑単純に元動画をクロップして繋ぎ合わせたい場合は、AVMutableCompositionTrackにAVAssetTrackをどんどん追加すれば良い。
    
//AudioTrackの並びを編集する
    // BGM用音声をトラックに追加
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrackBGM.timeRange.duration)
                                   ofTrack:audioAssetTrackBGM
                                    atTime:kCMTimeZero
                                     error:nil];
    
    // 環境音声をトラックに追加
    [compositionFieldTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrackField.timeRange.duration)
                                   ofTrack:audioAssetTrackField
                                    atTime:kCMTimeZero
                                     error:nil];

    
    /*
     TimeRange - 元素材トラックの方のどの範囲(0:30.000〜0:35.000 とか)を使うかを指定する。今回は元素材トラック全体を指定した。
     ofTrack - 元素材トラックを指定
     atTime - 貼付ける先のトラックのどの位置に貼付けるか
     */
    
    
//__________________________________
//生成前の合成処理（映像）
    /////////////////////////////////////////////////////////////////////////////
    // 手順5
    //トラック素材を何処に配置して、どういう変化パラメータ情報を設定して、何処に置くか、をここで指定している。
     //AVMutableVideoComposition, AVMutableAudioComposition  : AVMutableCompositionに対する付加情報を設定：フレームの長さやレンダリングサイズ
    
    // Video1の合成命令用オブジェクトを生成
    AVMutableVideoCompositionInstruction *mutableVideoCompositionInstruction1 = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        //タイム範囲を指定し、背景の指定
        mutableVideoCompositionInstruction1.timeRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack1.timeRange.duration);
        mutableVideoCompositionInstruction1.backgroundColor = UIColor.redColor.CGColor;
    // Video1のレイヤーの合成命令を生成
    AVMutableVideoCompositionLayerInstruction *videoLayerInstruction1;
        videoLayerInstruction1= [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        mutableVideoCompositionInstruction1.layerInstructions = @[videoLayerInstruction1];
    
    
    // Video2の合成命令用オブジェクトを生成
    AVMutableVideoCompositionInstruction *mutableVideoCompositionInstruction2 = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mutableVideoCompositionInstruction2.timeRange = CMTimeRangeMake(videoAssetTrack1.timeRange.duration,
                                                                        CMTimeAdd(videoAssetTrack1.timeRange.duration, videoAssetTrack2.timeRange.duration));
        mutableVideoCompositionInstruction2.backgroundColor = UIColor.blueColor.CGColor;
    // Video2のレイヤーの合成命令を生成
    AVMutableVideoCompositionLayerInstruction *videoLayerInstruction2;
        videoLayerInstruction2= [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        mutableVideoCompositionInstruction2.layerInstructions = @[videoLayerInstruction2];
    
    // --------------------------------------------- //
    
    //最終フレームへの画像合成用オブジェクトを生成
    //          3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        mainInstruction.timeRange = CMTimeRangeMake(videoAssetTrack1.timeRange.duration,
                                                    CMTimeAdd(videoAssetTrack1.timeRange.duration, videoAssetTrack2.timeRange.duration));
    //最終フレームへのレイヤーの合成命令を生成
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction;
        videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    
    //          3.3 - Add instructions
    mainInstruction.layerInstructions =  @[videolayerInstruction];  //[NSArray arrayWithObjects:videolayerInstruction,nil];
    
    CGSize naturalSize;
    naturalSize = videoAssetTrack2.naturalSize;
    
    /////////////////////////////////////////////////////////////////////////////
    
    // 手順6
    // AVMutableVideoCompositionを生成
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.instructions = @[mutableVideoCompositionInstruction1, mutableVideoCompositionInstruction2];
    
/////////////////////////////////////////////////////////////////////////////
    // エンディング・レイヤーの生成
/////////////////////////////////////////////////////////////////////////////
    
    // 1-1 - Set up the text layer
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFont:@"Helvetica-Bold"];
    [subtitle1Text setFontSize:60];
    [subtitle1Text setFrame:CGRectMake(0, 0, naturalSize.width, naturalSize.height/2+20)];
    [subtitle1Text setString:@"チャリで来た。"];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    //Set title text begin time (WIP::より正確なタイム設定)
    [subtitle1Text setBeginTime:startTimeOfTitleDisplay];
    
// 動画キャプションのよる画像ファイル生成
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:videoAsset2];
    imageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    imageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    Float64 assetDuration = dulation;   //Float64 assetDuration = CMTimeGetSeconds([videoAsset2 duration]);
    //    Float64 dulation = audioDuration - mainVideoDuration;
    //    CMTime endingVideoRangeDuration = CMTimeMakeWithSeconds(dulation, kVideoFPS);
    
    NSError *error;
    CMTime actualTime;
    NSMutableArray *images = [NSMutableArray array];
    CMTime point = CMTimeMakeWithSeconds(assetDuration, NSEC_PER_SEC);
    CGImageRef image = [imageGenerator copyCGImageAtTime:point actualTime:&actualTime error:&error];
    if(!error) {
        [images addObject:[UIImage imageWithCGImage:image]];
        CGImageRelease(image);
    }
    
    //ex : 動画画像生成
    //http://appstars.jp/archive/650
    
// Blur Effect処理 ------------------
    UIImage *originalImage = images[0]; //WIP: UIImageにせずに処理可能にする
    CIImage *imageToBlur = [CIImage imageWithCGImage:originalImage.CGImage];
    CIFilter *gaussianBlurFilter = [CIFilter filterWithName: @"CIGaussianBlur"];
    [gaussianBlurFilter setValue:imageToBlur forKey: @"inputImage"];
    [gaussianBlurFilter setValue:[NSNumber numberWithFloat: 10] forKey: @"inputRadius"]; //change number to increase/decrease blur
    CIImage *outputImage = [gaussianBlurFilter outputImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[imageToBlur extent]];
    // note, use input image extent if you want it the same size, the output image extent is larger
    
    UIImage *convertedImage = [UIImage imageWithCGImage:cgimg];
    
    //WIP:: 後にメソッド化
    
    //ex : convertToBlurImage
    //http://findnerd.com/list/view/Blur-image-using-objective-c-and-swift/4213/
    
    
// GPS情報 ------------------
    CATextLayer *gpsInfoText = [[CATextLayer alloc] init];
    [gpsInfoText setFont:@"Helvetica-Bold"];
    [gpsInfoText setFontSize:50];
    [gpsInfoText setFrame:CGRectMake(0, 0, naturalSize.width, naturalSize.height/2 + 100)];
    [gpsInfoText setString:@"東京ソラマチ (スカイツリータウン)"];  //東京都墨田区押上一丁目1番2号 \n東京都墨田区押上一丁目1番2号
    [gpsInfoText setAlignmentMode:kCAAlignmentCenter];
    [gpsInfoText setForegroundColor:[[UIColor whiteColor] CGColor]];
    
    CATextLayer *addressInfoText = [[CATextLayer alloc] init];
    [addressInfoText setFontSize:30];
    [addressInfoText setFrame:CGRectMake(0, 0, naturalSize.width, naturalSize.height/2)];
    [addressInfoText setString:@"東京都墨田区押上一丁目1番2号"];  //東京都墨田区押上一丁目1番2号 \n東京都墨田区押上一丁目1番2号
    [addressInfoText setAlignmentMode:kCAAlignmentCenter];
    [addressInfoText setForegroundColor:[[UIColor whiteColor] CGColor]];
    
// LOGO Picture ------------
    
    CALayer *logoLayer = [CALayer layer];
    UIImage *logoImage = [UIImage imageNamed:@"ORSO-Logo.png"];
    [logoLayer setContents:(id)[logoImage CGImage]];
    //logoLayer.frame = CGRectMake(0, 0, 216, 84);    //DiscoveryCamera Logo
    logoLayer.frame = CGRectMake(0, 0, 120, 120);    //ORSO Logo
    [logoLayer setPosition:CGPointMake(naturalSize.width/2, naturalSize.height/4)];
    
    
// エンディング画像レイヤー設定
    
    //Add BackGround Blur Picture
    CALayer *endingLayer = [CALayer layer];
    [endingLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
    [endingLayer setContents:(id)[convertedImage CGImage]];
    
    //Add GPS Info
    [endingLayer addSublayer:gpsInfoText];
    [endingLayer addSublayer:addressInfoText];
    
    //Add LOGO Image
    [endingLayer addSublayer:logoLayer];
    
    endingLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    [endingLayer setMasksToBounds:YES];
    [endingLayer setBeginTime:startTimeOfTitleDisplay+2];
    
    //FadeIn Animation (Testing)
    // WIP::
//    CABasicAnimation *fadeInAndOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    fadeInAndOut.duration = 0.5;
//    fadeInAndOut.autoreverses = YES;
//    fadeInAndOut.fromValue = [NSNumber numberWithFloat:0.0];
//    fadeInAndOut.toValue = [NSNumber numberWithFloat:1.0];
//    fadeInAndOut.repeatCount = HUGE_VALF;
//    fadeInAndOut.fillMode = kCAFillModeBoth;
//    [endingLayer addAnimation:fadeInAndOut forKey:@"myanimation"];
    
    
    
    
    
    
//　設定用のCALayerを１つにまとめる ------------------
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    [overlayLayer addSublayer:endingLayer];
    
    overlayLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    [overlayLayer setMasksToBounds:YES];
    
    //WIP:: アニメーション詳細設定
    //ex http://qiita.com/inamiy/items/bdc0eb403852178c4ea7
    
    
// mutableVideoCompositionのアニメーションに作成したCALayer処理を設定 ------------------
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    videoLayer.frame = CGRectMake(0, 0, naturalSize.width, naturalSize.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    
    mutableVideoComposition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    

    
    


    
//__________________________________
//生成前の合成処理（音声）
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順7
    
    // Audioの合成パラメータオブジェクトを生成
    AVMutableAudioMixInputParameters *audioMixInputParametersBGM;
    audioMixInputParametersBGM = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack];
    [audioMixInputParametersBGM setVolumeRampFromStartVolume:0.5
                                              toEndVolume:0.5
                                                timeRange:CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)];
    // Fieldの合成パラメータオブジェクトを生成
    AVMutableAudioMixInputParameters *audioMixInputParametersField;
    audioMixInputParametersField = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionFieldTrack];
    [audioMixInputParametersField setVolumeRampFromStartVolume:0.5
                                                 toEndVolume:0.5
                                                   timeRange:CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)];
    /////////////////////////////////////////////////////////////////////////////
    // 手順8
    // AVMutableAudioMixを生成
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = @[audioMixInputParametersBGM, audioMixInputParametersField];
    
    
//__________________________________
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順9
    
    // 動画の回転情報を取得する
    CGAffineTransform transform1 = videoAssetTrack1.preferredTransform;
    BOOL isVideoAssetPortrait = ( transform1.a == 0 &&
                                  transform1.d == 0 &&
                                 (transform1.b == 1.0 || transform1.b == -1.0) &&
                                 (transform1.c == 1.0 || transform1.c == -1.0));
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順10
    
    CGSize naturalSize1 = CGSizeZero;
    CGSize naturalSize2 = CGSizeZero;
    if (isVideoAssetPortrait) {
        naturalSize1 = CGSizeMake(videoAssetTrack1.naturalSize.height, videoAssetTrack1.naturalSize.width);
        naturalSize2 = CGSizeMake(videoAssetTrack2.naturalSize.height, videoAssetTrack2.naturalSize.width);
    }
    else {
        naturalSize1 = videoAssetTrack1.naturalSize;
        naturalSize2 = videoAssetTrack2.naturalSize;
    }
    
    CGFloat renderWidth  = MAX(naturalSize1.width, naturalSize2.width);
    CGFloat renderHeight = MAX(naturalSize1.height, naturalSize2.height);
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順11
    
    // 書き出す動画のサイズ設定
    mutableVideoComposition.renderSize = CGSizeMake(renderWidth, renderHeight);
    
    // 書き出す動画のフレームレート（30FPS）
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順12
    
    // AVMutableCompositionを元にExporterの生成
    AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mutableComposition
                                                                                presetName:AVAssetExportPreset1280x720];
    // 動画合成用のオブジェクトを指定
    assetExportSession.videoComposition = mutableVideoComposition;
    assetExportSession.audioMix         = mutableAudioMix;  //ここでオーディオの指定を行っている。
    
    // エクスポートファイルの設定
    NSString *composedMovieDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *composedMoviePath      = [NSString stringWithFormat:@"%@/%@", composedMovieDirectory, @"test.mp4"];
    
    // すでに合成動画が存在していたら消す
    NSFileManager *fileManager = NSFileManager.defaultManager;
    if ([fileManager fileExistsAtPath:composedMoviePath]) {
        [fileManager removeItemAtPath:composedMoviePath error:nil];
    }
    
    // 保存設定
    NSURL *composedMovieUrl = [NSURL fileURLWithPath:composedMoviePath];
    assetExportSession.outputFileType              = AVFileTypeQuickTimeMovie;
    assetExportSession.outputURL                   = composedMovieUrl;
    assetExportSession.shouldOptimizeForNetworkUse = YES;
    
    // 動画をExport
    [assetExportSession exportAsynchronouslyWithCompletionHandler:^{
        switch (assetExportSession.status) {
            case AVAssetExportSessionStatusFailed: {
                NSLog(@"生成失敗");
                NSLog(@"Export failed: %@", [[assetExportSession error]localizedDescription]);
                break;
                
//                // 端末に保存
//                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
//                if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:exportUrl])
//                {
//                    [library writeVideoAtPathToSavedPhotosAlbum:exportUrl
//                                                completionBlock:^(NSURL *assetURL, NSError *assetError)
//                     {
//                         if (assetError) { }
//                     }];
//                }
//                http://qiita.com/KUMAN/items/a2a1e903b26b062d2d79
                
                
                
                
                
            }
            case AVAssetExportSessionStatusCancelled: {
                NSLog(@"生成キャンセル");
                break;
            }
            default: {
                NSLog(@"生成完了");
                if (self.handler) {
                    self.handler(composedMovieUrl);
                }
                break;
            }
        }
    }];
}

- (NSURL *)movieFileMain
{
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *path = [bundle pathForResource:@"CamelliaTestMovie01" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    return url;
}

- (NSURL *)movieFileLast
{
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *path = [bundle pathForResource:@"CamelliaTestMovie02" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    return url;
}


- (NSURL *)videoFileFromRecSample
{
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *path = [bundle pathForResource:@"Sample_movie-sound" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    return url;
}

- (NSURL *)videoFileFromFieldRec
{
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *path = [bundle pathForResource:@"FieldSound26s" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    return url;
}


/**
 *  合成するひとつめの動画ファイル
 */
- (NSURL *)movieFile1
{
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *path   = [bundle pathForResource:@"URLHookmark" ofType:@"mp4"];
    NSURL *url       = [NSURL fileURLWithPath:path];
    return url;
}


/**
 *  合成するふたつめの動画ファイル
 */
- (NSURL *)movieFile2
{
    NSBundle *bundle = NSBundle.mainBundle;
    NSString *path   = [bundle pathForResource:@"FurShader" ofType:@"mp4"];
    NSURL *url       = [NSURL fileURLWithPath:path];
    return url;
}

//****************************************************************************

//secに秒数を指定すれば、可能。
- (UIImage *)getThumbImage:(NSURL *)url time:(double)sec	//	指定時間（秒）のサムネイル画像を得る
{
    UIImage					*image;
    AVURLAsset				*asset;
    AVAssetImageGenerator	*igtr;
    CMTime					t1,t2;
    CGImageRef				iref;
    
    asset = [AVURLAsset URLAssetWithURL:url options:nil];
    if(asset)
    {
        igtr=[AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
        if(igtr)
        {
            igtr.appliesPreferredTrackTransform=YES;		//	画像の回転を許すか？
            igtr.requestedTimeToleranceBefore=kCMTimeZero;	//	サムネイルの正確さ（前方）
            igtr.requestedTimeToleranceAfter=kCMTimeZero;	//	サムネイルの正確さ（後方）
            t1=CMTimeMakeWithSeconds( sec,NSEC_PER_SEC );
            iref=[igtr copyCGImageAtTime:t1 actualTime:&t2 error:nil];
            
            if(iref)
            {
                image = [UIImage imageWithCGImage:iref];
                CGImageRelease( iref );
                //timeValue.text=[NSString stringWithFormat:@"Request=%.1f\t\tActual=%.3f",sec,CMTimeGetSeconds( t2 )];
            }
        }
    }
    return image;
}







@end


