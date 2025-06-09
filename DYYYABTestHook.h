#import <Foundation/Foundation.h>

// 声明全局变量
extern BOOL abTestBlockEnabled;
extern BOOL abTestPatchEnabled;
extern NSDictionary *gFixedABTestData;
extern dispatch_once_t onceToken;
extern BOOL gDataLoaded;

// 声明函数
void ensureABTestDataLoaded(void);
NSDictionary *getCurrentABTestData(void);
