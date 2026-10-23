#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface DYYYAudioManager : NSObject

+ (instancetype)sharedManager;

// 在原有的方法下面添加：
- (BOOL)renameItemAtPath:(NSString *)path toNewName:(NSString *)newName;
- (BOOL)deleteItemAtPath:(NSString *)path;
- (BOOL)createFolderNamed:(NSString *)folderName atSubPath:(NSString *)subPath;
- (NSArray<NSDictionary *> *)getContentsAtSubPath:(NSString *)subPath;
- (NSString *)voiceDirectory; // 暴露根目录路径

// 保存音频到收藏夹（传入下载好的音频本地路径和自定义名称）
- (void)saveAudioAtURL:(NSURL *)fileURL withName:(NSString *)name;

// 必须声明这个方法，否则编译会报错
- (void)downloadAndSaveAudioFromUrl:(NSString *)urlString withName:(NSString *)name;

// 获取所有已收藏的语音名称列表
- (NSArray<NSString *> *)getSavedAudioNames;

// 播放指定名称的语音
- (void)playAudioNamed:(NSString *)name;

// 停止播放
- (void)stopPlaying;

@end