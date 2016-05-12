
@import UIKit;
@import AVFoundation;
@import MediaPlayer;

#import "Composition.h"

@interface Composition ()
@property (nonatomic, copy) void (^handler)(NSURL *url);
@end


// WIP 自身での書き出しについて、慣れる！

//AVFoundationフレームワークの仕様調査
    //ざっと読み解き完了。（引き続き何度も読み返しておく）
    // その情報を基に、コードをいじり下記をテストします。


    // - サウンドの長さ主体で、動画を切る　＞＞そのために動画をもう一つ用意で、１つを書き出せるか。
    // - ビデオ環境音を合成した動画の書き出し
    //

/*
 AVMutableComposition       : iMovieで言うプロジェクト。このProject内で、各トラックを編集する。
 AVMutableCompositionTrack  : ビデオトラックとオーディオトラックが設定
 AVMutableVideoComposition  : AVMutableCompositionに対する付加情報を設定：フレームの長さやレンダリングサイズ
 AVAssetExportSession       : AVMutableComposition,AVMutableVideoCompositionの情報をAVAssetExportSessionに代入→ビデオのクオリティやアウトプット用のパスなどを設定すればビデオファイルの出来上がり
 
 _____
 
 
 １．AVMutableCompositionで編集したい動画を割当て
 ２．AVMutableVideoCompositionInstructionで動画に対する編集内容を設定
 
 
 
 AVMutableVideoCompositionをAVPlayerやExportのクラスに渡す事でビデオに付加情報がセットされる。
 */

@implementation Composition

const int kVideoFPS = 30;

- (void)create:(void (^)(NSURL *url))handler
{
    
    Float64 duration = 26;
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
    
        /////////////////////////////////////////////////////////////////////////////
        // 手順4
        //※単純に元動画をクロップして繋ぎ合わせたい場合は、AVMutableCompositionTrackにAVAssetTrackをどんどん追加すれば良い。
    
//VideoTrackの並びを編集する
    
    // ひとつめの動画をトラックに追加
    // `videoAssetTrack1`の動画の長さ分を`kCMTimeZero`の位置に挿入
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack1.timeRange.duration)
                                   ofTrack:videoAssetTrack1
                                    atTime:kCMTimeZero
                                     error:nil];
    
    // ふたつめの動画を追加　：ケースとしては最後のタイトル文言の動画を挿入
    // `videoAssetTrack2`の動画の長さ分を`videoAssetTrack1`の終了時間の後ろに挿入
    //    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAssetTrack2.timeRange.duration)
    //                                   ofTrack:videoAssetTrack2
    //                                    atTime:videoAssetTrack1.timeRange.duration
    //                                     error:nil];
    
    
    //長さを調整(TEST・オーディオの尺に合わせ動画をトリム）: audioAssetTrack.timeRange.duration -  videoAssetTrack1.timeRange.duration
    Float64 audioDuration = CMTimeGetSeconds(audioAssetTrackBGM.timeRange.duration);
    Float64 mainVideoDuration = CMTimeGetSeconds(videoAssetTrack1.timeRange.duration);
    Float64 dulation = audioDuration - mainVideoDuration;
    CMTime endingVideoRangeDuration = CMTimeMakeWithSeconds(dulation, kVideoFPS);
    
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, endingVideoRangeDuration)
                                   ofTrack:videoAssetTrack2
                                    atTime:videoAssetTrack1.timeRange.duration
                                     error:nil];
    
//AudioTrackの並びを編集する。
    
//    // ひとつめの音声をトラックに追加
//    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack2.timeRange.duration)
//                                   ofTrack:audioAssetTrack2
//                                    atTime:kCMTimeZero
//                                     error:nil];
//    // ふたつめの音声を追加
//    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrack1.timeRange.duration)
//                                   ofTrack:audioAssetTrack1
//                                    atTime:audioAssetTrack2.timeRange.duration
//                                     error:nil];
    // BGM用音声をトラックに追加
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrackBGM.timeRange.duration)
                                   ofTrack:audioAssetTrackBGM
                                    atTime:kCMTimeZero
                                     error:nil];
    
    // 環境音声をトラックに追加
    [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAssetTrackField.timeRange.duration)
                                   ofTrack:audioAssetTrackField
                                    atTime:kCMTimeZero
                                     error:nil];
    
    
    
//    テスト。ここも同じように、音声データを追加してみたらどうなるか
//    で、後述のパラメータ設定でのパーセンテージで、可能にはならないだろうか。
    
    /*
     TimeRange - 元素材トラックの方のどの範囲(0:30.000〜0:35.000 とか)を使うかを指定する。今回は元素材トラック全体を指定した。
     ofTrack - 元素材トラックを指定
     atTime - 貼付ける先のトラックのどの位置に貼付けるか
     */
    
//__________________________________
//生成前の合成処理（映像）
    /////////////////////////////////////////////////////////////////////////////
    // 手順5
    
     //AVMutableVideoComposition  : AVMutableCompositionに対する付加情報を設定：フレームの長さやレンダリングサイズ
    //WIP::ここで再生秒数の長さとか指定している感じ。
        // - 単純に音をカットしたらどうなるだろうか。最後のサンプルフレームで終了する。
    
    //timeRange >> どこのタイムからどこのタイムまでを再生かを指定。
    //おそらく＞インタラクション、可変の設定用オブジェクトを設定して、その後、compositionVideoTrackに当て込んでいる？
    
    // Video1の合成命令用オブジェクトを生成
    AVMutableVideoCompositionInstruction *mutableVideoCompositionInstruction1 = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        //タイム範囲を指定
        mutableVideoCompositionInstruction1.timeRange = CMTimeRangeMake(kCMTimeZero, videoAssetTrack1.timeRange.duration);
        mutableVideoCompositionInstruction1.backgroundColor = UIColor.redColor.CGColor;
    
    // Video1のレイヤーの合成命令を生成
    AVMutableVideoCompositionLayerInstruction *videoLayerInstruction1;
        videoLayerInstruction1= [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        mutableVideoCompositionInstruction1.layerInstructions = @[videoLayerInstruction1];
    
    
    // Video2の合成命令用オブジェクトを生成
    AVMutableVideoCompositionInstruction *mutableVideoCompositionInstruction2 = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    //
//        mutableVideoCompositionInstruction2.timeRange = CMTimeRangeMake(videoAssetTrack1.timeRange.duration, audioAssetTrack.timeRange.duration); //ここは変わらない。
        mutableVideoCompositionInstruction2.timeRange = CMTimeRangeMake(videoAssetTrack1.timeRange.duration, CMTimeAdd(videoAssetTrack1.timeRange.duration, videoAssetTrack2.timeRange.duration));
        mutableVideoCompositionInstruction2.backgroundColor = UIColor.blueColor.CGColor;
    
    // Video2のレイヤーの合成命令を生成
    AVMutableVideoCompositionLayerInstruction *videoLayerInstruction2;
        videoLayerInstruction2= [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
        mutableVideoCompositionInstruction2.layerInstructions = @[videoLayerInstruction2];
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順6
    
    // AVMutableVideoCompositionを生成
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    mutableVideoComposition.instructions = @[mutableVideoCompositionInstruction1, mutableVideoCompositionInstruction2];
    
//__________________________________
//生成前の合成処理（音声）
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順7
    
    // Audioの合成パラメータオブジェクトを生成
    AVMutableAudioMixInputParameters *audioMixInputParametersBGM;
    audioMixInputParametersBGM = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:compositionAudioTrack];
    //音量可変の設定のみ
    [audioMixInputParametersBGM setVolume:1.0 atTime:kCMTimeZero];
    [audioMixInputParametersBGM setVolumeRampFromStartVolume:1.0
                                              toEndVolume:1.0
                                                timeRange:CMTimeRangeMake(kCMTimeZero, mutableComposition.duration)];
    
    
    
    
    /////////////////////////////////////////////////////////////////////////////
    // 手順8
    
    // AVMutableAudioMixを生成
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    mutableAudioMix.inputParameters = @[audioMixInputParametersBGM];
    
    
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

//MARK:: TEST MIX DATA
    //1. 作成した動画にて、自由にコントロールしてみる。
    //2. 動画に『音楽で」当て込んでみる。
        //その知識を基に、ライブラリの仕様を確認
        //実実装を試す。


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
    NSString *path = [bundle pathForResource:@"FieldMovieBGM" ofType:@"mp4"];
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

@end


