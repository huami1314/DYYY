//
// WCPLBaseViewController.m
//
// Created by dyf on 17/4/6.
// Copyright © 2017 dyf. All rights reserved.
//

#import "WCPLBaseViewController.h"
#import "WeChatRedEnvelop.h"
#import <objc/objc-runtime.h>

@interface WCPLBaseViewController ()

@property (strong, nonatomic) MMLoadingView *loadingView;

@end

@implementation WCPLBaseViewController

- (void)startLoadingBlocked {
    if (!self.loadingView) {
        self.loadingView = [self createDefaultLoadingView];
        [self.view addSubview:self.loadingView];
    } else {
        [self.view bringSubviewToFront:self.loadingView];
    }
    
    [self.loadingView setM_bIgnoringInteractionEventsWhenLoading:YES];
    [self.loadingView setFitFrame:1];
    [self.loadingView startLoading];
}

- (void)startLoadingNonBlock {
    if (!self.loadingView) {
        self.loadingView = [self createDefaultLoadingView];
        [self.view addSubview:self.loadingView];
    } else {
        [self.view bringSubviewToFront:self.loadingView];
    }
    
    [self.loadingView setM_bIgnoringInteractionEventsWhenLoading:NO];
    [self.loadingView setFitFrame:1];
    [self.loadingView startLoading];
}

- (void)startLoadingWithText:(NSString *)text {
    [self startLoadingNonBlock];
    [self.loadingView.m_label setText:text];
}

- (MMLoadingView *)createDefaultLoadingView {
    MMLoadingView *loadingView     = [[objc_getClass("MMLoadingView") alloc] init];
    
    MMServiceCenter *serviceCenter = [objc_getClass("MMServiceCenter") defaultCenter];
    MMLanguageMgr *languageMgr     = [serviceCenter getService:objc_getClass("MMLanguageMgr")];
    NSString *loadingText          = [languageMgr getStringForCurLanguage:@"Common_DefaultLoadingText"];
    
    [loadingView.m_label setText:loadingText];
    
    return loadingView;
}

- (void)stopLoading {
    [self.loadingView stopLoading];
}

- (void)stopLoadingWithFailText:(NSString *)text {
    [self.loadingView stopLoadingAndShowError:text];
}

- (void)stopLoadingWithOKText:(NSString *)text {
    [self.loadingView stopLoadingAndShowOK:text];
}

@end
