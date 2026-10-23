#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Present the system file picker and copy a selected GIF into DYYY's Documents/DYYY directory.
void DYYYPresentProgressGIFPicker(UIViewController *presentingViewController, void (^completion)(NSString * _Nullable savedPath));

/// Decode a local GIF into an animated UIImage suitable for UIImageView animation.
UIImage * _Nullable DYYYAnimatedImageFromGIFPath(NSString *path);

NS_ASSUME_NONNULL_END
