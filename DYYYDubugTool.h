#import <Foundation/Foundation.h>

/**
 * 打印一个Objective-C类的详细信息
 * @param cls 要检查的类
 * @return 类的接口定义，包括属性和方法
 */
NSString *dumpClassInfo(Class cls);

/**
 * 将Objective-C类型编码转换为可读字符串
 * @param encoding 类型编码字符串
 * @return 人类可读的类型名称
 */
NSString *humanReadableTypeFromEncoding(const char *encoding);