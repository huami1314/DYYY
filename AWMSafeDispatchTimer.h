#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWMSafeDispatchTimer : NSObject

- (void)startWithInterval:(NSTimeInterval)interval
                   leeway:(NSTimeInterval)leeway
                    queue:(dispatch_queue_t)queue
                 repeats:(BOOL)repeats
                 handler:(dispatch_block_t)handler;

- (void)cancel;

@property (nonatomic, readonly, getter=isRunning) BOOL running;

@end

NS_ASSUME_NONNULL_END
