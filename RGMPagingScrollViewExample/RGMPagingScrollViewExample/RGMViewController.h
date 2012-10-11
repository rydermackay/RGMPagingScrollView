//
//  RGMViewController.h
//  RGMPagingScrollViewExample
//
//  Created by Ryder Mackay on 2012-10-09.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RGMPagingScrollView;
@class RGMPageControl;

@interface RGMViewController : UIViewController

@property (nonatomic, strong) IBOutlet RGMPagingScrollView *pagingScrollView;
@property (nonatomic, strong) IBOutlet RGMPageControl *pageIndicator;

@end
