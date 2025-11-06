#import <Foundation/Foundation.h>

BOOL LifecycleSafety_RunAllTests(void);

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        BOOL success = LifecycleSafety_RunAllTests();
        if (!success) {
            fprintf(stderr, "Lifecycle safety tests failed\n");
            return 1;
        }
        printf("Lifecycle safety tests passed\n");
        return 0;
    }
}
