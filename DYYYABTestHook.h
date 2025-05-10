#import <Foundation/Foundation.h>

// 声明全局变量
extern BOOL abTestBlockEnabled;
extern BOOL abTestPatchEnabled;
extern NSDictionary *gFixedABTestData;
extern dispatch_once_t onceToken;

// 声明函数
NSDictionary *loadFixedABTestData(void);
NSDictionary *getCurrentABTestData(void);
