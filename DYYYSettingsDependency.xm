#import "AwemeHeaders.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "DYYYUtils.h"

static bool getUserDefaults(NSString *key) { return [[NSUserDefaults standardUserDefaults] boolForKey:key]; }

static void setUserDefaults(id object, NSString *key) {
	[[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

%hook AWESettingsViewModel

%new
- (NSDictionary *)settingsDependencyConfig {
	static NSDictionary *config = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
	  config = @{
		  // ===== 依赖关系配置 =====
		  @"dependencies" : @{
			  // 普通依赖：当源设置开启时，目标设置项可用
			  @"DYYYEnableDanmuColor" : @[ @"DYYYdanmuColor" ],
			  @"DYYYisEnableArea" : @[ @"DYYYLabelColor" ],
			  @"DYYYisShowScheduleDisplay" : @[ @"DYYYScheduleStyle", @"DYYYProgressLabelColor", @"DYYYTimelineVerticalPosition" ],
			  @"DYYYEnableNotificationTransparency" : @[ @"DYYYNotificationCornerRadius" ],
			  @"DYYYEnableFloatSpeedButton" : @[ @"DYYYAutoRestoreSpeed", @"DYYYSpeedButtonShowX", @"DYYYSpeedButtonSize", @"DYYYSpeedSettings" ],
			  @"DYYYEnableFloatClearButton" : @[ @"DYYYClearButtonIcon", @"DYYYEnableFloatClearButtonSize", @"DYYYEnabshijianjindu", @"DYYYHideTimeProgress", @"DYYYHideDanmaku" ],
		  },

		  // ===== 条件依赖配置 =====
		  // 一些设置项依赖于多个其他设置项的复杂条件
		  @"conditionalDependencies" : @{
			  @"DYYYCommentBlurTransparent" : @{@"condition" : @"OR", @"settings" : @[ @"DYYYisEnableCommentBlur", @"DYYYEnableNotificationTransparency" ]},
		  },

		  // ===== 冲突配置 =====
		  // 当源设置项开启时，会自动关闭目标设置项
		  @"conflicts" : @{
			  @"DYYYEnableDoubleOpenComment" : @[ @"DYYYEnableDoubleOpenAlertController" ],
			  @"DYYYEnableDoubleOpenAlertController" : @[ @"DYYYEnableDoubleOpenComment" ],
			  @"DYYYABTestBlockEnabled" : @[ @"DYYYABTestPatchEnabled" ],
			  @"DYYYABTestPatchEnabled" : @[ @"DYYYABTestBlockEnabled" ],
			  @"DYYYEnabshijianjindu" : @[ @"DYYYHideTimeProgress" ],
			  @"DYYYHideTimeProgress" : @[ @"DYYYEnabshijianjindu" ],
			  @"DYYYHideLOTAnimationView" : @[ @"DYYYHideFollowPromptView" ],
			  @"DYYYHideFollowPromptView" : @[ @"DYYYHideLOTAnimationView" ]
		  },

		  // ===== 互斥激活配置 =====
		  // 当源设置项关闭时，目标设置项才能激活
		  @"mutualExclusive" : @{
			  @"DYYYEnableDoubleOpenComment" : @[ @"DYYYEnableDoubleOpenAlertController" ],
			  @"DYYYEnableDoubleOpenAlertController" : @[ @"DYYYEnableDoubleOpenComment" ],
			  @"DYYYABTestBlockEnabled" : @[ @"DYYYABTestPatchEnabled" ],
			  @"DYYYABTestPatchEnabled" : @[ @"DYYYABTestBlockEnabled" ],
			  @"DYYYEnabshijianjindu" : @[ @"DYYYHideTimeProgress" ],
			  @"DYYYHideTimeProgress" : @[ @"DYYYEnabshijianjindu" ],
			  @"DYYYHideLOTAnimationView" : @[ @"DYYYHideFollowPromptView" ],
			  @"DYYYHideFollowPromptView" : @[ @"DYYYHideLOTAnimationView" ]
		  },

		  // ===== 值依赖配置 =====
		  // 基于字符串值的依赖关系
		  @"valueDependencies" :
		      @{@"DYYYInterfaceDownload" : @{@"valueType" : @"string", @"condition" : @"isNotEmpty", @"dependents" : @[ @"DYYYShowAllVideoQuality", @"DYYYDoubleInterfaceDownload" ]}},
	  };
	});

	return config;
}

%new
- (void)applyDependencyRulesForItem:(AWESettingItemModel *)item {
	NSDictionary *dependencies = [self settingsDependencyConfig][@"dependencies"];
	NSDictionary *conditionalDependencies = [self settingsDependencyConfig][@"conditionalDependencies"];
	NSDictionary *mutualExclusive = [self settingsDependencyConfig][@"mutualExclusive"];
	NSDictionary *valueDependencies = [self settingsDependencyConfig][@"valueDependencies"];

	for (NSString *sourceKey in dependencies) {
		NSArray *dependentItems = dependencies[sourceKey];
		if ([dependentItems containsObject:item.identifier]) {
			BOOL sourceValue = getUserDefaults(sourceKey);
			item.isEnable = sourceValue;
			return;
		}
	}

	for (NSString *targetKey in conditionalDependencies) {
		NSDictionary *conditionConfig = conditionalDependencies[targetKey];
		if ([targetKey isEqualToString:item.identifier]) {
			NSString *conditionType = conditionConfig[@"condition"];
			NSArray *settingList = conditionConfig[@"settings"];

			if ([conditionType isEqualToString:@"OR"]) {
				BOOL shouldEnable = NO;
				for (NSString *settingKey in settingList) {
					if (getUserDefaults(settingKey)) {
						shouldEnable = YES;
						break;
					}
				}
				item.isEnable = shouldEnable;
				return;
			} else if ([conditionType isEqualToString:@"AND"]) {
				BOOL shouldEnable = YES;
				for (NSString *settingKey in settingList) {
					if (!getUserDefaults(settingKey)) {
						shouldEnable = NO;
						break;
					}
				}
				item.isEnable = shouldEnable;
				return;
			}
		}
	}

	for (NSString *sourceKey in mutualExclusive) {
		NSArray *exclusiveItems = mutualExclusive[sourceKey];
		if ([exclusiveItems containsObject:item.identifier]) {
			BOOL sourceValue = getUserDefaults(sourceKey);
			item.isEnable = !sourceValue; // 当源设置关闭时，目标设置才能激活
			return;
		}
	}

	for (NSString *sourceKey in valueDependencies) {
		NSDictionary *valueConfig = valueDependencies[sourceKey];
		NSArray *dependentItems = valueConfig[@"dependents"];

		if ([dependentItems containsObject:item.identifier]) {
			NSString *valueType = valueConfig[@"valueType"];
			NSString *condition = valueConfig[@"condition"];

			if ([valueType isEqualToString:@"string"] && [condition isEqualToString:@"isNotEmpty"]) {
				NSString *sourceValue = [[NSUserDefaults standardUserDefaults] objectForKey:sourceKey];
				item.isEnable = (sourceValue != nil && sourceValue.length > 0);
				return;
			}
		}
	}
}

%new
- (void)handleConflictsAndDependenciesForSetting:(NSString *)identifier isEnabled:(BOOL)isEnabled {
	NSDictionary *conflicts = [self settingsDependencyConfig][@"conflicts"];
	NSDictionary *dependencies = [self settingsDependencyConfig][@"dependencies"];
	if (isEnabled) {
		NSArray *conflictingItems = conflicts[identifier];
		if (conflictingItems) {
			for (NSString *conflictItem in conflictingItems) {
				// 更新NSUserDefaults
				setUserDefaults(@(NO), conflictItem);

				// 立即更新互斥项的UI状态
				[self updateConflictingItemUIState:conflictItem withValue:NO];
			}
		}
	}

	[self updateDependentItemsForSetting:identifier value:@(isEnabled)];

	[self refreshTableView];
}

%new
- (void)updateConflictingItemUIState:(NSString *)identifier withValue:(BOOL)value {
	UIViewController *topVC = topView();
	AWESettingBaseViewController *settingsVC = nil;

	// 查找当前视图控制器
	if ([topVC isKindOfClass:%c(AWESettingBaseViewController)]) {
		settingsVC = (AWESettingBaseViewController *)topVC;
	} else {
		UIView *firstLevelView = [topVC.view.subviews firstObject];
		UIView *secondLevelView = firstLevelView ? [firstLevelView.subviews firstObject] : nil;
		UIView *thirdLevelView = secondLevelView ? [secondLevelView.subviews firstObject] : nil;

		UIResponder *responder = thirdLevelView;
		while (responder) {
			if ([responder isKindOfClass:%c(AWESettingBaseViewController)]) {
				settingsVC = (AWESettingBaseViewController *)responder;
				break;
			}
			responder = [responder nextResponder];
		}
	}

	// 更新设置项UI
	if (settingsVC) {
		AWESettingsViewModel *viewModel = (AWESettingsViewModel *)[settingsVC viewModel];
		if (viewModel && [viewModel respondsToSelector:@selector(sectionDataArray)]) {
			NSArray *sectionDataArray = [viewModel sectionDataArray];
			for (AWESettingSectionModel *section in sectionDataArray) {
				if ([section respondsToSelector:@selector(itemArray)]) {
					NSArray *itemArray = section.itemArray;
					for (id itemObj in itemArray) {
						if ([itemObj isKindOfClass:%c(AWESettingItemModel)]) {
							AWESettingItemModel *item = (AWESettingItemModel *)itemObj;
							if ([item.identifier isEqualToString:identifier]) {
								item.isSwitchOn = value;
								break;
							}
						}
					}
				}
			}
		}
	}
}

%new
- (void)updateDependentItemsForSetting:(NSString *)identifier value:(id)value {
	NSDictionary *dependencies = [self settingsDependencyConfig][@"dependencies"];
	NSDictionary *conditionalDependencies = [self settingsDependencyConfig][@"conditionalDependencies"];
	NSDictionary *mutualExclusive = [self settingsDependencyConfig][@"mutualExclusive"];
	NSDictionary *valueDependencies = [self settingsDependencyConfig][@"valueDependencies"];
	NSDictionary *conflicts = [self settingsDependencyConfig][@"conflicts"];

	UIViewController *topVC = topView();
	AWESettingBaseViewController *settingsVC = nil;

	UIView *firstLevelView = [topVC.view.subviews firstObject];
	UIView *secondLevelView = [firstLevelView.subviews firstObject];
	UIView *thirdLevelView = [secondLevelView.subviews firstObject];

	UIResponder *responder = thirdLevelView;
	while (responder) {
		if ([responder isKindOfClass:%c(AWESettingBaseViewController)]) {
			settingsVC = (AWESettingBaseViewController *)responder;
			break;
		}
		responder = [responder nextResponder];
	}

	AWESettingsViewModel *viewModel = (AWESettingsViewModel *)[settingsVC viewModel];
	if (!viewModel || ![viewModel respondsToSelector:@selector(sectionDataArray)])
		return;

	NSArray *sectionDataArray = [viewModel sectionDataArray];

	NSMutableSet *itemsToUpdate = [NSMutableSet set];

	NSArray *directDependents = dependencies[identifier];
	if (directDependents) {
		[itemsToUpdate addObjectsFromArray:directDependents];
	}

	NSArray *exclusiveItems = mutualExclusive[identifier];
	if (exclusiveItems) {
		[itemsToUpdate addObjectsFromArray:exclusiveItems];
	}

	NSArray *conflictItems = conflicts[identifier];
	if (conflictItems) {
		[itemsToUpdate addObjectsFromArray:conflictItems];
	}

	for (NSString *targetItem in conditionalDependencies) {
		NSDictionary *conditionInfo = conditionalDependencies[targetItem];
		NSArray *settingsList = conditionInfo[@"settings"];
		if ([settingsList containsObject:identifier]) {
			[itemsToUpdate addObject:targetItem];
		}
	}

	NSDictionary *valueDepInfo = valueDependencies[identifier];
	if (valueDepInfo) {
		NSArray *dependentItems = valueDepInfo[@"dependents"];
		if (dependentItems) {
			[itemsToUpdate addObjectsFromArray:dependentItems];
		}
	}

	for (AWESettingSectionModel *section in sectionDataArray) {
		if (![section respondsToSelector:@selector(itemArray)])
			continue;

		NSArray *itemArray = section.itemArray;
		for (id itemObj in itemArray) {
			if (![itemObj isKindOfClass:%c(AWESettingItemModel)])
				continue;

			AWESettingItemModel *item = (AWESettingItemModel *)itemObj;
			if ([itemsToUpdate containsObject:item.identifier]) {
				[self applyDependencyRulesForItem:item];
			}
		}
	}
}

%new
- (void)refreshTableView {
	UIViewController *topVC = topView();
	AWESettingBaseViewController *settingsVC = nil;
	UITableView *tableView = nil;

	UIView *firstLevelView = [topVC.view.subviews firstObject];
	UIView *secondLevelView = [firstLevelView.subviews firstObject];
	UIView *thirdLevelView = [secondLevelView.subviews firstObject];

	UIResponder *responder = thirdLevelView;
	while (responder) {
		if ([responder isKindOfClass:%c(AWESettingBaseViewController)]) {
			settingsVC = (AWESettingBaseViewController *)responder;
			break;
		}
		responder = [responder nextResponder];
	}

	if (settingsVC) {
		for (UIView *subview in settingsVC.view.subviews) {
			if ([subview isKindOfClass:[UITableView class]]) {
				tableView = (UITableView *)subview;
				break;
			}
		}

		if (tableView) {
			[tableView reloadData];
		}
	}
}
%end
