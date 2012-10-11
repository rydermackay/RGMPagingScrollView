//
//  RGMViewController.m
//  RGMPagingScrollViewExample
//
//  Created by Ryder Mackay on 2012-10-09.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import "RGMViewController.h"
#import "RGMPagingScrollView.h"
#import "RGMPageControl.h"

@interface RGMViewController () <RGMPagingScrollViewDatasource, RGMPagingScrollViewDelegate>

#pragma mark - RGMPagingScrollViewDatasource

- (NSUInteger)pagingScrollViewNumberOfPages:(RGMPagingScrollView *)pagingScrollView;
- (UIView *)pagingScrollView:(RGMPagingScrollView *)pagingScrollView viewForIndex:(NSUInteger)idx;

#pragma mark - RGMPagingScrollViewDelegate

- (void)pagingScrollView:(RGMPagingScrollView *)pagingScrollView scrolledToPage:(NSInteger)idx;

@end



#pragma mark -

static NSString *reuseIdentifier = @"RGMPageReuseIdentifier";
static NSUInteger numberOfPages = 3;

@implementation RGMViewController

#pragma mark - View life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.pagingScrollView registerClass:[UIView class] forCellReuseIdentifier:reuseIdentifier];
    
    UIImage *image = [UIImage imageNamed:@"indicator.png"];
    UIImage *imageActive = [UIImage imageNamed:@"indicator-active.png"];
    
    RGMPageControl *indicator = [[RGMPageControl alloc] initWithItemImage:image activeImage:imageActive];
    indicator.numberOfPages = numberOfPages;
    [self.view addSubview:indicator];
    self.pageIndicator = indicator;
    
    [indicator addTarget:self action:@selector(pageIndicatorValueChanged:) forControlEvents:UIControlEventValueChanged];
}

- (IBAction)pageIndicatorValueChanged:(RGMPageControl *)sender
{
    [self.pagingScrollView setCurrentPage:sender.currentPage animated:YES];
}

- (void)viewDidUnload
{
    self.pagingScrollView = nil;
    self.pageIndicator = nil;
    [super viewDidUnload];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect bounds = self.view.bounds;
    
    [self.pageIndicator sizeToFit];
    
    CGRect frame = self.pageIndicator.frame;
    frame.origin.x = floorf((bounds.size.width - frame.size.width) / 2.0f);
    frame.origin.y = bounds.size.height - frame.size.height - 20.0f;
    frame.size.width = MIN(frame.size.width, bounds.size.width);
    self.pageIndicator.frame = frame;
}

#pragma mark - RGMPagingScrollViewDatasource

- (NSUInteger)pagingScrollViewNumberOfPages:(RGMPagingScrollView *)pagingScrollView
{
    return numberOfPages;
}

- (UIView *)pagingScrollView:(RGMPagingScrollView *)pagingScrollView viewForIndex:(NSUInteger)idx
{
    UIView *view = [pagingScrollView dequeueReusablePageWithIdentifer:reuseIdentifier forIndex:idx];
    
    switch (idx) {
        case 0:
            view.backgroundColor = [UIColor redColor];
            break;
        case 1:
            view.backgroundColor = [UIColor greenColor];
            break;
        case 2:
            view.backgroundColor = [UIColor blueColor];
            break;
        default:
            break;
    }
    
    return view;
}

#pragma mark - RGMPagingScrollViewDelegate

- (void)pagingScrollView:(RGMPagingScrollView *)pagingScrollView scrolledToPage:(NSInteger)idx
{
    self.pageIndicator.currentPage = idx;
}

@end
