#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "DYYYDubugTool.h"

// 添加函数声明
NSString *humanReadableTypeFromEncoding(const char *encoding);

NSString *dumpClassInfo(Class cls) {
    if (!cls)
        return @"类不存在";

    NSMutableString *result = [NSMutableString stringWithFormat:@"@interface %s : %s\n", class_getName(cls), class_getName(class_getSuperclass(cls))];

    // 获取所有属性
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList(cls, &propertyCount);

    for (unsigned int i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        const char *attributes = property_getAttributes(property);

        NSString *type = @"id";
        if (attributes) {
            NSString *attrStr = [NSString stringWithUTF8String:attributes];
            NSArray *attrComponents = [attrStr componentsSeparatedByString:@","];
            if (attrComponents.count > 0) {
                NSString *typeComponent = attrComponents[0];
                if ([typeComponent hasPrefix:@"T"]) {
                    NSString *typeStr = [typeComponent substringFromIndex:1];
                    if ([typeStr hasPrefix:@"@\""] && [typeStr hasSuffix:@"\""]) {
                        type = [typeStr substringWithRange:NSMakeRange(2, typeStr.length - 3)];
                    } else if ([typeStr isEqualToString:@"i"]) {
                        type = @"NSInteger";
                    } else if ([typeStr isEqualToString:@"f"]) {
                        type = @"float";
                    } else if ([typeStr isEqualToString:@"d"]) {
                        type = @"double";
                    } else if ([typeStr isEqualToString:@"B"]) {
                        type = @"BOOL";
                    } else {
                        type = typeStr;
                    }
                }
            }
        }

        [result appendFormat:@"@property (nonatomic) %@ %s;\n", type, name];
    }

    if (properties)
        free(properties);

    // 获取所有实例方法
    unsigned int methodCount;
    Method *methods = class_copyMethodList(cls, &methodCount);

    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *name = sel_getName(selector);
        
        // 获取方法返回类型
        char returnType[256];
        method_getReturnType(method, returnType, 256);
        // 修改这里：由消息发送改为直接函数调用
        NSString *returnTypeString = humanReadableTypeFromEncoding(returnType);
        
        [result appendFormat:@"- (%@)%s;\n", returnTypeString, name];
    }

    if (methods)
        free(methods);

    // 获取所有类方法
    methodCount = 0;
    methods = class_copyMethodList(object_getClass(cls), &methodCount);

    for (unsigned int i = 0; i < methodCount; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *name = sel_getName(selector);
        
        // 获取方法返回类型
        char returnType[256];
        method_getReturnType(method, returnType, 256);
        NSString *returnTypeString = humanReadableTypeFromEncoding(returnType);
        
        // 过滤掉Objective-C运行时自动生成的方法
        if (strncmp(name, ".cxx_", 5) != 0 && strcmp(name, "load") != 0 && strcmp(name, "initialize") != 0) {
            [result appendFormat:@"+ (%@)%s;\n", returnTypeString, name];
        }
    }

    if (methods)
        free(methods);

    [result appendString:@"@end\n"];
    return result;
}

// 辅助方法，转换类型编码为可读类型
NSString *humanReadableTypeFromEncoding(const char *encoding) {
    if (!encoding || encoding[0] == '\0') return @"void";
    
    switch (encoding[0]) {
        case 'c': return @"char";
        case 'i': return @"int";
        case 's': return @"short";
        case 'l': return @"long";
        case 'q': return @"long long";
        case 'C': return @"unsigned char";
        case 'I': return @"unsigned int";
        case 'S': return @"unsigned short";
        case 'L': return @"unsigned long";
        case 'Q': return @"unsigned long long";
        case 'f': return @"float";
        case 'd': return @"double";
        case 'B': return @"BOOL";
        case 'v': return @"void";
        case '*': return @"char *";
        case '#': return @"Class";
        case ':': return @"SEL";
        case '?': return @"unknown";
        case '@': 
            if (strlen(encoding) > 3 && encoding[1] == '"') {
                // 提取类名
                NSString *className = [NSString stringWithUTF8String:encoding + 2];
                if ([className hasSuffix:@"\""]) {
                    className = [className substringToIndex:className.length - 1];
                }
                return className;
            }
            return @"id";
        default: return @"id";
    }
}