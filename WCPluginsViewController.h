//
//     Generated by class-dump 3.5 (64 bit).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <UIKit/UIViewController.h>

@class NSMutableArray, UIView, WCTableViewManager;

@interface WCPluginsViewController : UIViewController
{
    WCTableViewManager *_tableViewManager;
    UIView *_navHeaderView;
    NSMutableArray *_dataSource;
}

//- (void).cxx_destruct;
- (id)addNormalCellForSel:(SEL)arg1 title:(id)arg2 rightValue:(id)arg3 userInfo:(id)arg4;
- (id)addSwitchCellForSel:(SEL)arg1 title:(id)arg2 on:(_Bool)arg3 userInfo:(id)arg4;
@property(retain, nonatomic) NSMutableArray *dataSource; // @synthesize dataSource=_dataSource;
- (id)getHeaderView;
- (_Bool)getSwitchKeyValue:(id)arg1;
- (void)initData;
- (void)initNavHeaderIfNeed;
- (void)initTableView;
- (id)initWithNibName:(id)arg1 bundle:(id)arg2;
@property(retain, nonatomic) UIView *navHeaderView; // @synthesize navHeaderView=_navHeaderView;
- (void)pushPluginController:(id)arg1;
- (void)reloadTableData;
@property(retain, nonatomic) WCTableViewManager *tableViewManager; // @synthesize tableViewManager=_tableViewManager;
- (_Bool)shouldAutorotate;
- (void)switchChanged:(id)arg1;
- (void)viewDidLoad;
- (void)viewWillLayoutSubviews;

@end

