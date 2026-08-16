#import "DYYYOptionsSelectionView.h"
#import <objc/runtime.h>
#import "AwemeHeaders.h"
#import "DYYYUtils.h"

@implementation DYYYOptionsSelectionView

static UIColor *DYYYThemeColor(UIColor *darkColor, UIColor *lightColor, BOOL darkMode) {
    return darkMode ? darkColor : lightColor;
}

static UIColor *DYYYSelectionSheetBackgroundColor(BOOL darkMode) {
    return DYYYThemeColor([UIColor colorWithRed:29 / 255.0 green:31 / 255.0 blue:42 / 255.0 alpha:1.0], [UIColor whiteColor], darkMode);
}

static UIColor *DYYYSelectionSheetTextColor(BOOL darkMode) {
    return DYYYThemeColor([UIColor colorWithWhite:1.0 alpha:0.95], [UIColor colorWithRed:22 / 255.0 green:24 / 255.0 blue:35 / 255.0 alpha:1.0], darkMode);
}

static UIColor *DYYYSelectionSheetSeparatorColor(BOOL darkMode) {
    return DYYYThemeColor([UIColor colorWithRed:60 / 255.0 green:60 / 255.0 blue:60 / 255.0 alpha:1.0], [UIColor colorWithRed:230 / 255.0 green:230 / 255.0 blue:230 / 255.0 alpha:1.0], darkMode);
}

static BOOL DYYYColorGetRGBA(UIColor *color, CGFloat *red, CGFloat *green, CGFloat *blue, CGFloat *alpha) {
    if ([color getRed:red green:green blue:blue alpha:alpha]) {
        return YES;
    }

    CGFloat white = 0.0;
    if ([color getWhite:&white alpha:alpha]) {
        *red = white;
        *green = white;
        *blue = white;
        return YES;
    }

    return NO;
}

static BOOL DYYYColorIsLight(UIColor *color) {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    if (!DYYYColorGetRGBA(color, &red, &green, &blue, &alpha) || alpha < 0.01) {
        return NO;
    }

    CGFloat luminance = 0.299 * red + 0.587 * green + 0.114 * blue;
    return luminance > 0.55;
}

static BOOL DYYYColorIsAccent(UIColor *color) {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    if (!DYYYColorGetRGBA(color, &red, &green, &blue, &alpha) || alpha < 0.01) {
        return NO;
    }

    return red > 0.75 && green < 0.35 && blue < 0.5;
}

static CGFloat DYYYSelectionSheetHeaderHeight(NSString *headerText, UIViewController *presentingVC) {
    CGFloat viewWidth = CGRectGetWidth(presentingVC.view.bounds);
    if (viewWidth <= 0) {
        viewWidth = CGRectGetWidth([UIScreen mainScreen].bounds);
    }

    CGFloat labelWidth = MAX(viewWidth - 64.0, 120.0);
    UIFont *headerFont = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    CGRect headerRect = [headerText boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                              attributes:@{NSFontAttributeName : headerFont}
                                                 context:nil];
    return MAX(58.0, ceil(headerRect.size.height) + 34.0);
}

static CGFloat DYYYSelectionSheetFittingHeight(NSArray<NSString *> *optionsArray, NSString *headerText, UIViewController *presentingVC) {
    CGFloat safeAreaTop = presentingVC.view.safeAreaInsets.top;
    CGFloat safeAreaBottom = presentingVC.view.safeAreaInsets.bottom;
    CGFloat screenHeight = CGRectGetHeight(presentingVC.view.bounds);
    if (screenHeight <= 0) {
        screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    }

    CGFloat topAreaHeight = DYYYSelectionSheetHeaderHeight(headerText ?: @"", presentingVC);
    CGFloat optionHeight = 53.0;
    CGFloat bottomPadding = MAX(safeAreaBottom, 20.0) + 14.0;
    CGFloat fittingHeight = topAreaHeight + optionHeight * optionsArray.count + bottomPadding;
    CGFloat maxHeight = screenHeight - safeAreaTop - 20.0;
    if (maxHeight <= 0) {
        maxHeight = fittingHeight;
    }
    return ceil(MIN(fittingHeight, maxHeight));
}

static void DYYYApplySelectionSheetThemeToView(UIView *view, BOOL darkMode) {
    if (!view) {
        return;
    }

    if (@available(iOS 13.0, *)) {
        view.overrideUserInterfaceStyle = darkMode ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
    }

    UIColor *backgroundColor = DYYYSelectionSheetBackgroundColor(darkMode);
    UIColor *textColor = DYYYSelectionSheetTextColor(darkMode);
    UIColor *separatorColor = DYYYSelectionSheetSeparatorColor(darkMode);

    UIColor *currentBackgroundColor = view.backgroundColor;
    if (currentBackgroundColor && ![currentBackgroundColor isEqual:[UIColor clearColor]]) {
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
        BOOL hasRGBA = DYYYColorGetRGBA(currentBackgroundColor, &red, &green, &blue, &alpha);
        if (hasRGBA && alpha > 0.01) {
            if (view.bounds.size.height > 0 && view.bounds.size.height <= 1.0) {
                view.backgroundColor = separatorColor;
            } else if ((darkMode && DYYYColorIsLight(currentBackgroundColor)) || (!darkMode && !DYYYColorIsLight(currentBackgroundColor))) {
                view.backgroundColor = backgroundColor;
            }
        }
    }

    if ([view isKindOfClass:[UITableView class]] || [view isKindOfClass:[UITableViewCell class]]) {
        view.backgroundColor = backgroundColor;
    }

    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        UIColor *labelColor = label.textColor;
        if (!DYYYColorIsAccent(labelColor)) {
            label.textColor = textColor;
        }
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        UIColor *buttonColor = [button titleColorForState:UIControlStateNormal];
        if (!DYYYColorIsAccent(buttonColor)) {
            [button setTitleColor:textColor forState:UIControlStateNormal];
        }
    }

    for (UIView *subview in view.subviews) {
        DYYYApplySelectionSheetThemeToView(subview, darkMode);
    }
}

+ (NSString *)showWithPreferenceKey:(NSString *)preferenceKey optionsArray:(NSArray<NSString *> *)optionsArray headerText:(NSString *)headerText onPresentingVC:(UIViewController *)presentingVC {
    return [self showWithPreferenceKey:preferenceKey optionsArray:optionsArray headerText:headerText onPresentingVC:presentingVC selectionChanged:nil];
}

+ (NSString *)showWithPreferenceKey:(NSString *)preferenceKey
                       optionsArray:(NSArray<NSString *> *)optionsArray
                         headerText:(NSString *)headerText
                     onPresentingVC:(UIViewController *)presentingVC
                   selectionChanged:(void (^)(NSString *selectedValue))callback {
    NSString *savedPreference = [[NSUserDefaults standardUserDefaults] stringForKey:preferenceKey];
    if (!savedPreference && optionsArray.count > 0) {
        savedPreference = optionsArray[0];
    }

    Class AWESettingItemModelClass = NSClassFromString(@"AWESettingItemModel");
    Class AWEPrivacySettingActionSheetConfigClass = NSClassFromString(@"AWEPrivacySettingActionSheetConfig");
    Class AWEPrivacySettingActionSheetClass = NSClassFromString(@"AWEPrivacySettingActionSheet");
    Class DUXContentSheetClass = NSClassFromString(@"DUXContentSheet");

    NSMutableArray *models = [NSMutableArray array];
    NSMutableArray *modelRefs = [NSMutableArray array];

    __block id contentSheet = nil;

    for (NSString *option in optionsArray) {
        id model = [[AWESettingItemModelClass alloc] initWithIdentifier:option];
        [model setTitle:option];
        [model setIsSelect:[savedPreference isEqualToString:option]];
        [models addObject:model];
        [modelRefs addObject:model];
    }

    for (int i = 0; i < modelRefs.count; i++) {
        id currentModel = modelRefs[i];
        [currentModel setCellTappedBlock:^{
          for (int j = 0; j < modelRefs.count; j++) {
              [modelRefs[j] setIsSelect:(j == i)];
          }

          NSString *selectedValue = [currentModel title];
          [[NSUserDefaults standardUserDefaults] setObject:selectedValue forKey:preferenceKey];

          if (callback) {
              callback(selectedValue);
          }

          if (contentSheet) {
              [contentSheet dismissViewControllerAnimated:YES completion:nil];
          }
        }];
    }

    id config = [[AWEPrivacySettingActionSheetConfigClass alloc] init];
    [config setModels:models];
    [config setHeaderText:headerText];
    [config setHeaderTitleText:@""];
    [config setNeedHighLight:NO];
    [config setUseCardUIStyle:YES];
    [config setFromHalfScreen:NO];
    [config setHeaderLabelIcon:nil];
    [config setSheetWidth:0];
    [config setAdaptIpadFromHalfVC:NO];

    id actionSheet = [AWEPrivacySettingActionSheetClass sheetWithConfig:config];

    UIViewController *containerVC = [[UIViewController alloc] init];
    BOOL isDarkMode = ![DYYYUtils usesDouyinLightBackground];
    UIColor *sheetBackgroundColor = DYYYSelectionSheetBackgroundColor(isDarkMode);
    if (@available(iOS 13.0, *)) {
        containerVC.overrideUserInterfaceStyle = isDarkMode ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
    }
    containerVC.view.backgroundColor = sheetBackgroundColor;
    [containerVC.view addSubview:actionSheet];

    UIView *sheetView = (UIView *)actionSheet;
    sheetView.backgroundColor = sheetBackgroundColor;
    sheetView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [sheetView.leadingAnchor constraintEqualToAnchor:containerVC.view.leadingAnchor], [sheetView.trailingAnchor constraintEqualToAnchor:containerVC.view.trailingAnchor],
        [sheetView.topAnchor constraintEqualToAnchor:containerVC.view.topAnchor], [sheetView.bottomAnchor constraintEqualToAnchor:containerVC.view.bottomAnchor]
    ]];
    DYYYApplySelectionSheetThemeToView(containerVC.view, isDarkMode);

    CGFloat fittingHeight = DYYYSelectionSheetFittingHeight(optionsArray, headerText, presentingVC);
    contentSheet = [[DUXContentSheetClass alloc] initWithRootViewController:containerVC withTopType:0 withHeight:fittingHeight];
    [contentSheet setContentColor:sheetBackgroundColor];
    [contentSheet setAutoAlignmentCenter:YES];
    [contentSheet setSheetCornerRadius:10.0];

    [actionSheet setCloseBlock:^{
      [contentSheet dismissViewControllerAnimated:YES completion:nil];
    }];

    [contentSheet showOnViewController:presentingVC completion:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
      BOOL currentDarkMode = ![DYYYUtils usesDouyinLightBackground];
      DYYYApplySelectionSheetThemeToView(containerVC.view, currentDarkMode);
      if ([contentSheet respondsToSelector:@selector(setContentColor:)]) {
          [contentSheet setContentColor:DYYYSelectionSheetBackgroundColor(currentDarkMode)];
      }
    });

    return savedPreference;
}

@end
