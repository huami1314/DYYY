#import <Foundation/Foundation.h>

#import "AWMSafeDispatchTimer.h"
#import "DYYYLifecycleSafety.h"

static BOOL LifecycleSafety_TimerCancelsSafely(void) {
    __block NSInteger fireCount = 0;
    dispatch_queue_t queue = dispatch_queue_create("com.dyyy.lifecycleSafety.timer", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t fireSignal = dispatch_semaphore_create(0);

    AWMSafeDispatchTimer *timer = [[AWMSafeDispatchTimer alloc] init];
    [timer startWithInterval:0.05
                      leeway:0.01
                       queue:queue
                    repeats:YES
                    handler:^{
                      fireCount++;
                      dispatch_semaphore_signal(fireSignal);
                    }];

    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC * 1.0));
    if (dispatch_semaphore_wait(fireSignal, timeout) != 0) {
        return NO;
    }
    if (dispatch_semaphore_wait(fireSignal, timeout) != 0) {
        return NO;
    }

    [timer cancel];

    dispatch_time_t postCancelTimeout = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC));
    BOOL firedAfterCancel = (dispatch_semaphore_wait(fireSignal, postCancelTimeout) == 0);
    return !firedAfterCancel;
}

static BOOL LifecycleSafety_NotificationAutoRemoval(void) {
    NSString *notificationName = @"LifecycleSafetyTestNotificationInternal";
    __block NSInteger received = 0;

    id token = [[NSNotificationCenter defaultCenter] addObserverForName:notificationName
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(__unused NSNotification *note) {
                                                               received++;
                                                             }];

    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    if (received != 1) {
        [[NSNotificationCenter defaultCenter] removeObserver:token];
        return NO;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:token];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    return received == 1;
}

static BOOL LifecycleSafety_DispatchAfterWeakSkipsReleasedOwner(void) {
    __block BOOL fired = NO;
    @autoreleasepool {
        NSObject *owner = [[NSObject alloc] init];
        DYYYDispatchAfterWeak(0.1, owner, ^(__unused id retainedOwner) {
          fired = YES;
        });
        owner = nil;
    }
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.3]];
    return fired == NO;
}

BOOL LifecycleSafety_RunAllTests(void) {
    BOOL timerResult = LifecycleSafety_TimerCancelsSafely();
    BOOL notificationResult = LifecycleSafety_NotificationAutoRemoval();
    BOOL dispatchResult = LifecycleSafety_DispatchAfterWeakSkipsReleasedOwner();
    return timerResult && notificationResult && dispatchResult;
}

