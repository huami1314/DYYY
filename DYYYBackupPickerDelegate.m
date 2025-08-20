#import "DYYYBackupPickerDelegate.h"

@implementation DYYYBackupPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.count > 0 && self.completionBlock) {
        self.completionBlock(urls.firstObject);
    }
    [self cleanupTempFile];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [self cleanupTempFile];
}

- (void)cleanupTempFile {
    if (self.tempFilePath && [[NSFileManager defaultManager] fileExistsAtPath:self.tempFilePath]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.tempFilePath error:&error];
        if (error) {
            NSLog(@"[DYYY] \u6e05\u7406\u4e34\u65f6\u6587\u4ef6\u5931\u8d25: %@", error.localizedDescription);
        }
    }
}
@end
