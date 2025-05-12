#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#pragma mark

static bool getUserDefaults(NSString *key) { return [[NSUserDefaults standardUserDefaults] boolForKey:key]; }
#define DYYYALLOW_KEY @"DYYYAllowConcurrentPlay"

%hook AVAudioSession

- (BOOL)setCategory:(AVAudioSessionCategory)category withOptions:(AVAudioSessionCategoryOptions)options error:(NSError **)outError {
    if (getUserDefaults(DYYYALLOW_KEY) &&
        ([category isEqualToString:AVAudioSessionCategoryPlayback] ||
        [category isEqualToString:AVAudioSessionCategoryPlayAndRecord] ||
        [category isEqualToString:AVAudioSessionCategoryMultiRoute])) {
        options |= AVAudioSessionCategoryOptionMixWithOthers;
        %log;
    }
    return %orig(category, options, outError);
}

- (BOOL)setCategory:(AVAudioSessionCategory)category error:(NSError **)outError {
    if (getUserDefaults(DYYYALLOW_KEY) &&
        ([category isEqualToString:AVAudioSessionCategoryPlayback] ||
        [category isEqualToString:AVAudioSessionCategoryPlayAndRecord] ||
        [category isEqualToString:AVAudioSessionCategoryMultiRoute])) {
        return [self setCategory:category
                     withOptions:AVAudioSessionCategoryOptionMixWithOthers
                           error:outError];
    }
    return %orig;
}

- (BOOL)setCategory:(AVAudioSessionCategory)category mode:(AVAudioSessionMode)mode options:(AVAudioSessionCategoryOptions)options error:(NSError **)outError {
 
    if (getUserDefaults(DYYYALLOW_KEY) &&
        ([category isEqualToString:AVAudioSessionCategoryPlayback] ||
        [category isEqualToString:AVAudioSessionCategoryPlayAndRecord] ||
        [category isEqualToString:AVAudioSessionCategoryMultiRoute])) {
        options |= AVAudioSessionCategoryOptionMixWithOthers;
        %log;
    }
    return %orig(category, mode, options, outError);
}

- (BOOL)setActive:(BOOL)active withOptions:(AVAudioSessionSetActiveOptions)options error:(NSError **)outError {
    BOOL result = %orig;
    if (getUserDefaults(DYYYALLOW_KEY) && active && result) {
        AVAudioSessionCategoryOptions currentOptions = [self categoryOptions];
        if (!(currentOptions & AVAudioSessionCategoryOptionMixWithOthers)) {
            AVAudioSessionCategory currentCategory = [self category];
            if ([currentCategory isEqualToString:AVAudioSessionCategoryPlayback] ||
                [currentCategory isEqualToString:AVAudioSessionCategoryPlayAndRecord] ||
                [currentCategory isEqualToString:AVAudioSessionCategoryMultiRoute]) {
                [self setCategory:currentCategory
                      withOptions:currentOptions | AVAudioSessionCategoryOptionMixWithOthers
                            error:nil];
            }
        }
    }
    return result;
}

%end