#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <dlfcn.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <stdio.h>
#include <errno.h>

// 常见越狱文件路径列表
NSArray* jailbreakPaths() {
    return @[
        // Rootful越狱路径
        @"/Applications/Cydia.app", 
        @"/Applications/Sileo.app",
        @"/Applications/Zebra.app",
        @"/Applications/Santander.app",
        @"/Library/MobileSubstrate",
        @"/Library/PreferenceBundles",
        @"/Library/PreferenceLoader",
        @"/etc/apt",
        @"/private/var/lib/apt",
        @"/usr/sbin/sshd",
        @"/usr/libexec/ssh-keysign",
        @"/var/cache/apt",
        @"/var/lib/apt",
        @"/var/lib/cydia",
        @"/var/log/syslog",
        @"/var/tmp/cydia.log",
        @"/bin/bash",
        @"/bin/sh",
        @"/usr/bin/sshd",
        @"/usr/libexec/sftp-server",
        @"/etc/ssh/sshd_config",
        @"/var/stash",
        @"/.installed_unc0ver",
        @"/.bootstrapped_electra",
        @"/jb",
        @"/var/LIB",
        @"/usr/lib/libsubstrate.dylib",
        @"/usr/lib/libsubstitute.dylib",
        @"/usr/lib/libhooker.dylib",
        @"/etc/apt/sources.list.d",
        
        // Rootless越狱路径
        @"/var/jb",
        @"/var/jb/Applications/Sileo.app",
        @"/var/jb/Applications/Cydia.app",
        @"/var/jb/Applications/Zebra.app",
        @"/var/jb/usr/lib",
        @"/var/jb/Library/MobileSubstrate",
        @"/var/jb/bin/bash",
        @"/var/jb/usr/lib/libsubstrate.dylib",
        @"/var/jb/usr/lib/libsubstitute.dylib",
        @"/var/jb/usr/lib/libhooker.dylib"
    ];
}

// 常见越狱相关动态库
NSArray* jailbreakLibraries() {
    return @[
        @"libsubstrate.dylib",
        @"libsubstitute.dylib",
        @"libhooker.dylib",
        @"TweakInject",
        @"CydiaSubstrate",
        @"MobileSubstrate"
    ];
}

// 隐藏文件系统检测
%hook NSFileManager

- (BOOL)fileExistsAtPath:(NSString *)path {
    for (NSString *jbPath in jailbreakPaths()) {
        if ([path isEqualToString:jbPath] || [path hasPrefix:jbPath]) {
            return NO;
        }
    }
    return %orig;
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory {
    for (NSString *jbPath in jailbreakPaths()) {
        if ([path isEqualToString:jbPath] || [path hasPrefix:jbPath]) {
            if (isDirectory != NULL) {
                *isDirectory = NO;
            }
            return NO;
        }
    }
    return %orig;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error {
    NSArray *result = %orig;
    
    // 在根目录时隐藏越狱目录
    if ([path isEqualToString:@"/"]) {
        NSMutableArray *filteredResult = [NSMutableArray arrayWithArray:result];
        [filteredResult removeObject:@"Applications"];
        [filteredResult removeObject:@"jb"];
        [filteredResult removeObject:@"Library"];
        return filteredResult;
    }
    
    // 在/var目录时隐藏rootless越狱目录
    if ([path isEqualToString:@"/var"]) {
        NSMutableArray *filteredResult = [NSMutableArray arrayWithArray:result];
        [filteredResult removeObject:@"jb"];
        return filteredResult;
    }
    
    return result;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error {
    for (NSString *jbPath in jailbreakPaths()) {
        if ([path isEqualToString:jbPath] || [path hasPrefix:jbPath]) {
            if (error) {
                *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoSuchFileError userInfo:nil];
            }
            return nil;
        }
    }
    return %orig;
}

%end

// 隐藏环境变量检测
%hook NSProcessInfo

- (NSDictionary *)environment {
    NSMutableDictionary *env = [%orig mutableCopy];
    [env removeObjectForKey:@"DYLD_INSERT_LIBRARIES"];
    [env removeObjectForKey:@"_MSSafeMode"];
    [env removeObjectForKey:@"_SafeMode"];
    return env;
}

%end

// 阻止URL scheme检测
%hook UIApplication

- (BOOL)canOpenURL:(NSURL *)url {
    NSString *scheme = [url scheme];
    if ([scheme isEqualToString:@"cydia"] ||
        [scheme isEqualToString:@"sileo"] ||
        [scheme isEqualToString:@"zbra"] ||
        [scheme isEqualToString:@"filza"]) {
        return NO;
    }
    return %orig;
}

%end

// 隐藏写入受保护目录的权限测试
%hook NSString

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError **)error {
    if ([path hasPrefix:@"/private/"] && ![path hasPrefix:@"/private/var/mobile"]) {
        if (error) {
            *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteNoPermissionError userInfo:nil];
        }
        return NO;
    }
    return %orig;
}

%end

%hook NSData

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile {
    if ([path hasPrefix:@"/private/"] && ![path hasPrefix:@"/private/var/mobile"]) {
        return NO;
    }
    return %orig;
}

%end

// 钩住底层系统调用
%hookf(int, access, const char *path, int mode) {
    if (path) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        for (NSString *jbPath in jailbreakPaths()) {
            if ([pathStr isEqualToString:jbPath] || [pathStr hasPrefix:jbPath]) {
                errno = ENOENT;
                return -1;
            }
        }
    }
    return %orig;
}

%hookf(int, stat, const char *path, struct stat *buf) {
    if (path) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        for (NSString *jbPath in jailbreakPaths()) {
            if ([pathStr isEqualToString:jbPath] || [pathStr hasPrefix:jbPath]) {
                errno = ENOENT;
                return -1;
            }
        }
    }
    return %orig;
}

%hookf(FILE *, fopen, const char *path, const char *mode) {
    if (path) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        for (NSString *jbPath in jailbreakPaths()) {
            if ([pathStr isEqualToString:jbPath] || [pathStr hasPrefix:jbPath]) {
                errno = ENOENT;
                return NULL;
            }
        }
    }
    return %orig;
}

// 隐藏越狱动态库加载检测
%hookf(void *, dlopen, const char *path, int mode) {
    if (path) {
        NSString *pathStr = [NSString stringWithUTF8String:path];
        for (NSString *lib in jailbreakLibraries()) {
            if ([pathStr containsString:lib]) {
                return NULL;
            }
        }
    }
    return %orig;
}

// 拦截dlsym动态符号查找
%hookf(void *, dlsym, void *handle, const char *symbol) {
    if (symbol) {
        if (strcmp(symbol, "MSGetImageByName") == 0 ||
            strcmp(symbol, "MSFindSymbol") == 0 ||
            strcmp(symbol, "MSHookFunction") == 0 ||
            strcmp(symbol, "MSHookMessageEx") == 0) {
            return NULL;
        }
    }
    return %orig;
}

%ctor {
    %init;
}