//
//  RGMPageControl.m
//  RGMPagingScrollView
//
//  Created by Ryder Mackay on 2012-07-06.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import "RGMPageControl.h"

@interface RGMPageControl ()

@property (copy, nonatomic) NSArray *indicators;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *activeImage;

@end



@implementation RGMPageControl

- (id)initWithItemImage:(UIImage *)image activeImage:(UIImage *)activeImage
{
    if (self = [super initWithFrame:CGRectZero]) {
        _image = image;
        _numberOfPages = 0;
        _currentPage = 0;
        _activeImage = activeImage;
        _itemSpacing = 10.0f;
        _orientation = RGMPageIndicatorHorizontal;
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    
    return self;
}

- (IBAction)tapGestureRecognized:(UITapGestureRecognizer *)sender
{
    const CGPoint point = [sender locationInView:self];
    const CGRect frame = [self frameForIndex:self.currentPage];
    const RGMPageIndicatorOrientation orientation = self.orientation;
    
    if ((orientation == RGMPageIndicatorHorizontal && point.x < CGRectGetMinX(frame)) ||
        (orientation == RGMPageIndicatorVertical && point.y < CGRectGetMinY(frame))) {
        self.currentPage--;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else if ((orientation == RGMPageIndicatorHorizontal && point.x > CGRectGetMaxX(frame)) ||
             (orientation == RGMPageIndicatorVertical && point.y > CGRectGetMaxY(frame))) {
        self.currentPage++;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (void)setItemSpacing:(CGFloat)itemSpacing
{
    if (_itemSpacing == itemSpacing) {
        return;
    }
    
    _itemSpacing = itemSpacing;
    
    [self setNeedsLayout];
}

- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    if (_numberOfPages == numberOfPages) {
        return;
    }
    
    _numberOfPages = numberOfPages;
    
    [self reload];
    [self setNeedsLayout];
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    if (_currentPage == currentPage) {
        return;
    }
    
    _currentPage = MIN(currentPage, (self.numberOfPages - 1));
    
    [self highlightIndicatorAtIndex:_currentPage];
}

- (void)highlightIndicatorAtIndex:(NSInteger)indicatorIndex
{
    if (indicatorIndex >= self.indicators.count) {
        return;
    }
    
    [self.indicators enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
        imageView.highlighted = (indicatorIndex == idx);
    }];
}

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount
{
    CGSize imageSize = self.image.size;
    CGFloat spacing = self.itemSpacing;
    
    if (self.orientation == RGMPageIndicatorVertical) {
        return CGSizeMake(imageSize.width, (imageSize.height + spacing) * pageCount - spacing);
    }
    else {
        return CGSizeMake((imageSize.width + spacing) * pageCount - spacing, imageSize.height);
    }
}

- (CGSize)sizeThatFits:(CGSize)size
{
    return [self sizeForNumberOfPages:self.numberOfPages];
}

- (void)reload
{
    for (UIImageView *imageView in self.indicators) {
        [imageView removeFromSuperview];
    }
    
    if (self.hidesForSinglePage && self.numberOfPages < 2) {
        return;
    }
    
    UIImage *image = self.image;
    UIImage *activeImage = self.activeImage;
    
    NSMutableArray *indicators = [NSMutableArray array];
    
    for (int i = 0; i < self.numberOfPages; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image highlightedImage:activeImage];
        imageView.highlighted = (i == self.currentPage);
        
        [self addSubview:imageView];
        [indicators addObject:imageView];
    }
    
    self.indicators = indicators;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.indicators enumerateObjectsUsingBlock:^(UIImageView *imageView, NSUInteger idx, BOOL *stop) {
        imageView.frame = [self frameForIndex:idx];
    }];
}

- (CGRect)frameForIndex:(NSInteger)idx
{
    const CGRect bounds = [self bounds];
    const CGSize size = self.image.size;
    const CGFloat spacing = self.itemSpacing;
    
    if (self.orientation == RGMPageIndicatorVertical) {
        return CGRectMake(floorf((CGRectGetWidth(bounds) - size.width) * 0.5f),
                          (size.height + spacing) * idx,
                          size.width,
                          size.height);
    } else {
        return CGRectMake((size.width + spacing) * idx,
                          floorf((CGRectGetHeight(bounds) - size.height) * 0.5f),
                          size.width,
                          size.height);
    }
}

@end
