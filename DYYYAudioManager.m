#import "DYYYAudioManager.h"
#import "DYYYUtils.h"
#import <AVFoundation/AVFoundation.h>

@interface DYYYAudioManager () <AVAudioPlayerDelegate>
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) NSString *voiceDirectory;
@end

@implementation DYYYAudioManager

+ (instancetype)sharedManager {
    static DYYYAudioManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        // 在 App 的 Documents 目录下创建一个专属的 DYYY_Voices 文件夹
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths firstObject];
        _voiceDirectory = [docDir stringByAppendingPathComponent:@"DYYY_Voices"];
        
        NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:_voiceDirectory]) {
        NSError *createError = nil;
        [fm createDirectoryAtPath:_voiceDirectory withIntermediateDirectories:YES attributes:nil error:&createError];
        if (createError) {
            NSLog(@"[DYYY] 创建语音目录失败: %@", createError);
        }
    }
    }
    return self;
}

#pragma mark - 文件操作

// 用于手动导入本地文件
- (void)saveAudioAtURL:(NSURL *)fileURL withName:(NSString *)name {
    if (!fileURL || !name || name.length == 0) return;
    
    NSString *extension = [fileURL pathExtension] ?: @"mp3";
    NSString *fileName = [NSString stringWithFormat:@"%@.%@", name, extension];
    NSString *destPath = [self.voiceDirectory stringByAppendingPathComponent:fileName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:destPath]) {
        [fm removeItemAtPath:destPath error:nil];
    }
    
    NSError *error;
    [fm copyItemAtURL:fileURL toURL:[NSURL fileURLWithPath:destPath] error:&error];
}

// 【联动功能核心】：从网络链接下载音频并存入收藏夹
- (void)downloadAndSaveAudioFromUrl:(NSString *)urlString withName:(NSString *)name {
    if (!urlString || urlString.length == 0) return;
    
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.timeoutInterval = 30.0;
    [[[NSURLSession sharedSession] downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"下载音频失败"];
            });
            return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        long long contentLength = [httpResponse.allHeaderFields[@"Content-Length"] longLongValue];
        if (contentLength > 50 * 1024 * 1024) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"文件过大，无法保存"];
            });
            [[NSFileManager defaultManager] removeItemAtURL:location error:nil];
            return;
        }

        NSString *contentType = httpResponse.allHeaderFields[@"Content-Type"];
        if (contentType && ![contentType hasPrefix:@"audio/"] && ![contentType hasPrefix:@"application/octet-stream"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"非音频文件，无法保存"];
            });
            [[NSFileManager defaultManager] removeItemAtURL:location error:nil];
            return;
        }

        // 默认使用 .mp3 后缀，也可以根据链接动态获取
        NSString *ext = [urlString pathExtension];
        if (ext.length == 0 || [ext containsString:@"?"]) ext = @"mp3";
        
        NSString *fileName = [NSString stringWithFormat:@"%@.%@", name, ext];
        NSString *destPath = [self.voiceDirectory stringByAppendingPathComponent:fileName];
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:destPath]) {
            [fm removeItemAtPath:destPath error:nil];
        }

        NSError *moveError;
        // 使用 moveItem 将下载好的临时文件移动到收藏夹目录
        [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:destPath] error:&moveError];

        dispatch_async(dispatch_get_main_queue(), ^{
            if (!moveError) {
                [DYYYUtils showToast:[NSString stringWithFormat:@"已存入语音收藏夹：%@", name]];
            } else {
                [DYYYUtils showToast:@"保存文件失败"];
            }
        });
    }] resume];
}

// 获取所有已收藏音频的名称（不含后缀）
- (NSArray<NSString *> *)getSavedAudioNames {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:self.voiceDirectory error:nil];
    NSMutableArray *names = [NSMutableArray array];
    
    for (NSString *file in files) {
        if ([file hasSuffix:@".mp3"] || [file hasSuffix:@".m4a"] || [file hasSuffix:@".wav"]) {
            [names addObject:[file stringByDeletingPathExtension]];
        }
    }
    // 按字母顺序排序
    return [names sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (NSString *)voiceDirectory {
    return _voiceDirectory;
}

// 创建文件夹
- (BOOL)createFolderNamed:(NSString *)folderName atSubPath:(NSString *)subPath {
    NSString *targetPath = self.voiceDirectory;
    if (subPath && subPath.length > 0) {
        targetPath = [targetPath stringByAppendingPathComponent:subPath];
    }
    NSString *newFolderPath = [targetPath stringByAppendingPathComponent:folderName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:newFolderPath]) {
        return [fm createDirectoryAtPath:newFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return NO; // 已存在
}

// 获取目录下的内容（区分文件和文件夹，并获取大小格式）
- (NSArray<NSDictionary *> *)getContentsAtSubPath:(NSString *)subPath {
    NSString *targetPath = self.voiceDirectory;
    if (subPath && subPath.length > 0) {
        targetPath = [targetPath stringByAppendingPathComponent:subPath];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:targetPath error:nil];
    
    NSMutableArray *folders = [NSMutableArray array];
    NSMutableArray *audioFiles = [NSMutableArray array];
    
    for (NSString *fileName in files) {
        if ([fileName hasPrefix:@"."]) continue; 

        // 1. 先生成完整路径
        NSString *fullPath = [targetPath stringByAppendingPathComponent:fileName];
        
        // 2. 获取文件属性 (attrs)
        NSDictionary *attrs = [fm attributesOfItemAtPath:fullPath error:nil];
        // 3. 提取修改时间 (date)
        NSDate *modDate = [attrs fileModificationDate] ?: [NSDate distantPast];

        BOOL isDir = NO;
        [fm fileExistsAtPath:fullPath isDirectory:&isDir];
        
        if (isDir) {
            [folders addObject:@{
                @"type": @"folder",
                @"name": fileName,
                @"path": fullPath,
                @"date": modDate
            }];
        } else {
            NSString *ext = [fileName pathExtension].lowercaseString;
            if ([ext isEqualToString:@"mp3"] || [ext isEqualToString:@"m4a"] || [ext isEqualToString:@"wav"]) {
                unsigned long long size = [attrs fileSize];
                NSString *sizeStr = [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile];
                
                [audioFiles addObject:@{
                    @"type": @"file",
                    @"name": [fileName stringByDeletingPathExtension],
                    @"ext": ext.uppercaseString,
                    @"size": sizeStr,
                    @"path": fullPath,
                    @"date": modDate // 用于排序
                }];
            }
        }
    }
    
    // 文件夹按名称排序
    [folders sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1[@"name"] localizedCaseInsensitiveCompare:obj2[@"name"]];
    }];
    
    // 音频文件按时间倒序排列 (最新的在最上面)
    [audioFiles sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2[@"date"] compare:obj1[@"date"]]; 
    }];
    
    NSMutableArray *result = [NSMutableArray array];
    [result addObjectsFromArray:folders];
    [result addObjectsFromArray:audioFiles];
    
    return result;
}
#pragma mark - 播放逻辑

- (void)playAudioNamed:(NSString *)name {
    NSArray *extensions = @[@"mp3", @"m4a", @"wav"];
    NSString *targetPath = nil;
    
    for (NSString *ext in extensions) {
        NSString *path = [self.voiceDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", name, ext]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            targetPath = path;
            break;
        }
    }
    
    if (!targetPath) return; 

    NSURL *url = [NSURL fileURLWithPath:targetPath];
    
    // 停止当前播放
    [self stopPlaying];
    
    // 配置音频会话：确保静音开关开启时也能播放，且不被系统音效打断
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    [session setActive:YES error:nil];
    
    NSError *error = nil;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    self.audioPlayer.delegate = self;
    [self.audioPlayer prepareToPlay];
    [self.audioPlayer play];
}

- (void)stopPlaying {
    if (self.audioPlayer && self.audioPlayer.isPlaying) {
        [self.audioPlayer stop];
    }
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    // 播放完成后释放资源（可选）
}


// 重命名文件或文件夹
- (BOOL)renameItemAtPath:(NSString *)path toNewName:(NSString *)newName {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) return NO;
    
    NSString *dir = [path stringByDeletingLastPathComponent];
    NSString *ext = [path pathExtension];
    
    NSString *newFileName = newName;
    // 如果是文件，重命名时保留原后缀
    BOOL isDir = NO;
    [fm fileExistsAtPath:path isDirectory:&isDir];
    if (!isDir && ext.length > 0) {
        newFileName = [newName stringByAppendingPathExtension:ext];
    }
    
    NSString *newPath = [dir stringByAppendingPathComponent:newFileName];
    if ([fm fileExistsAtPath:newPath]) return NO; // 目标名称已存在
    
    return [fm moveItemAtPath:path toPath:newPath error:nil];
}

// 删除文件或文件夹
- (BOOL)deleteItemAtPath:(NSString *)path {
    return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}

@end