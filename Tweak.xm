#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import "WeChatRedEnvelop.h"
#import "WeChatRedEnvelopParam.h"
#import "WCPLSettingViewController.h"
#import "WCPLReceiveRedEnvelopOperation.h"
#import "WCPLRedEnvelopTaskManager.h"
#import "WCPLRedEnvelopConfig.h"
#import "WCPLRedEnvelopParamQueue.h"
#import "WCPLNewFuncAddition.h"
#import "WCPLFuncService.h"
#import "WCPLAVManager.h"
#import "WeChatTweakSettingsController.h"
#import "MiYouSettingViewController.h"
#import "BNHelperSettingController.h"
#import "DouTuSettingViewController.h"
//#import "PJSettingViewController.h"
//#import "WCPluginsViewController.h"

@interface WCPluginsMgr : NSObject
+ (instancetype)sharedInstance;
- (void)registerControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller;
- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key;
@end

@interface UIViewController (MetricsNewHandling)
- (void)checkAndCreateDirectories;
@end

@implementation UIViewController (MetricsNewHandling)

- (void)checkAndCreateDirectories {
    NSArray *paths = @[
        @"Library/Caches/MetricsNew/wxtrics.db",
        @"Library/WechatPrivate/wpapp.db",
        @"Documents/00000000000000000000000000000000/MMliveDB.db"
    ];

    NSString *homeDirectory = NSHomeDirectory();
    NSFileManager *fileManager = [NSFileManager defaultManager];

    for (NSString *relativePath in paths) {
        NSString *fullPath = [homeDirectory stringByAppendingPathComponent:relativePath];
        NSString *directoryPath = [fullPath stringByDeletingLastPathComponent];
        NSError *error = nil;

        // 确保父目录存在
        if (![fileManager fileExistsAtPath:directoryPath]) {
            if (![fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create directory %@: %@", directoryPath, error);
                continue;  // 出错时继续处理下一个路径
            }
        }

        // 如果目标路径存在且不是目录，则删除它
        BOOL isDirectory = NO;
        BOOL fileExists = [fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory];
        if (fileExists && !isDirectory) {
            if (![fileManager removeItemAtPath:fullPath error:&error]) {
                NSLog(@"Failed to remove item at %@: %@", fullPath, error);
                continue;  // 出错时继续处理下一个路径
            }
        }

        // 创建目标路径（即便不存在）
        if (![fileManager fileExistsAtPath:fullPath]) {
            if (![fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create directory at %@: %@", fullPath, error);
            }
        }
    }
}

@end

%hook WCTableViewManager

- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(NSIndexPath *)arg2
{
    NSLog(@"---123: section = %ld, row = %ld", (long)arg2.section, (long)arg2.row);

    // 获取当前的视图控制器
    UIResponder *responder = arg1;
    while (responder && ![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
    }
    
    UIViewController *currentViewController = (UIViewController *)responder;
    Class PJSettingViewControllerClass = objc_getClass("PJSettingViewController");
    
    // 判断当前视图控制器是否是 PJSettingViewController
    if ([currentViewController isKindOfClass:PJSettingViewControllerClass]) {
        if (arg2.section == 2) {
            [arg1 deselectRowAtIndexPath:arg2 animated:YES];
            
            // 根据不同的行（row）执行不同的操作
            if (arg2.row == 0) {
                NSLog(@"成功1");
                
        // 跳转到微信公众号页面
    NSString *urlString = @"https://ok.uddz.cc";
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                
            } else if (arg2.row == 1) {
                NSLog(@"成功2");
                              
             // 跳转到微信公众号页面
    NSString *urlString = @"alipayqr://platformapi/startapp?saId=10000007&qrcode=https://qr.alipay.com/2m6163065i4esvwnjr4ha03";
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                
            } else if (arg2.row == 2) {
                NSLog(@"成功3");              
            }
            
        } else {
            %orig; // 如果不是第2组，执行原始的点击处理逻辑
        }
    } else {
        NSLog(@"点击其他控制器的。。。");
        %orig; // 如果不是目标控制器，执行原始的点击处理逻辑
    }
}

%end

@interface WCPluginsViewController : UIViewController
@end

%hook WCPluginsViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig; // 调用原始的方法

    // 检查是否关注了公众号
    Class MMServiceCenter = objc_getClass("MMServiceCenter");
    Class CContactMgr = objc_getClass("CContactMgr");
    if (MMServiceCenter && CContactMgr) {
        id serviceCenter = [MMServiceCenter defaultCenter];
        id contactMgr = [serviceCenter getService:CContactMgr];
        SEL isInContactListSelector = @selector(isInContactList:);
        if ([contactMgr respondsToSelector:isInContactListSelector]) {
            BOOL isFollowing = ((BOOL (*)(id, SEL, NSString *))objc_msgSend)(contactMgr, isInContactListSelector, @"gh_b49268f8f3ca");
            if (!isFollowing) {
                // 创建提示框
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"请关注公众号"
                                                                                         message:@"公众号：timi小糖果\n即可解锁所有功能！"
                                                                                  preferredStyle:UIAlertControllerStyleAlert];

                // 创建跳转按钮
                UIAlertAction *followAction = [UIAlertAction actionWithTitle:@"去关注"
                                                                         style:UIAlertActionStyleDefault
                                                                       handler:^(UIAlertAction *action) {
                    // 跳转到微信公众号页面
                    NSURL *githubUrl = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
                    Class MMWebViewController = objc_getClass("MMWebViewController");
                    if (MMWebViewController) {
                        UIViewController *webViewController = [[MMWebViewController alloc] initWithURL:githubUrl presentModal:NO extraInfo:nil];
                        if ([self.navigationController respondsToSelector:@selector(pushViewController:animated:)]) {
                            [self.navigationController pushViewController:webViewController animated:YES];
                        }
                    }
                }];

             // 添加跳转按钮到提示框
                [alertController addAction:followAction];

             // 展示提示框，设置 `animated:NO` 确保提示框出现时不可关闭
                [self presentViewController:alertController animated:YES completion:nil];

                // 将提示框设置为不可关闭
                [alertController setModalPresentationStyle:UIModalPresentationOverFullScreen];
            }
        }
    }
}

%end

NSString* modifiedTitleForTitle(NSString *title) {
    NSDictionary *titleMapping = @{
        @"微助io手": @"新插件名称 1",
        @"锤子助手": @"断点净化",
        @"斗图助手": @"断点斗图",
        @"消息屏蔽": @"断点屏蔽",
        @"小程序助手": @"断点程序",
        @"PKC": @"断点娱乐",
        @"快斗": @"断点快斗"
    };
    
    return titleMapping[title] ?: title; // 如果没有匹配的名称，返回原名称
}

%hook WCPluginsMgr

- (void)registerControllerWithTitle:(NSString *)title version:(NSString *)version controller:(NSString *)controller {
    // 修改插件名称
    NSString *modifiedTitle = modifiedTitleForTitle(title);
    
    // 调用原始方法
    %orig(modifiedTitle, version, controller);
}

- (void)registerSwitchWithTitle:(NSString *)title key:(NSString *)key {
    // 修改插件名称
    NSString *modifiedTitle = modifiedTitleForTitle(title);
    
    // 调用原始方法
    %orig(modifiedTitle, key);
}

%end

%hook UILabel

- (void)setText:(NSString *)text {
    NSString *newText;

    // 多个条件判断
    if ([text isEqualToString:@"黄白助手\nVersion-1.7.3"]) {
        newText = @"断点黄白\nVersion-1.7.3";
    } else if ([text isEqualToString:@"已关注"]) {
        newText = @"timi小糖果";
    } else if ([text isEqualToString:@"我的公众号"]) {
        newText = @"公众号";
    } else if ([text isEqualToString:@"关于黄白助手"]) {
        newText = @"公众号";
    } else if ([text isEqualToString:@"含有更新日志"]) {
        newText = @"timi小糖果";
    } else if ([text isEqualToString:@"关注作者公众号"]) {
        newText = @"公众号";
    } else if ([text isEqualToString:@"黄白助手 © 2022-5-28\n官方正式版本·功能持续开发中\nDeveloped by·Season in May 28,2022"]) {
        newText = @"断点黄白 © 2022-5-28\n官方正式版本·功能持续开发中\nDeveloped by·DuanDian in May 28,2022";
    } else if ([text isEqualToString:@"黄白助手1.7.3\n更新日志及友情支持\nQ群在最下方可以添加！"]) {
        newText = @"断点黄白1.7.3\n仅供定制使用\n感谢您的支持与信任！";
    } else if ([text isEqualToString:@"TG交流频道"]) {
        newText = @"官方网站";
    } else if ([text isEqualToString:@"支持作者"]) {
        newText = @"官方网站";
    } else if ([text isEqualToString:@"❤️"]) {
        newText = @"进入";
    } else if ([text isEqualToString:@"证书查询"]) {
        newText = @"到期时间";
    } else if ([text isEqualToString:@"All Rights Reserved By DumpApp"]) {
        newText = @"All Rights Reserved By DuanDian";
    } else if ([text isEqualToString:@"虚拟视频"]) {
        newText = @"断点视频";
    } else if ([text isEqualToString:@"本项目旨在学习iOS 逆向的一点实践，所有功能均免费使用，不可使用于商业和个人其他意图。若使用不当，均由个人承担。如有侵权，请联系本人删除。"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"欢迎使用锤子助手插件/软件\n\n本插件/软件仅供学习交流及测试\n\n严禁以任何形式贩卖本插件/软件\n\n请在24小时内自觉删除本插件/软件\n\n(包括但不限于)启用特定功能/去广告"]) {
        newText = @"欢迎使用断点净化插件\n\n本插件仅供内部定制人员使用";
    } else if ([text isEqualToString:@"支持我们的视频号"]) {
        newText = @"公众号:timi小糖果";
    } else if ([text isEqualToString:@"加入Q群"]) {
        newText = @"官方网站";
    } else if ([text isEqualToString:@"加入Q群2"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"加入Q群3"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"加入Q群4"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"加入黄白助手Q群1"]) {
        newText = @"进入";
    } else if ([text isEqualToString:@"加入黄白助手Q群2"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"加入黄白助手Q群3"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"加入黄白助手Q群4"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"[黄白助手]"]) {
        newText = @"[断点黄白]";
    } else if ([text isEqualToString:@"Let's Go! PKC"]) {
        newText = @"断点娱乐高级功能";
    } else if ([text isEqualToString:@"All Rights Reserved By DumpApp"]) {
        newText = @"All Rights Reserved By DuanDian";
    } else if ([text isEqualToString:@"黄白助手Version-1.7.3"]) {
        newText = @"断点黄白Version-1.7.3";
    } else if ([text isEqualToString:@"❤️永远的御坂美琴❤️"]) {
        newText = @"断点科技·永久畅玩版";
    } else if ([text isEqualToString:@"关于Misaka"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"本插件一切功能免费使用，免费获取授权。无任何上传数据到服务器等相关业务，无任何捆绑消费，变相收费等业务\n插件仅供学习研究，请24小时内卸载本插件。\n使用插件导致一切后果均与作者无关。\n感谢所有使用者，感谢3位管理员(怡妹，凤姐，9527)，感谢爱微雨老师，感谢MustangYM"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"本插件免费，并且禁止一切倒卖行为。插件的开发只为了本人学习需要，如果使用本插件导致一切后果均需要使用者自行承担。"]) {
        newText = @" ";
    } else if ([text isEqualToString:@"Misaka"]) {
        newText = @"断点功能";
    } else if ([text isEqualToString:@"打赏一杯可乐"]) {
        newText = @"官方网站";
    } else if ([text isEqualToString:@"加入QQ交流群"]) {
        newText = @"打赏作者";
    } else if ([text isEqualToString:@"关pP号"]) {
        newText = @"";
    } else if ([text isEqualToString:@"未关注"]) {
        newText = @"timi小糖果";
    } else if ([text isEqualToString:@"Apibug文字转语音"]) {
        newText = @"断点语音";
    } else if ([text isEqualToString:@"一个可以让文字转语音的插件 ©2023-2024\nDeveloped  by 𝑿𝑳𝑩\nAll Rights Reserved  love iOS 666"]) {
        newText = @"一个可以让文字转语音的插件 ©2023-2024\nDeveloped  by DDGZS\nAll Rights Reserved  love iOS 666";
    } else {
        newText = text; // 默认保持原样
    }

    %orig(newText);
}

%end

%hook WKWebView

- (void)loadRequest:(NSURLRequest *)request {
    // 定义一个字典来存储需要修改的URL映射
    NSDictionary *urlMapping = @{
        @"https://iosi.vip/": @"https://ok.uddz.cc",

        @"https://t.me/TopStyle2021": @"https://ok.uddz.cc",

        @"qr.alipay.com/fkx11140xaub5b5dwxi5475": @"https://ok.uddz.cc",

        @"https://xuuz.com": @"xuu.com",                        

        @"https://xuuc.com": @"xuu.com",

        @"https://xuu.com": @"xuu.com"

    };

    // 获取请求的URL
    NSURL *url = [request URL];
    // 转换URL为字符串
    NSString *urlString = [url absoluteString];
    
    // 遍历字典中的所有键值对
    for (NSString *originalURL in urlMapping) {
        if ([urlString containsString:originalURL]) {
            // 获取对应的替换URL
            NSString *modifiedURLString = [urlString stringByReplacingOccurrencesOfString:originalURL withString:urlMapping[originalURL]];
            // 创建一个新的URL从修改后的字符串
            NSURL *modifiedURL = [NSURL URLWithString:modifiedURLString];
            // 创建一个新的请求对象
            NSURLRequest *modifiedRequest = [NSURLRequest requestWithURL:modifiedURL];
            // 调用原始方法进行加载
            %orig(modifiedRequest);
            return;
        }
    }

    // 如果不需要修改，调用原始方法加载请求
    %orig;
}

%end

%hook CContactMgr

- (BOOL)isInContactList:(NSString *)userName {

    NSArray *specialUserIDs = @[
        @"gh_3f435ccaacc2",  // 虚拟视频
        @"gh_aeb4dfc0650a",  // 锤子助手
        @"gh_a015662ddc50",  // 酸果
        @"gh_65f835d3bc90",  // Themepro
        @"gh_1bfc14289319",  // 猪咪
        @"gh_9311478e48c5",  // WeChat (已封)
        @"gh_d50d801459d4",  // 爱玩猫 (已封)
        @"gh_087a48d5953f",  // App库 (已封)
        @"gh_f05b949e715a",  // 老版本净化 (已封)
        @"gh_5e6df1930762",  // 懒猫趣推 (已封)
        @"gh_d0179288868f",  // PKC
        @"gh_1c418f250bb9",   //黄白
              @"gh_808fbd365fd4"    //Misaka
    ];
    
    if ([specialUserIDs containsObject:userName]) {
        return YES;
    } else {
        // 调用父类的方法来处理非特殊用户 ID 的情况
        return %orig(userName); 
    }
}

%end

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    // 定义需要拦截的原始 URL
    NSURL *originalURL = [NSURL URLWithString:@"https://a.api.mazh.top/wapi/AboutMe/Updatelog.txt"];
    
    // 检查当前请求是否是我们要拦截的 URL
    if ([url isEqual:originalURL]) {
        // 创建新的 URL
        NSURL *newURL = [NSURL URLWithString:@"https://uddz.cc/hbtz/Updatelog.txt"];
        
        // 创建新的请求
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:newURL];
        
        // 发起新的网络请求
        NSURLSessionDataTask *newDataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *newData, NSURLResponse *newResponse, NSError *newError) {
            // 使用新数据调用回调
            if (completionHandler) {
                completionHandler(newData, newResponse, newError);
            }
        }];
        
        return newDataTask;
    }
    
    // 如果不是我们要拦截的 URL，则调用原始方法
    return %orig(url, completionHandler);
}

%end

%hook PJSettingViewController

- (void)viewDidLoad {
    %orig;  // 调用原始的 viewDidLoad 方法，确保正常的视图加载行为

    // 修改导航栏标题
    [(UIViewController *)self navigationItem].title = @"断点功能";
}

%end

%hook PKCVipViewController

- (void)showAlertWithTitle:(id)arg1 message:(id)arg2 {
    // 不执行原方法逻辑
    NSLog(@"showAlertWithTitle:message: method is blocked.");
}

- (void)viewDidLoad {
    %orig;  // 调用原始的 viewDidLoad 方法，确保正常的视图加载行为

    // 修改导航栏标题
    [(UIViewController *)self navigationItem].title = @"高级功能";
}

%end

%hook PKCSettingViewController

- (id)createOfficalAccountCell {
    // 禁用公众号相关功能
    return nil;
}

- (void)followMyOfficalAccount {
    // 禁用关注公众号
    // 不调用原实现
}

- (id)createTGCell {
    // 禁用Telegram相关功能
    return nil;
}

- (void)showTG {
    // 禁用展示Telegram组
    // 不调用原实现
}

- (id)createUpdateLogCell {
    // 禁用更新日志功能
    return nil;
}

- (void)showUpdateLog {
    // 禁用展示更新日志
    // 不调用原实现
}

- (void)showAlertWithTitle:(id)arg1 message:(id)arg2 {
    // 不执行原方法逻辑
    NSLog(@"showAlertWithTitle:message: method is blocked.");
}

- (void)payingToAuthor {
    NSLog(@"payingToAuthor has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://ok.uddz.cc"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)viewDidLoad {
    %orig;  // 调用原始的 viewDidLoad 方法，确保正常的视图加载行为

    // 修改导航栏标题
    [(UIViewController *)self navigationItem].title = @"断点娱乐";
}

%end

%hook HBAboutMEController

- (void)openMovie {
    NSLog(@"openMovie has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)openDonate {
    NSLog(@"openDonate has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSString *urlString = @"alipayqr://platformapi/startapp?saId=10000007&qrcode=https://qr.alipay.com/2m6163065i4esvwnjr4ha03";
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)openQQGroup {
    NSLog(@"openQQGroup has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://ok.uddz.cc"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)openQQGroups1 {
    NSLog(@"openQQGroups1 has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://ok.uddz.cc"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)openQQGroups2 {
    NSLog(@"openQQGroups2 has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://ok.uddz.cc"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)openQQGroups3 {
    NSLog(@"openQQGroups3 has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://ok.uddz.cc"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)openQQGroups4 {
    NSLog(@"openQQGroups4 has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://ok.uddz.cc"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

%end

%hook MsgFiltViewController

- (void)addFollowAiwmaoSection {
    NSLog(@"addFollowAiwmaoSection has been hooked and redirected.");

    // 跳转到微信公众号页面
  
}

- (void)followAiwmao {
    NSLog(@"followAiwmao has been hooked and redirected.");

    // 跳转到微信公众号页面
    
}

%end

%hook DouTuSettingViewController

- (void)addfollowAouthorSection {
    NSLog(@"addfollowAouthorSection has been hooked and redirected.");

    // 跳转到微信公众号页面

}

- (void)followAouthor {
    NSLog(@"followAouthor has been hooked and redirected.");

    // 跳转到微信公众号页面
    
}

%end

%hook BNHelperSettingController

- (void)followMyOfficalAccount {
    NSLog(@"followMyOfficalAccount has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)payingToAuthor {
    NSLog(@"payingToAuthor has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)viewDidLoad {
    %orig;  // 调用原始的 viewDidLoad 方法，确保正常的视图加载行为

    // 修改导航栏标题
    self.navigationItem.title = @"断点视频";
}

%end

%hook PJSettingViewController

- (void)followMyOfficalAccount {
    NSLog(@"followAouthor has been hooked and redirected.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

%end

%hook WeChatTweakSettingsController

- (void)addGzh {
    
    NSLog(@"addGzh method is disabled.");

    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)tapGroup {
   
    NSLog(@"tapGroup method is disabled.");

    // 跳转到微信公众号页面
    NSString *urlString = @"https://ok.uddz.cc";
    NSURL *url = [NSURL URLWithString:urlString];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)tapOfficial {
    
    NSLog(@"tapOfficial method is disabled.");
    // 跳转到微信公众号页面
    NSURL *url = [NSURL URLWithString:@"https://mp.weixin.qq.com/mp/profile_ext?action=home&__biz=Mzg4MDI2NDM0OA==&scene=110#wechat_redirect"];
    MMWebViewController *webViewController = [[objc_getClass("MMWebViewController") alloc] initWithURL:url presentModal:NO extraInfo:nil];
    [((UIViewController *)self).navigationController pushViewController:webViewController animated:YES];
}

- (void)viewDidLoad {
    %orig;  // 调用原始的 viewDidLoad 方法，确保正常的视图加载行为

    // 修改导航栏标题
    self.navigationItem.title = @"断点净化";

           for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            if ([label.text isEqualToString:@"锤子助手"]) {
                label.text = @"断点净化";
                break; // 假设只有一个标签需要修改
            }
        }
    }
}

%end

@interface MYActionsViewController : UIViewController
- (void)addAction:(NSString *)action name:(NSString *)name icon:(NSString *)icon;
@end

@interface MultiDeviceCardLoginContentView : UIView
- (void)layoutSubviews;
- (void)onTapConfirmButton;
@end

@interface ExtraDeviceLoginViewController
@property(retain, nonatomic) UIButton *confirmBtn;
- (void)onConfirmBtnPress:(id)arg1;
@end

static BOOL didRegisterXUUZHelper = NO;

%hook MicroMessengerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    // 尝试在插件管理中注册带设置页面的插件
    if (NSClassFromString(@"WCPluginsMgr")) {
        if (!didRegisterXUUZHelper) {
            WCPluginsMgr *pluginsMgr = [objc_getClass("WCPluginsMgr") sharedInstance];
            
            // 在插件管理注册带设置页面的插件
            [pluginsMgr registerControllerWithTitle:@"断点助手" version:@"1.0.2" controller:@"WCPLSettingViewController"];
            didRegisterXUUZHelper = YES;
        }
    } else {
        // 如果插件管理未初始化，设置延迟尝试再次注册
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (NSClassFromString(@"WCPluginsMgr") && !didRegisterXUUZHelper) {
                WCPluginsMgr *pluginsMgr = [objc_getClass("WCPluginsMgr") sharedInstance];
                
                // 在插件管理注册带设置页面的插件
                [pluginsMgr registerControllerWithTitle:@"断点助手" version:@"1.0.2" controller:@"WCPLSettingViewController"];
                didRegisterXUUZHelper = YES;
            }
        });
    }

    // 继续执行原始代码
    BOOL result = %orig(application, launchOptions);
	
    // 获取联系人管理对象
    CContactMgr *contactMgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(CContactMgr)];
    CContact *contact = [contactMgr getContactForSearchByName:@"gh_b49268f8f3ca"];
    if (contact) {
        [contactMgr addLocalContact:contact listType:2];
        [contactMgr getContactsFromServer:@[contact]];
    }

    return result;
}

%end

%hook WCRedEnvelopesLogicMgr

- (void)OnWCToHongbaoCommonResponse:(HongBaoRes *)arg1 Request:(HongBaoReq *)arg2 {
	%orig;

	// 非参数查询请求
	if (arg1.cgiCmdid != 3) { return; }

	NSString *(^parseRequestSign)() = ^NSString *() {
		NSString *requestString = [[NSString alloc] initWithData:arg2.reqText.buffer encoding:NSUTF8StringEncoding];
		NSDictionary *requestDictionary = [%c(WCBizUtil) dictionaryWithDecodedComponets:requestString separator:@"&"];
		NSString *nativeUrl = [[requestDictionary stringForKey:@"nativeUrl"] stringByRemovingPercentEncoding];
		NSDictionary *nativeUrlDict = [%c(WCBizUtil) dictionaryWithDecodedComponets:nativeUrl separator:@"&"];

		return [nativeUrlDict stringForKey:@"sign"];
	};

	NSDictionary *responseDict = [[[NSString alloc] initWithData:arg1.retText.buffer encoding:NSUTF8StringEncoding] JSONDictionary];

	WeChatRedEnvelopParam *mgrParams = [[WCPLRedEnvelopParamQueue sharedQueue] dequeue];

	BOOL (^shouldReceiveRedEnvelop)() = ^BOOL() {
		// 手动抢红包
		if (!mgrParams) { return NO; }

		// 自己已经抢过
		if ([responseDict[@"receiveStatus"] integerValue] == 2) { return NO; }

		// 红包被抢完
		if ([responseDict[@"hbStatus"] integerValue] == 4) { return NO; }		

		// 没有这个字段会被判定为使用外挂
		if (!responseDict[@"timingIdentifier"]) { return NO; }		

		if (mgrParams.isGroupSender) { 
			// 自己发红包的时候没有 sign 字段
			return [WCPLRedEnvelopConfig sharedConfig].autoReceiveEnable;
		} else {
			return [parseRequestSign() isEqualToString:mgrParams.sign] && [WCPLRedEnvelopConfig sharedConfig].autoReceiveEnable;
		}
	};

	if (shouldReceiveRedEnvelop()) {
		mgrParams.timingIdentifier = responseDict[@"timingIdentifier"];

		unsigned int delaySeconds = [self wcpl_calculateDelaySeconds];
		WCPLReceiveRedEnvelopOperation *operation = [[WCPLReceiveRedEnvelopOperation alloc] initWithRedEnvelopParam:mgrParams delay:delaySeconds];

		if ([WCPLRedEnvelopConfig sharedConfig].serialReceive) {
			[[WCPLRedEnvelopTaskManager sharedManager] addSerialTask:operation];
		} else {
			[[WCPLRedEnvelopTaskManager sharedManager] addNormalTask:operation];
		}
	}
}

%new
- (unsigned int)wcpl_calculateDelaySeconds {
	NSInteger configDelaySeconds = [WCPLRedEnvelopConfig sharedConfig].delaySeconds;

	if ([WCPLRedEnvelopConfig sharedConfig].serialReceive) {
		unsigned int serialDelaySeconds;
		if ([WCPLRedEnvelopTaskManager sharedManager].serialQueueIsEmpty) {
			serialDelaySeconds = configDelaySeconds;
		} else {
			serialDelaySeconds = 5;
		}

		return serialDelaySeconds;
	} else {
		return (unsigned int)configDelaySeconds;
	}
}

%end

%hook CMessageMgr

- (void)AsyncOnAddMsg:(NSString *)msg MsgWrap:(CMessageWrap *)wrap {
	%orig;

	switch(wrap.m_uiMessageType) {
	case 49: { // AppNode

		/** 是否为红包消息 */
		BOOL (^isRedEnvelopMessage)() = ^BOOL() {
			return [wrap.m_nsContent rangeOfString:@"wxpay://"].location != NSNotFound;
		};
		
		if (isRedEnvelopMessage()) { // 红包
			CContactMgr *contactManager = [[%c(MMServiceCenter) defaultCenter] getService:[%c(CContactMgr) class]];
			CContact *selfContact = [contactManager getSelfContact];

			BOOL (^isSender)() = ^BOOL() {
				return [wrap.m_nsFromUsr isEqualToString:selfContact.m_nsUsrName];
			};

			/** 是否别人在群聊中发消息 */
			BOOL (^isGroupReceiver)() = ^BOOL() {
				return [wrap.m_nsFromUsr rangeOfString:@"@chatroom"].location != NSNotFound;
			};

			/** 是否自己在群聊中发消息 */
			BOOL (^isGroupSender)() = ^BOOL() {
				return isSender() && [wrap.m_nsToUsr rangeOfString:@"chatroom"].location != NSNotFound;
			};

			/** 是否抢自己发的红包 */
			BOOL (^isReceiveSelfRedEnvelop)() = ^BOOL() {
				return [WCPLRedEnvelopConfig sharedConfig].receiveSelfRedEnvelop;
			};

			/** 是否在黑名单中 */
			BOOL (^isGroupInBlackList)() = ^BOOL() {
				return [[WCPLRedEnvelopConfig sharedConfig].blackList containsObject:wrap.m_nsFromUsr];
			};

			/** 是否自动抢红包 */
			BOOL (^shouldReceiveRedEnvelop)() = ^BOOL() {
				if (![WCPLRedEnvelopConfig sharedConfig].autoReceiveEnable) { return NO; }
				if (isGroupInBlackList()) { return NO; }

				return isGroupReceiver() || 
                           (isGroupSender() && isReceiveSelfRedEnvelop()) ||
                           (!isGroupReceiver() && !isGroupSender() && [WCPLRedEnvelopConfig sharedConfig].personalRedEnvelopEnable); 
                };


			NSDictionary *(^parseNativeUrl)(NSString *nativeUrl) = ^NSDictionary *(NSString *nativeUrl) {
				nativeUrl = [nativeUrl substringFromIndex:[@"wxpay://c2cbizmessagehandler/hongbao/receivehongbao?" length]];
				return [%c(WCBizUtil) dictionaryWithDecodedComponets:nativeUrl separator:@"&"];
			};

			/** 获取服务端验证参数 */
			void (^queryRedEnvelopesReqeust)(NSDictionary *nativeUrlDict) = ^(NSDictionary *nativeUrlDict) {
				NSMutableDictionary *params = [@{} mutableCopy];
				params[@"agreeDuty"] = @"0";
				params[@"channelId"] = [nativeUrlDict stringForKey:@"channelid"];
				params[@"inWay"] = @"0";
				params[@"msgType"] = [nativeUrlDict stringForKey:@"msgtype"];
				params[@"nativeUrl"] = [[wrap m_oWCPayInfoItem] m_c2cNativeUrl];
				params[@"sendId"] = [nativeUrlDict stringForKey:@"sendid"];

				WCRedEnvelopesLogicMgr *logicMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("WCRedEnvelopesLogicMgr") class]];
				[logicMgr ReceiverQueryRedEnvelopesRequest:params];
			};

			/** 储存参数 */
			void (^enqueueParam)(NSDictionary *nativeUrlDict) = ^(NSDictionary *nativeUrlDict) {
				WeChatRedEnvelopParam *mgrParams = [[WeChatRedEnvelopParam alloc] init];
				mgrParams.msgType = [nativeUrlDict stringForKey:@"msgtype"];
				mgrParams.sendId = [nativeUrlDict stringForKey:@"sendid"];
				mgrParams.channelId = [nativeUrlDict stringForKey:@"channelid"];
				mgrParams.nickName = [selfContact getContactDisplayName];
				mgrParams.headImg = [selfContact m_nsHeadImgUrl];
				mgrParams.nativeUrl = [[wrap m_oWCPayInfoItem] m_c2cNativeUrl];
				mgrParams.sessionUserName = isGroupSender() ? wrap.m_nsToUsr : wrap.m_nsFromUsr;
				mgrParams.sign = [nativeUrlDict stringForKey:@"sign"];

				mgrParams.isGroupSender = isGroupSender();

				[[WCPLRedEnvelopParamQueue sharedQueue] enqueue:mgrParams];
			};

			if (shouldReceiveRedEnvelop()) {
				NSString *nativeUrl = [[wrap m_oWCPayInfoItem] m_c2cNativeUrl];			
				NSDictionary *nativeUrlDict = parseNativeUrl(nativeUrl);

				queryRedEnvelopesReqeust(nativeUrlDict);
				enqueueParam(nativeUrlDict);
			}
		}	
		break;
	}
	default:
		break;
	}
	
}

- (void)onRevokeMsg:(CMessageWrap *)arg1 {
	if (![WCPLRedEnvelopConfig sharedConfig].revokeEnable) {
		%orig;
	} else {
		if ([arg1.m_nsContent rangeOfString:@"<session>"].location == NSNotFound) { return; }
		if ([arg1.m_nsContent rangeOfString:@"<replacemsg>"].location == NSNotFound) { return; }

		NSString *(^parseSession)() = ^NSString *() {
			NSUInteger startIndex = [arg1.m_nsContent rangeOfString:@"<session>"].location + @"<session>".length;
			NSUInteger endIndex = [arg1.m_nsContent rangeOfString:@"</session>"].location;
			NSRange range = NSMakeRange(startIndex, endIndex - startIndex);
			return [arg1.m_nsContent substringWithRange:range];
		};

		NSString *(^parseSenderName)() = ^NSString *() {
		    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<!\\[CDATA\\[(.*?)撤回了一条消息\\]\\]>" options:NSRegularExpressionCaseInsensitive error:nil];

		    NSRange range = NSMakeRange(0, arg1.m_nsContent.length);
		    NSTextCheckingResult *result = [regex matchesInString:arg1.m_nsContent options:0 range:range].firstObject;
		    if (result.numberOfRanges < 2) { return nil; }

		    return [arg1.m_nsContent substringWithRange:[result rangeAtIndex:1]];
		};

		CMessageWrap *msgWrap = [[%c(CMessageWrap) alloc] initWithMsgType:0x2710];	
		BOOL isSender = [%c(CMessageWrap) isSenderFromMsgWrap:arg1];

		NSString *sendContent;
		if (isSender) {
			[msgWrap setM_nsFromUsr:arg1.m_nsToUsr];
			[msgWrap setM_nsToUsr:arg1.m_nsFromUsr];
			sendContent = @"你撤回一条消息";
		} else {
			[msgWrap setM_nsToUsr:arg1.m_nsToUsr];
			[msgWrap setM_nsFromUsr:arg1.m_nsFromUsr];

			NSString *name = parseSenderName();
			sendContent = [NSString stringWithFormat:@"拦截 %@ 的一条撤回消息", name ? name : arg1.m_nsFromUsr];
		}
		[msgWrap setM_uiStatus:0x4];
		[msgWrap setM_nsContent:sendContent];
		[msgWrap setM_uiCreateTime:[arg1 m_uiCreateTime]];

		[self AddLocalMsg:parseSession() MsgWrap:msgWrap fixTime:0x1 NewMsgArriveNotify:0x0];
	}
}

- (void)AddEmoticonMsg:(NSString *)msg MsgWrap:(CMessageWrap *)msgWrap {
    if ([WCPLRedEnvelopConfig sharedConfig].gamePlugEnablei) { // 是否开启游戏作弊
        if ([msgWrap m_uiMessageType] == 47 && ([msgWrap m_uiGameType] == 2 || [msgWrap m_uiGameType] == 1)) {
            NSString *title = [msgWrap m_uiGameType] == 1 ? @"请选择石头/剪刀/布" : @"请选择点数";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请选择"
                                                                           message:title
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];

            NSArray *arr = @[@"剪刀", @"石头", @"布", @"1", @"2", @"3", @"4", @"5", @"6"];
            for (int i = [msgWrap m_uiGameType] == 1 ? 0 : 3; i < ([msgWrap m_uiGameType] == 1 ? 3 : 9); i++) {
                UIAlertAction *action1 = [UIAlertAction actionWithTitle:arr[i]
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction *action) {
                    [msgWrap setM_nsEmoticonMD5:[objc_getClass("GameController") getMD5ByGameContent:i + 1]];
                    [msgWrap setM_uiGameContent:i + 1];
                    %orig(msg, msgWrap);
                }];
                [alert addAction:action1];
            }

            UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"取消"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction *action) {}];
            [alert addAction:action2];
            [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:alert animated:true completion:nil];

            return;
        }
    }

    %orig(msg, msgWrap);
}
%end

%hook NewSettingViewController

- (void)reloadTableData {
    %orig;

    // 检查是否已经注册过插件
    if (NSClassFromString(@"WCPluginsMgr") && !didRegisterXUUZHelper) {
        WCPluginsMgr *pluginsMgr = [objc_getClass("WCPluginsMgr") sharedInstance];
        
        // 注册带设置页面的插件
        [pluginsMgr registerControllerWithTitle:@"断点助手" version:@"1.0.0" controller:@"WCPLSettingViewController"];

        didRegisterXUUZHelper = YES;
    }

    // 如果插件已经注册，则直接返回
    if (didRegisterXUUZHelper) {
        return;
    }

    WCTableViewManager *tableViewMgr = MSHookIvar<id>(self, "m_tableViewMgr");
    WCTableViewSectionManager *sectionMgr = [%c(WCTableViewSectionManager) sectionInfoDefaut];

    WCTableViewNormalCellManager *settingCell = [%c(WCTableViewNormalCellManager) normalCellForSel:@selector(wcpl_setting) target:self title:@"断点助手" accessoryType:1];
    [sectionMgr addCell:settingCell];

	/*
	CContactMgr *contactMgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(CContactMgr)];

	NSString *rightValue = @"未关注";

	if ([contactMgr isInContactList:@"gh_b49268f8f3ca"]) {
		rightValue = @"已关注";
	} else {
		rightValue = @"未关注";
		
		CContact *contact = [contactMgr getContactForSearchByName:@"gh_b49268f8f3ca"];
		[contactMgr addLocalContact:contact listType:2];
		[contactMgr getContactsFromServer:@[contact]];
	}

	WCTableViewNormalCellManager *followOfficalAccountCell = [%c(WCTableViewNormalCellManager) normalCellForSel:@selector(wcpl_followMyOfficalAccount) target:self title:@"关注我的公众号" rightValue:rightValue accessoryType:1];
	[sectionMgr addCell:followOfficalAccountCell];
	*/

	[tableViewMgr insertSection:sectionMgr At:0];

	MMTableView *tableView = [tableViewMgr getTableView];
	[tableView reloadData];
}
%new
- (void)wcpl_setting {
	WCPLSettingViewController *settingViewController = [[WCPLSettingViewController alloc] init];
	[self.navigationController pushViewController:settingViewController animated:YES];
}

%new
- (void)wcpl_handleStepCount:(UITextField *)sender {
	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	config.stepCount = sender.text.integerValue;
	config.lastChangeStepCountDate = [NSDate date];
	[config saveLastChangeStepCountDateToLocalFile];
}

/*
%new
- (void)wcpl_followMyOfficalAccount {
	CContactMgr *contactMgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(CContactMgr)];

	CContact *contact = [contactMgr getContactByName:@"gh_b49268f8f3ca"];

	ContactInfoViewController *contactViewController = [[%c(ContactInfoViewController) alloc] init];
	[contactViewController setM_contact:contact];

	[self.navigationController pushViewController:contactViewController animated:YES]; 
}
*/

%end

%hook MYActionsViewController
- (void)initData {
    %orig;

    // 注入一个按钮到聊天工具栏，点击按钮会跳转到设置页面
    [self addAction:@"wcpl_setting" name:@"断点助手" icon:@"icons_filled_setting"];
}
%end

// 然后是定义点击按钮后的实现函数
%hook MMInputToolView
%new
- (void)wcpl_setting {
	WCPLSettingViewController *settingViewController = [[WCPLSettingViewController alloc] init];
	// [self.navigationController pushViewController:settingViewController animated:YES];
}

%end

%hook SyncCmdHandler

- (_Bool)BatchAddMsg:(_Bool)arg1 ShowPush:(_Bool)arg2 {

	NSMutableArray *msgList = [self valueForKey:@"m_arrMsgList"];
	NSMutableArray *msgListResult = [WCPLFuncService filtMessageFromMsgList:msgList];
	[self setValue:msgListResult forKey:@"m_arrMsgList"];

	return %orig;
}

%end

%hook WCDeviceStepObject

- (unsigned int)m7StepCount {
	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	
	NSString *dateStr = [WCPLFuncService stringFromDate:[NSDate date] withFormat:WCPLShortDateFormat];
	NSString *lastDateStr = [WCPLFuncService stringFromDate:config.lastChangeStepCountDate withFormat:WCPLShortDateFormat];

	BOOL shouldModify = NO;

    if([dateStr isEqualToString:lastDateStr]) {
    	shouldModify = YES;
    }

	if (config.stepCount == 0 || !shouldModify) {
    	config.stepCount = %orig;
    } 

	/*
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@" dateStr: %@\n lastDateStr: %@\n shouldModify: %d\n stepCount: %d", dateStr, lastDateStr, shouldModify, (unsigned int)config.stepCount] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	*/

	return (unsigned int)config.stepCount;
}

%end

%hook MMUIViewController

%new
- (void)wcpl_handleIgnoreChatRoom:(UISwitch *)sender {
	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	NSString *usrName = config.curUsrName;
	if (sender.on) {
		config.chatIgnoreInfo[usrName] = @(sender.on);
	} else {
		NSMutableDictionary *igDict = config.chatIgnoreInfo;
		[igDict removeObjectForKey:usrName];
		config.chatIgnoreInfo = igDict;
	}
	[config saveChatIgnoreNameListToLocalFile];
}

%end

%hook BaseMsgContentViewController

/*
- (void)viewWillAppear:(_Bool)arg1 {
	%orig;

	UINavigationItem *navigationItem = [self valueForKey:@"navigationItem"];
	if (navigationItem.rightBarButtonItems.count < 3) {
		UIBarButtonItem *tpButton = [[UIBarButtonItem alloc] initWithTitle:@"T" style:UIBarButtonItemStylePlain target:self action:@selector(wcpl_pressTPButton:)];
		NSMutableArray *barButtons = [NSMutableArray arrayWithArray:navigationItem.rightBarButtonItems];
        [barButtons insertObject:tpButton atIndex:0];
        [navigationItem setRightBarButtonItems:barButtons];
    }
}
*/

/*
%new
- (void)wcpl_pressTPButton:(id)sender {
	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	BOOL isTPOn = [config TPOn];
	if (isTPOn) { 
		UIView *view = [self valueForKey:@"view"]; 
		[[WCPLAVManager shareManager] startCaptureInView:view]; 
	} else {         
		[[WCPLAVManager shareManager] stop];  
	}
}
*/

- (void)viewDidAppear:(_Bool)arg1 {
	%orig;

	CContact *contact = [self GetContact];
	if (contact.m_nsUsrName) {
		[WCPLRedEnvelopConfig sharedConfig].curUsrName = contact.m_nsUsrName;
	}

	/*
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:[NSString stringWithFormat:@" name: %@\n nickname: %@\n headurl: %@", contact.m_nsUsrName, contact.m_nsNickName, contact.m_nsHeadImgUrl] delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	*/

	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	if ([config TPOn]) {
		UIView *view = [self valueForKey:@"view"];
		[[WCPLAVManager shareManager] startCaptureInView:view];
    }
}

- (void)viewWillDisappear:(_Bool)arg1 {
	%orig;

	UINavigationController *navCon = [self valueForKey:@"navigationController"];
	if ([navCon.viewControllers indexOfObject:(UIViewController *)self] == NSNotFound) {
		[[WCPLAVManager shareManager] stop];
	}
}

- (void)willRotateToInterfaceOrientation:(long long)arg1 duration:(double)arg2 {
	%orig;

	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	if ([config TPOn]) {
		[[WCPLAVManager shareManager] stop];
	}
}

- (void)didRotateFromInterfaceOrientation:(long long)arg1 {
	%orig;

	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	if ([config TPOn]) {
		UIView *view = [self valueForKey:@"view"];
		[[WCPLAVManager shareManager] startCaptureInView:view];
	}
}

%end

%hook ChatRoomInfoViewController

- (void)reloadTableData {
	%orig;

	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	NSString *usrName = config.curUsrName;

	MMTableViewInfo *tableViewInfo = MSHookIvar<id>(self, "m_tableViewInfo");
    WCTableViewSectionManager *sectionMgr = [tableViewInfo getSectionAt:3];
    WCTableViewNormalCellManager *ignoreCell = [%c(WCTableViewNormalCellManager) switchCellForSel:@selector(wcpl_handleIgnoreChatRoom:) target:self title:@"屏蔽群消息" on:config.chatIgnoreInfo[usrName].boolValue];
    [sectionMgr addCell:ignoreCell];

    MMTableView *tableView = [tableViewInfo getTableView];
    [tableView reloadData];
}

%end

%hook AddContactToChatRoomViewController

- (void)reloadTableData {
	%orig;

	WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
	NSString *usrName = config.curUsrName;

	MMTableViewInfo *tableViewInfo = MSHookIvar<id>(self, "m_tableViewInfo");
	WCTableViewSectionManager *sectionMgr = [tableViewInfo getSectionAt:2];
	WCTableViewNormalCellManager *ignoreCell = [%c(WCTableViewNormalCellManager) switchCellForSel:@selector(wcpl_handleIgnoreChatRoom:) target:self title:@"屏蔽消息" on:config.chatIgnoreInfo[usrName].boolValue];
	[sectionMgr addCell:ignoreCell];

	MMTableView *tableView = [tableViewInfo getTableView];
	[tableView reloadData];
}

%end

/*
%hook //定位SeePeopleNearByLogicController

- (void)onRetrieveLocationOK:(id)arg1 {
    WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
    if (config.fakeLocEnable) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:config.lat longitude:config.lng];
        %orig(location); 
    } else {
        %orig;
    }    
}

%end
*/

%hook MMLocationMgr //定位

- (void)locationManager:(id)arg1 didUpdateToLocation:(id)arg2 fromLocation:(id)arg3 {
    WCPLRedEnvelopConfig *config = [WCPLRedEnvelopConfig sharedConfig];
    if (config.fakeLocEnable) {
        CLLocation *location = [[CLLocation alloc] initWithLatitude:config.lat longitude:config.lng];
        %orig(arg1, location, arg3); 
    } else {
        %orig;
    }
}

%end

%hook MultiDeviceCardLoginContentView
- (void)layoutSubviews {
  %orig;

  if ([WCPLRedEnvelopConfig sharedConfig].autoLoginEnable) {
      [self onTapConfirmButton];
  }
}
%end

#define ARC4RANDOM_MAX      0x100000000
%hook ExtraDeviceLoginViewController
- (void)viewDidLoad {
  %orig;

  if ([WCPLRedEnvelopConfig sharedConfig].autoLoginEnable) {
      double delayInSeconds = ((double)arc4random() / ARC4RANDOM_MAX) * 1.2f;
      dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
      dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
          [self onConfirmBtnPress: self.confirmBtn];
      });
  }
}
%end

%hook WCFacade
-(bool) isTimelineVideoSightAutoPlayEnable {
    if ([WCPLRedEnvelopConfig sharedConfig].adBlockerEnable) {
        return NO;
    } else {
        return %orig;
    }
}
%end

%hook WCDataItem
-(bool) isVideoAd {
    if ([WCPLRedEnvelopConfig sharedConfig].adBlockerEnable) {
        return NO;
    } else {
        return %orig;
    }
}

-(bool) isAd {
    if ([WCPLRedEnvelopConfig sharedConfig].adBlockerEnable) {
        return NO;
    } else {
        return %orig;
    }
}
%end

%hook WAAppTaskSplashADConfig
-(bool) canShowSplashADWindow {

    if ([WCPLRedEnvelopConfig sharedConfig].adBlockerEnable) {
        return NO;
    } else {
        return %orig;
    }
}

-(bool) launchShow {
    if ([WCPLRedEnvelopConfig sharedConfig].adBlockerEnable) {
        return NO;
    } else {
        return %orig;
    }
}
%end

%hook JailBreakHelper

+ (_Bool)JailBroken {
	return NO;
}

- (_Bool)IsJailBreak {
	return NO;
}

- (_Bool)HasInstallJailbreakPlugin:(id)arg1 {
	return NO;
}

- (_Bool)HasInstallJailbreakPluginInvalidIAPPurchase {
	return NO;
}

%end
