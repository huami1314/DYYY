#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

static BOOL gPiPActive = NO;
static AVAudioSessionCategoryOptions gSavedOptions = 0;
#define DYYYALLOW_KEY @"DYYYAllowConcurrentPlay"

static inline BOOL wantsMix(void) {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@DYYYALLOW_KEY] && !gPiPActive;
}

static inline BOOL isPureAudioCategory(NSString *category, NSString *mode) {
    if ([mode isEqualToString:AVAudioSessionModeMoviePlayback] || [mode hasPrefix:@"Video"]) {
        return NO;
    }
    return ([category isEqualToString:AVAudioSessionCategoryPlayAndRecord] ||
            [category isEqualToString:AVAudioSessionCategoryMultiRoute]);
}

%group DYYYAudioPatch
%hook AVAudioSession

- (BOOL)setCategory:(NSString *)category mode:(NSString *)mode options:(AVAudioSessionCategoryOptions)options error:(NSError **)error {
    if (wantsMix() && isPureAudioCategory(category, mode)) {
        options |= AVAudioSessionCategoryOptionMixWithOthers;
    }
    return %orig(category, mode, options, error);
}

- (BOOL)setCategory:(NSString *)category withOptions:(AVAudioSessionCategoryOptions)options error:(NSError **)error {
    if (wantsMix() && isPureAudioCategory(category, self.mode)) {
        options |= AVAudioSessionCategoryOptionMixWithOthers;
    }
    return %orig(category, options, error);
}

- (BOOL)setCategory:(NSString *)category error:(NSError **)error {
    return [self setCategory:category withOptions:0 error:error];
}

%end
%end

static void UpdateAudioSessionForPiP(BOOL active) {
    gPiPActive = active;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    if (active) {
        gSavedOptions = [session categoryOptions];
        if (gSavedOptions & AVAudioSessionCategoryOptionMixWithOthers) {
            [session setCategory:[session category] mode:[session mode] options:(gSavedOptions & ~AVAudioSessionCategoryOptionMixWithOthers) error:nil];
        }
    } else {
        AVAudioSessionCategoryOptions opt = [session categoryOptions];
        if (wantsMix() && !(opt & AVAudioSessionCategoryOptionMixWithOthers)) {
            [session setCategory:[session category] mode:[session mode] options:(gSavedOptions | AVAudioSessionCategoryOptionMixWithOthers) error:nil];
        }
    }
}

%ctor {
    NSNotificationCenter *c = [NSNotificationCenter defaultCenter];
    [c addObserverForName:AVPictureInPictureControllerWillStartPictureInPictureNotification object:nil queue:nil usingBlock:^(__unused NSNotification *n) { UpdateAudioSessionForPiP(YES); }];
    [c addObserverForName:AVPictureInPictureControllerDidStopPictureInPictureNotification object:nil queue:nil usingBlock:^(__unused NSNotification *n) { UpdateAudioSessionForPiP(NO); }];
    %init(DYYYAudioPatch);
}
