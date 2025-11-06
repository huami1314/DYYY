#import "AWMSafeDispatchTimer.h"

#import "DYYYLifecycleSafety.h"

static const void *kAWMSafeDispatchTimerSpecificKey = &kAWMSafeDispatchTimerSpecificKey;

@interface AWMSafeDispatchTimer ()
@property (nonatomic, strong, nullable) dispatch_source_t internalTimer;
@property (nonatomic, assign) BOOL resumed;
@property (nonatomic, copy, nullable) dispatch_block_t internalHandler;
@property (nonatomic, strong) dispatch_queue_t synchronizationQueue;
@property (nonatomic, assign, getter=isRunning) BOOL running;
@end

@implementation AWMSafeDispatchTimer

- (instancetype)init {
    self = [super init];
    if (self) {
        _synchronizationQueue = dispatch_queue_create("com.dyyy.safeDispatchTimer", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_synchronizationQueue, kAWMSafeDispatchTimerSpecificKey, (__bridge void *)self, NULL);
    }
    return self;
}

- (void)startWithInterval:(NSTimeInterval)interval
                   leeway:(NSTimeInterval)leeway
                    queue:(dispatch_queue_t)queue
                 repeats:(BOOL)repeats
                 handler:(dispatch_block_t)handler {
    if (interval <= 0.0) {
        interval = 0.1;
    }
    dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
    uint64_t repeatInterval = repeats ? (uint64_t)(interval * NSEC_PER_SEC) : DISPATCH_TIME_FOREVER;
    uint64_t tolerance = leeway > 0 ? (uint64_t)(leeway * NSEC_PER_SEC) : (uint64_t)(0.1 * NSEC_PER_SEC);

    __weak typeof(self) weakSelf = self;
    dispatch_async(self.synchronizationQueue, ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      if (!strongSelf) {
          return;
      }

      [strongSelf cancelLocked];

      dispatch_queue_t targetQueue = queue ?: dispatch_get_main_queue();
      dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, targetQueue);
      if (!timer) {
          return;
      }

      strongSelf.internalTimer = timer;
      strongSelf.internalHandler = handler;

      dispatch_source_set_timer(timer, startTime, repeatInterval, tolerance);
      dispatch_source_set_event_handler(timer, ^{
        __strong typeof(weakSelf) innerSelf = weakSelf;
        if (!innerSelf) {
            return;
        }
        dispatch_block_t block = innerSelf.internalHandler;
        if (block) {
            block();
        }
        if (!repeats) {
            [innerSelf cancel];
        }
      });

      if (!strongSelf.resumed) {
          dispatch_resume(timer);
          strongSelf.resumed = YES;
          DYYYDebugLog("dispatch_timer_resume start interval=%.3f repeats=%{public}@", interval, repeats ? @"YES" : @"NO");
      }

      strongSelf.running = YES;
    });
}

- (void)cancel {
    dispatch_async(self.synchronizationQueue, ^{
      [self cancelLocked];
    });
}

- (void)cancelLocked {
    if (!self.internalTimer) {
        return;
    }

    dispatch_source_t timer = self.internalTimer;
    self.internalHandler = nil;
    self.internalTimer = nil;

    dispatch_source_set_event_handler(timer, ^{});

    if (self.resumed) {
        dispatch_source_cancel(timer);
        self.resumed = NO;
        DYYYDebugLog("dispatch_timer_cancel");
    }

    self.running = NO;
}

- (BOOL)isRunning {
    if (dispatch_get_specific(kAWMSafeDispatchTimerSpecificKey) == (__bridge void *)self) {
        return _running;
    }

    __block BOOL runningState = NO;
    dispatch_sync(self.synchronizationQueue, ^{
      runningState = _running;
    });
    return runningState;
}

- (void)dealloc {
    if (self.synchronizationQueue) {
        dispatch_queue_set_specific(self.synchronizationQueue, kAWMSafeDispatchTimerSpecificKey, NULL, NULL);
    }
    [self cancel];
}

@end
