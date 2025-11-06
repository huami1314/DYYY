#import <Foundation/Foundation.h>
#import <os/log.h>

#ifndef DYYYLifecycleSafety_h
#define DYYYLifecycleSafety_h

#if DEBUG
#define DYYYDebugLog(fmt, ...)                                                                                                                             \
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_INFO, "[DYYYLifecycle][%{public}s:%d] " fmt, __FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#define DYYYDebugLog(fmt, ...)
#endif

#if defined(DEBUG) && !defined(NDEBUG)
#define DYYY_KEYWORDIFY autoreleasepool {}
#else
#define DYYY_KEYWORDIFY try {} @catch (...) {}
#endif

#define weakify(object)                                                                                                                                     \
    DYYY_KEYWORDIFY                                                                                                                                         \
    __weak __typeof__(object) weak_##object = (object);

#define strongify(object)                                                                                                                                    \
    DYYY_KEYWORDIFY                                                                                                                                         \
    __strong __typeof__(object) object = weak_##object;

static inline void DYYYDispatchAfterWeak(NSTimeInterval delay, __weak id owner, void (^block)(id owner)) {
    if (!block) {
        return;
    }
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
    dispatch_after(time, dispatch_get_main_queue(), ^{
      id strongOwner = owner;
      if (!strongOwner) {
          DYYYDebugLog("DispatchAfterWeak skipped (owner deallocated)");
          return;
      }
      block(strongOwner);
    });
}

#endif /* DYYYLifecycleSafety_h */
