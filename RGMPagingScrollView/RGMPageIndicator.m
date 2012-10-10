//
//  RGMPageIndicator.m
//  RGMPagingScrollView
//
//  Created by Ryder Mackay on 2012-07-06.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import "RGMPageIndicator.h"

@interface RGMPageIndicator ()

@property (copy, nonatomic) NSArray *indicators;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *activeImage;

@end



@implementation RGMPageIndicator

- (id)initWithItemImage:(UIImage *)image activeImage:(UIImage *)activeImage
{
    if (self = [super initWithFrame:CGRectZero]) {
        _image = image;
        _numberOfPages = 0;
        _currentPage = 0;
        _activeImage = activeImage;
        _itemSpacing = 5.0f;
        _orientation = RGMPageIndicatorHorizontal;
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
        [self addGestureRecognizer:tapGestureRecognizer];
    }
    
    return self;
}

- (IBAction)tapGestureRecognized:(UITapGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self];
    
    UIImageView *activeIndicator;
    for (UIImageView *imageView in self.indicators) {
        if (imageView.highlighted) {
            activeIndicator = imageView;
            break;
        }
    }
    
    CGRect frame = activeIndicator.frame;
    if (point.x < CGRectGetMinX(frame)) {
        self.currentPage--;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    else if (point.x > CGRectGetMaxX(frame)) {
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

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // remove all pages
    for (UIImageView *imageView in self.indicators) {
        [imageView removeFromSuperview];
    }
    
    if (self.hidesForSinglePage && self.numberOfPages < 2) {
        return;
    }
    
    // reset bounds
    CGRect bounds = self.bounds;
    bounds.size = [self sizeForNumberOfPages:self.numberOfPages];
    self.bounds = bounds;
    
    UIImage *image = self.image;
    UIImage *activeImage = self.activeImage;
    
    NSMutableArray *indicators = [NSMutableArray array];
    
    CGFloat offset = 0.0f;
    CGFloat spacing = self.itemSpacing;
    
    for (int i = 0; i < self.numberOfPages; i++) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image highlightedImage:activeImage];
        imageView.highlighted = (i == self.currentPage);
        
        CGRect frame = imageView.frame;
        
        if (self.orientation == RGMPageIndicatorVertical) {
            frame.origin.y += offset;
            offset += frame.size.height + spacing;
        }
        else {
            frame.origin.x += offset;
            offset += frame.size.width + spacing;
        }
        
        imageView.frame = frame;
        
        [self addSubview:imageView];
        [indicators addObject:imageView];
    }
    
    self.indicators = indicators;
}

@end
