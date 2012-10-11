//
//  RGMPagingScrollView.h
//  RGMPagingScrollView
//
//  Created by Ryder Mackay on 12-04-20.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    RGMScrollDirectionHorizontal,
    RGMScrollDirectionVertical
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
- (NSInteger)pagingScrollViewNumberOfPages:(RGMPagingScrollView *)pagingScrollView;
- (UIView *)pagingScrollView:(RGMPagingScrollView *)pagingScrollView viewForIndex:(NSInteger)idx;
@end



#pragma mark - RGMPagingScrollView

@interface RGMPagingScrollView : UIScrollView <UIScrollViewDelegate>

@property (assign, nonatomic) RGMScrollDirection scrollDirection;

@property (weak, nonatomic) IBOutlet id <RGMPagingScrollViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet id <RGMPagingScrollViewDatasource> datasource;

@property (nonatomic) NSInteger currentPage;
- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated;

- (UIView *)dequeueReusablePageWithIdentifer:(NSString *)identifier forIndex:(NSInteger)idx;
- (void)registerClass:(Class)pageClass forCellReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(UINib *)nib forCellReuseIdentifier:(NSString *)identifier;

- (void)reloadData;

@end



#pragma mark - UIView+RGMReusablePage

@interface UIView (RGMReusablePage)

@property (copy, nonatomic, readonly) NSString *pageReuseIdentifier;
- (void)prepareForReuse;

@end




