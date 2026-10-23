#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DYYYVoiceChanger : NSObject

// 🚀 新增：控制和获取音频助手的工作状态
+ (void)setAudioAssistantActive:(BOOL)active;
+ (BOOL)isAudioAssistantActive;

+ (BOOL)processAudioFileFrom:(NSString *)srcPath to:(NSString *)dstPath;

+ (void)processAudioAtPath:(NSString *)inputPath
             withVoiceType:(NSInteger)voiceType 
                completion:(void(^)(NSString *outputPath, NSError *error))completion;

@end