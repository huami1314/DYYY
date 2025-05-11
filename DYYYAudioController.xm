#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

#pragma mark - 全局状态

static BOOL gPiPActive = NO;
static AVAudioSessionCategoryOptions gSavedOptions = 0;

#define DYYYALLOW_KEY @"DYYYAllowConcurrentPlay"

// 当前是否应启用 MixWithOthers
static inline BOOL wantsMix(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@DYYYALLOW_KEY] && !gPiPActive;
}

// 判断是否属于“纯音频”类别（可混音）
static inline BOOL isPureAudioCategory(NSString *category, NSString *mode) {
    // MoviePlayback
    if ([mode isEqualToString:AVAudioSessionModeMoviePlayback] ||
        [mode hasPrefix:@"Video"]) {
        return NO;
    }
    return ([category isEqualToString:AVAudioSessionCategoryPlayAndRecord] ||
            [category isEqualToString:AVAudioSessionCategoryMultiRoute]);
}

#pragma mark - AVAudioSession Hook

%group AudioPatch
%hook AVAudioSession

// setCategory:mode:options:error:
- (BOOL)setCategory:(NSString *)category
               mode:(NSString *)mode
            options:(AVAudioSessionCategoryOptions)options
              error:(NSError **)outError {

    if (wantsMix() && isPureAudioCategory(category, mode)) {
        options |= AVAudioSessionCategoryOptionMixWithOthers;
    }
    return %orig(category, mode, options, outError);
}

// setCategory:withOptions:error:
- (BOOL)setCategory:(NSString *)category
        withOptions:(AVAudioSessionCategoryOptions)options
              error:(NSError **)outError {

    if (wantsMix() && isPureAudioCategory(category, self.mode)) {
        options |= AVAudioSessionCategoryOptionMixWithOthers;
    }
    return %orig(category, options, outError);
}

// setCategory:error:
- (BOOL)setCategory:(NSString *)category error:(NSError **)outError {
    // 不走自己实现，防止递归；直接转调带 options 版本
    return [self setCategory:category
                 withOptions:0
                       error:outError];
}

%end
%end


#pragma mark - PiP 状态监听

// 内部助手：在 PiP 状态变化时调整 MixWithOthers
static void UpdateAudioSessionForPiP(BOOL active) {
    gPiPActive = active;

    AVAudioSession *session = [AVAudioSession sharedInstance];

    if (active) {
        // 进入 PiP：如有 MixWithOthers，先去掉
        gSavedOptions = [session categoryOptions];
        if (gSavedOptions & AVAudioSessionCategoryOptionMixWithOthers) {
            [session setCategory:[session category]
                            mode:[session mode]
                         options:(gSavedOptions & ~AVAudioSessionCategoryOptionMixWithOthers)
                           error:nil];
        }
    } else {
        // 退出 PiP：根据用户偏好恢复
        AVAudioSessionCategoryOptions opt = [session categoryOptions];
        if (wantsMix() && !(opt & AVAudioSessionCategoryOptionMixWithOthers)) {
            [session setCategory:[session category]
                            mode:[session mode]
                         options:(gSavedOptions | AVAudioSessionCategoryOptionMixWithOthers)
                           error:nil];
        }
    }
}

%ctor {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserverForName:AVPictureInPictureControllerWillStartPictureInPictureNotification
                    object:nil queue:nil
                usingBlock:^(__unused NSNotification *note) {
                    UpdateAudioSessionForPiP(YES);
                }];

    [nc addObserverForName:AVPictureInPictureControllerDidStopPictureInPictureNotification
                    object:nil queue:nil
                usingBlock:^(__unused NSNotification *note) {
                    UpdateAudioSessionForPiP(NO);
                }];
}
