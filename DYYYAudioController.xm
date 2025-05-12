#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

static bool getUserDefaults(NSString *key) { return [[NSUserDefaults standardUserDefaults] boolForKey:key]; }
#define DYYYALLOW_KEY @"DYYYAllowConcurrentPlay"

#pragma mark AVAudioSession
%hook AVAudioSession
- (BOOL)setActive:(BOOL)active withOptions:(AVAudioSessionSetActiveOptions)options error:(NSError **)outError{
    
    NSString *category = [self category];

    if(getUserDefaults(DYYYALLOW_KEY)){
        [self setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:outError];
    }else{
        [self setCategory:category withOptions:2 error:outError];
    }

    return %orig;
}
%end
