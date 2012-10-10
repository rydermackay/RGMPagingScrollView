//
//  RGMPagingScrollView.h
//  RGMPagingScrollView
//
//  Created by Ryder Mackay on 12-04-20.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    RGMScrollDirectionVertical,
    RGMScrollDirectionHorizontal
} RGMScrollDirection;

@class RGMPagingScrollView;

#pragma mark RGMPagingScrollViewDelegate

@protocol RGMPagingScrollViewDelegate <UIScrollViewDelegate>
@optional
- (void)pagingScrollView:(RGMPagingScrollView *)pagingScrollView scrolledToPage:(NSInteger)idx;
@end



#pragma mark - RGMPagingScrollViewDatasource

@protocol RGMPagingScrollViewDatasource <NSObject>
@required
- (NSUInteger)pagingScrollViewNumberOfPages:(RGMPagingScrollView *)pagingScrollView;
- (UIView *)pagingScrollView:(RGMPagingScrollView *)pagingScrollView viewForIndex:(NSUInteger)idx;
@end



#pragma mark - RGMPagingScrollView

@interface RGMPagingScrollView : UIScrollView <UIScrollViewDelegate>

@property (assign, nonatomic) RGMScrollDirection scrollDirection;

@property (weak, nonatomic) IBOutlet id <RGMPagingScrollViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet id <RGMPagingScrollViewDatasource> datasource;

@property (nonatomic) NSInteger currentPage;
- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated;

- (UIView *)dequeueReusablePageWithIdentifer:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellReuseIdentifier:(NSString *)identifier;

- (void)reloadData;

@end



#pragma mark - UIView+RGMReusablePage

@protocol RGMReusablePage <NSObject>

@optional
- (void)prepareForReuse;

@end



@interface UIView (RGMReusablePage) <RGMReusablePage>

@property (copy, nonatomic) NSString *pageReuseIdentifier;
- (void)prepareForReuse;

@end




