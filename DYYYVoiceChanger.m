#import "DYYYVoiceChanger.h"

static BOOL _isAudioAssistantActive = NO;

@implementation DYYYVoiceChanger

+ (void)setAudioAssistantActive:(BOOL)active {
    _isAudioAssistantActive = active;
    NSLog(@"[DYYYVoiceChanger] 🎛️ 音频助手状态: %@", active ? @"极速提纯模式" : @"拦截模式");
}

+ (BOOL)isAudioAssistantActive {
    return _isAudioAssistantActive;
}

+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSInteger voiceType = [[NSUserDefaults standardUserDefaults] integerForKey:@"DYYYVoiceChangerType"];
    
    // 音频助手发来的，强制进入 0 号极速提纯通道
    if ([self isAudioAssistantActive]) {
        voiceType = 0; 
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (voiceType == 0) {
        // 🌊 第一层：严格解码 (带自动重采样机制)
        if ([self hardTranscodeAudioFrom:srcPath to:dstPath]) {
            return YES;
        }
        
        // 🌊 第二层：智能嗅探引擎
        NSLog(@"[DYYYVoiceChanger] ⚠️ 严格解码失败，启动智能嗅探引擎提纯...");
        if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
        if ([self engineTranscodeAudioFrom:srcPath to:dstPath]) {
            return YES;
        }
        
        // 🌊 第三层：原生兜底
        NSLog(@"[DYYYVoiceChanger] ⚠️ 嗅探引擎也失败，启动原生兜底...");
        if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
        __block BOOL exportSuccess = NO;
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        [self fallbackExportAudio:[NSURL fileURLWithPath:srcPath] to:dstPath completion:^(BOOL success) {
            exportSuccess = success;
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
        return exportSuccess;
    }
    
    // 🎛️ 变声特效通道...
    __block BOOL processSuccess = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self processAudioAtPath:srcPath withVoiceType:voiceType completion:^(NSString *outputPath, NSError *error) {
        if (outputPath) {
            if ([fm fileExistsAtPath:dstPath]) [fm removeItemAtPath:dstPath error:nil];
            processSuccess = [fm moveItemAtPath:outputPath toPath:dstPath error:nil];
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
    return processSuccess;
}

// ==========================================
// 🛡️ 第一层：严格提纯机 (修复了变声和变速 BUG！)
// ==========================================
+ (BOOL)hardTranscodeAudioFrom:(NSString *)srcPath to:(NSString *)dstPath {
    NSURL *srcURL = [NSURL fileURLWithPath:srcPath];
    NSURL *dstURL = [NSURL fileURLWithPath:dstPath];
    
    AVAsset *asset = [AVAsset assetWithURL:srcURL];
    NSError *error = nil;
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:&error];
    if (!reader) return NO;
    
    CMTime duration = asset.duration;
    if (CMTimeGetSeconds(duration) > 29.5) {
        reader.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(29.5, 600));
    }
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    if (!audioTrack) return NO;

    // 读取源声道数，最多保留立体声
    NSUInteger outputChannels = 1;
    CMFormatDescriptionRef fmtDesc = (__bridge CMFormatDescriptionRef)[audioTrack.formatDescriptions firstObject];
    if (fmtDesc) {
        const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmtDesc);
        if (asbd) outputChannels = MIN(asbd->mChannelsPerFrame, 2);
    }

    // 🚨 核心修复 1：强制读取器自动完成 48000Hz 重采样，防止音频拉伸
    // 32-bit float 中间层，给 AAC 编码器提供最高精度原料
    NSDictionary *readerSettings = @{
        AVFormatIDKey: @(kAudioFormatLinearPCM),
        AVSampleRateKey: @(48000.0),
        AVNumberOfChannelsKey: @(outputChannels),
        AVLinearPCMBitDepthKey: @(32),
        AVLinearPCMIsNonInterleaved: @(NO),
        AVLinearPCMIsFloatKey: @(YES),
        AVLinearPCMIsBigEndianKey: @(NO)
    };
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:readerSettings];
    if (![reader canAddOutput:readerOutput]) return NO;
    [reader addOutput:readerOutput];

    AVAssetWriter *writer = [AVAssetWriter assetWriterWithURL:dstURL fileType:AVFileTypeAppleM4A error:&error];
    if (!writer) return NO;

    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = (outputChannels == 2) ? kAudioChannelLayoutTag_Stereo : kAudioChannelLayoutTag_Mono;
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];

    // 立体声用 320kbps，单声道用 256kbps
    NSInteger outputBitRate = (outputChannels == 2) ? 320000 : 256000;

    // 🚨 核心修复 2：写入器和读取器参数必须完美一致！
    NSDictionary *writerSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(48000.0),
        AVNumberOfChannelsKey: @(outputChannels),
        AVEncoderBitRateKey: @(outputBitRate),
        AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable,
        AVEncoderAudioQualityKey: @(AVAudioQualityMax),
        AVChannelLayoutKey: channelLayoutData
    };
    
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:writerSettings];
    writerInput.expectsMediaDataInRealTime = NO;
    if (![writer canAddInput:writerInput]) return NO;
    [writer addInput:writerInput];
    
    if (![reader startReading]) return NO;
    if (![writer startWriting]) return NO;
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    __block BOOL success = NO;

    [writer startSessionAtSourceTime:kCMTimeZero];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        while (reader.status == AVAssetReaderStatusReading) {
            if (writerInput.isReadyForMoreMediaData) {
                CMSampleBufferRef buffer = [readerOutput copyNextSampleBuffer];
                if (buffer) {
                    if (![writerInput appendSampleBuffer:buffer]) {
                        CFRelease(buffer);
                        break;
                    }
                    CFRelease(buffer);
                }
            }
            [NSThread sleepForTimeInterval:0.005];
        }

        [writerInput markAsFinished];

        if (reader.status == AVAssetReaderStatusCompleted) {
            [writer finishWritingWithCompletionHandler:^{
                success = (writer.status == AVAssetWriterStatusCompleted);
                dispatch_semaphore_signal(sema);
            }];
        } else {
            [writer cancelWriting];
            dispatch_semaphore_signal(sema);
        }
    });
    
    dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)));
    return success;
}

// ==========================================
// 🛡️ 第二层：智能嗅探提纯机 (同样焊死 48000Hz)
// ==========================================
+ (BOOL)engineTranscodeAudioFrom:(NSString *)inputPath to:(NSString *)outputPath {
    NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
    NSError *error = nil;
    
    AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
    if (!sourceFile) return NO;
    
    AVAudioEngine *engine = [[AVAudioEngine alloc] init];
    AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
    [engine attachNode:playerNode];
    [engine connect:playerNode to:engine.mainMixerNode format:sourceFile.processingFormat];

    // 读取源声道数，最多保留立体声
    AVAudioChannelCount outputChannels = MIN(sourceFile.processingFormat.channelCount, 2);
    AVAudioFormat *outputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000.0 channels:outputChannels];
    [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:outputFormat maximumFrameCount:4096 error:&error];
    if (error) return NO;

    [engine startAndReturnError:&error];
    if (error) return NO;

    [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
    [playerNode play];

    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = (outputChannels == 2) ? kAudioChannelLayoutTag_Stereo : kAudioChannelLayoutTag_Mono;
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)];
    NSInteger outputBitRate = (outputChannels == 2) ? 320000 : 256000;

    NSDictionary *outputSettings = @{
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVSampleRateKey: @(48000.0),
        AVNumberOfChannelsKey: @(outputChannels),
        AVEncoderBitRateKey: @(outputBitRate),
        AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable,
        AVEncoderAudioQualityKey: @(AVAudioQualityMax),
        AVChannelLayoutKey: channelLayoutData
    };

    AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:outputPath] settings:outputSettings commonFormat:outputFormat.commonFormat interleaved:outputFormat.isInterleaved error:&error];
    if (!outputFile) return NO;

    AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:outputFormat frameCapacity:engine.manualRenderingMaximumFrameCount];

    AVAudioFramePosition maxLength = (AVAudioFramePosition)(29.5 * outputFormat.sampleRate);
    AVAudioFramePosition targetLength = MIN((AVAudioFramePosition)(sourceFile.length * (48000.0 / sourceFile.processingFormat.sampleRate)), maxLength);
    
    BOOL success = YES;
    while (engine.manualRenderingSampleTime < targetLength) {
        AVAudioFrameCount framesToRender = (AVAudioFrameCount)MIN(buffer.frameCapacity, targetLength - engine.manualRenderingSampleTime);
        AVAudioEngineManualRenderingStatus status = [engine renderOffline:framesToRender toBuffer:buffer error:&error];
        
        if (status == AVAudioEngineManualRenderingStatusSuccess) {
            [outputFile writeFromBuffer:buffer error:&error];
            if (error) { success = NO; break; }
        } else if (status == AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode) {
            break; 
        } else {
            success = NO; break;
        }
    }
    
    [playerNode stop];
    [engine stop];
    return success;
}

// 🛡️ 第三层：高质量兜底（AVAudioEngine 强制解码 + 完整质量参数）
+ (void)fallbackExportAudio:(NSURL *)sourceURL to:(NSString *)dstPath completion:(void(^)(BOOL))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error = nil;
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (!sourceFile) {
            // 最终保底：系统导出器
            AVAsset *asset = [AVAsset assetWithURL:sourceURL];
            AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetAppleM4A];
            session.outputURL = [NSURL fileURLWithPath:dstPath];
            session.outputFileType = AVFileTypeAppleM4A;
            if (CMTimeGetSeconds(asset.duration) > 29.5)
                session.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, CMTimeMakeWithSeconds(29.5, 600));
            [session exportAsynchronouslyWithCompletionHandler:^{
                if (completion) completion(session.status == AVAssetExportSessionStatusCompleted);
            }];
            return;
        }

        AVAudioChannelCount outChannels = MIN(sourceFile.processingFormat.channelCount, 2);
        AVAudioFormat *outFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000.0 channels:outChannels];

        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *player = [[AVAudioPlayerNode alloc] init];
        [engine attachNode:player];
        [engine connect:player to:engine.mainMixerNode format:sourceFile.processingFormat];
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:outFormat maximumFrameCount:8192 error:&error];
        if (error) { if (completion) dispatch_async(dispatch_get_main_queue(), ^{ completion(NO); }); return; }
        [engine startAndReturnError:&error];
        if (error) { if (completion) dispatch_async(dispatch_get_main_queue(), ^{ completion(NO); }); return; }

        [player scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [player play];

        AudioChannelLayout chLayout; memset(&chLayout, 0, sizeof(AudioChannelLayout));
        chLayout.mChannelLayoutTag = (outChannels == 2) ? kAudioChannelLayoutTag_Stereo : kAudioChannelLayoutTag_Mono;
        NSData *chLayoutData = [NSData dataWithBytes:&chLayout length:sizeof(AudioChannelLayout)];
        NSInteger bitRate = (outChannels == 2) ? 320000 : 256000;

        NSDictionary *outSettings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @(48000.0),
            AVNumberOfChannelsKey: @(outChannels),
            AVEncoderBitRateKey: @(bitRate),
            AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable,
            AVEncoderAudioQualityKey: @(AVAudioQualityMax),
            AVChannelLayoutKey: chLayoutData
        };
        AVAudioFile *outFile = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:dstPath] settings:outSettings commonFormat:outFormat.commonFormat interleaved:outFormat.isInterleaved error:&error];
        if (!outFile) { [engine stop]; if (completion) dispatch_async(dispatch_get_main_queue(), ^{ completion(NO); }); return; }

        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:outFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        AVAudioFramePosition maxFrames = (AVAudioFramePosition)(29.5 * outFormat.sampleRate);
        AVAudioFramePosition targetFrames = MIN((AVAudioFramePosition)(sourceFile.length * (48000.0 / sourceFile.processingFormat.sampleRate)), maxFrames);

        BOOL success = YES;
        while (engine.manualRenderingSampleTime < targetFrames) {
            AVAudioFrameCount toRender = (AVAudioFrameCount)MIN(buffer.frameCapacity, targetFrames - engine.manualRenderingSampleTime);
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:toRender toBuffer:buffer error:&error];
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                [outFile writeFromBuffer:buffer error:&error];
                if (error) { success = NO; break; }
            } else if (status == AVAudioEngineManualRenderingStatusInsufficientDataFromInputNode) {
                break;
            } else { success = NO; break; }
        }
        [player stop]; [engine stop];
        if (completion) dispatch_async(dispatch_get_main_queue(), ^{ completion(success); });
    });
}

// --- 变声特效渲染器 (暂不修改) ---
+ (void)processAudioAtPath:(NSString *)inputPath withVoiceType:(NSInteger)voiceType completion:(void(^)(NSString *outputPath, NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSURL *sourceURL = [NSURL fileURLWithPath:inputPath];
        NSError *error = nil;
        AVAudioFile *sourceFile = [[AVAudioFile alloc] initForReading:sourceURL error:&error];
        if (error || !sourceFile) { if(completion) completion(nil, error); return; }
        
        AVAudioEngine *engine = [[AVAudioEngine alloc] init];
        AVAudioPlayerNode *playerNode = [[AVAudioPlayerNode alloc] init];
        [engine attachNode:playerNode];
        
        NSMutableArray<AVAudioNode *> *audioNodes = [NSMutableArray array];
        if (voiceType == 1) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = 1000.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; } 
        else if (voiceType == 2) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -800.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; } 
        else if (voiceType == 3) { AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetLargeHall]; reverb.wetDryMix = 50.0; [engine attachNode:reverb]; [audioNodes addObject:reverb]; } 
        else if (voiceType == 4) { AVAudioUnitDistortion *distortion = [[AVAudioUnitDistortion alloc] init]; [distortion loadFactoryPreset:AVAudioUnitDistortionPresetSpeechRadioTower]; distortion.wetDryMix = 70.0; [engine attachNode:distortion]; [audioNodes addObject:distortion]; } 
        else if (voiceType == 5) { AVAudioUnitTimePitch *pitch = [[AVAudioUnitTimePitch alloc] init]; pitch.pitch = -1200.0; [engine attachNode:pitch]; [audioNodes addObject:pitch]; AVAudioUnitReverb *reverb = [[AVAudioUnitReverb alloc] init]; [reverb loadFactoryPreset:AVAudioUnitReverbPresetMediumChamber]; reverb.wetDryMix = 40.0; [engine attachNode:reverb]; [audioNodes addObject:reverb]; }
        
        AVAudioFormat *sourceFormat = sourceFile.processingFormat;
        AVAudioNode *previousNode = playerNode;
        for (AVAudioNode *node in audioNodes) { [engine connect:previousNode to:node format:sourceFormat]; previousNode = node; }
        [engine connect:previousNode to:engine.mainMixerNode format:sourceFormat];
        
        // 特效模式：保留立体声，焊死 48000Hz
        AVAudioChannelCount outChannels = MIN(sourceFile.processingFormat.channelCount, 2);
        AVAudioFormat *monoBufferFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000.0 channels:outChannels];
        [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline format:monoBufferFormat maximumFrameCount:4096 error:&error];
        if (error) { if(completion) completion(nil, error); return; }

        [engine startAndReturnError:&error];
        if (error) { if(completion) completion(nil, error); return; }

        [playerNode scheduleFile:sourceFile atTime:nil completionHandler:nil];
        [playerNode play];

        NSString *outFileName = [NSString stringWithFormat:@"dyyy_fx_%@.m4a", [[NSUUID UUID] UUIDString]];
        NSString *outputPath = [NSTemporaryDirectory() stringByAppendingPathComponent:outFileName];

        NSInteger fxBitRate = (outChannels == 2) ? 320000 : 256000;
        NSDictionary *outputSettings = @{ AVFormatIDKey: @(kAudioFormatMPEG4AAC), AVSampleRateKey: @(48000.0), AVNumberOfChannelsKey: @(outChannels), AVEncoderBitRateKey: @(fxBitRate), AVEncoderBitRateStrategyKey: AVAudioBitRateStrategy_Variable, AVEncoderAudioQualityKey: @(AVAudioQualityMax) };
        AVAudioFile *outputFile = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:outputPath] settings:outputSettings commonFormat:monoBufferFormat.commonFormat interleaved:monoBufferFormat.isInterleaved error:&error];
        if (error || !outputFile) { if(completion) completion(nil, error); return; }
        
        AVAudioPCMBuffer *buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:monoBufferFormat frameCapacity:engine.manualRenderingMaximumFrameCount];
        
        while (YES) {
            AVAudioEngineManualRenderingStatus status = [engine renderOffline:buffer.frameCapacity toBuffer:buffer error:&error];
            if (status == AVAudioEngineManualRenderingStatusSuccess) {
                [outputFile writeFromBuffer:buffer error:&error];
                if (error) break;
            } else {
                break;
            }
        }
        
        [playerNode stop]; [engine stop];
        if (error) { if(completion) completion(nil, error); } else { if(completion) completion(outputPath, nil); }
    });
}
@end
