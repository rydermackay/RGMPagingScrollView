//
//  RGMPagingScrollView.m
//  RGMPagingScrollView
//
//  Created by Ryder Mackay on 12-04-20.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import "RGMPagingScrollView.h"
#import <objc/runtime.h>

#pragma mark UIView + RGMReusablePage

@implementation UIView (RGMReusablePage)

static NSString *RGMPageReuseIdentifierKey = @"pageReuseIdentifier";

- (NSString *)pageReuseIdentifier
{
    return objc_getAssociatedObject(self, &RGMPageReuseIdentifierKey);
}

- (void)setPageReuseIdentifier:(NSString *)pageReuseIdentifier
{
    objc_setAssociatedObject(self, &RGMPageReuseIdentifierKey, pageReuseIdentifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)prepareForReuse
{
    
}

@end





#pragma mark - RGMPagingScrollViewPrivateDelegate

@interface RGMPagingScrollViewPrivateDelegate : NSObject <UIScrollViewDelegate>

- (id)initWithPagingScrollView:(RGMPagingScrollView *)pagingScrollView;

@property (weak, nonatomic) RGMPagingScrollView *pagingScrollView;
@property (weak, nonatomic) id <RGMPagingScrollViewDelegate> delegate;

@end


@implementation RGMPagingScrollViewPrivateDelegate

- (id)initWithPagingScrollView:(RGMPagingScrollView *)pagingScrollView
{
    if (self = [super init]) {
        self.pagingScrollView = pagingScrollView;
    }
    
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || [self.delegate respondsToSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if ([self.delegate respondsToSelector:invocation.selector]) {
        [invocation invokeWithTarget:self.delegate];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.pagingScrollView scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self.pagingScrollView scrollViewDidEndDecelerating:scrollView];
    
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self.pagingScrollView scrollViewDidEndScrollingAnimation:scrollView];
    
    if ([self.delegate respondsToSelector:_cmd]) {
        [self.delegate scrollViewDidEndScrollingAnimation:scrollView];
    }
}

@end





#pragma mark - RGMPagingScrollViewModel

@interface RGMPagingScrollViewModel : NSObject

@property (nonatomic) NSInteger numberOfPages;
@property (nonatomic) CGFloat pageWidth;
@property (nonatomic) CGFloat pageHeight;
@property (nonatomic) CGFloat gutter;

- (CGSize)contentSizeForDirection:(RGMScrollDirection)direction;

@end



@implementation RGMPagingScrollViewModel

- (CGSize)contentSizeForDirection:(RGMScrollDirection)direction
{
    switch (direction) {
        case RGMScrollDirectionHorizontal:
            return CGSizeMake((self.pageWidth + self.gutter) * self.numberOfPages, self.pageHeight);
            break;
        case RGMScrollDirectionVertical:
            return CGSizeMake(self.pageWidth, (self.pageHeight + self.gutter) * self.numberOfPages);
            break;
        default:
            return CGSizeMake(self.pageWidth, self.pageHeight);
            break;
    }
}

@end





#pragma mark - RGMPagingScrollView

@interface RGMPagingScrollView () {
    NSMutableSet *_visiblePages;
    NSMutableDictionary *_reusablePages;
    NSMutableDictionary *_registeredClasses;
    NSMutableDictionary *_registeredNibs;
}

@property (strong, nonatomic) RGMPagingScrollViewModel *viewModel;
@property (strong, nonatomic) RGMPagingScrollViewPrivateDelegate *privateDelegate;

- (CGRect)frameForIndex:(NSInteger)idx;
- (BOOL)isDisplayingPageAtIndex:(NSInteger)idx;
- (void)queuePageForReuse:(UIView *)page;
- (void)didScrollToPage:(NSInteger)idx;

@end


@implementation RGMPagingScrollView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]){
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    self.pagingEnabled = YES;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    _scrollDirection = RGMScrollDirectionHorizontal;
    _visiblePages = [NSMutableSet set];
    _reusablePages = [NSMutableDictionary dictionary];
    _registeredClasses = [NSMutableDictionary dictionary];
    _registeredNibs = [NSMutableDictionary dictionary];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (self.clipsToBounds == NO) {
        CGPoint newPoint = [self.superview convertPoint:point fromView:self];
        return CGRectContainsPoint(self.superview.bounds, newPoint);
    }
    else {
        return [super pointInside:point withEvent:event];
    }
}

- (RGMPagingScrollViewPrivateDelegate *)privateDelegate
{
    if (_privateDelegate == nil) {
        _privateDelegate = [[RGMPagingScrollViewPrivateDelegate alloc] initWithPagingScrollView:self];
    }
    
    return _privateDelegate;
}

- (void)setDelegate:(id <RGMPagingScrollViewDelegate>)delegate
{
    self.privateDelegate.delegate = delegate;
    [super setDelegate:self.privateDelegate];
}

- (id <RGMPagingScrollViewDelegate>)delegate
{
    return self.privateDelegate.delegate;
}

- (void)reloadData
{
    for (UIView *view in _visiblePages) {
        [view removeFromSuperview];
    }
    
    [_visiblePages removeAllObjects];
    [_reusablePages removeAllObjects];
    
    self.viewModel = nil;
    
    [self setNeedsLayout];
}

- (RGMPagingScrollViewModel *)viewModel
{
    if (_viewModel == nil) {
        _viewModel = [[RGMPagingScrollViewModel alloc] init];
        _viewModel.numberOfPages = [self.datasource pagingScrollViewNumberOfPages:self];
        
        _viewModel.pageWidth = self.bounds.size.width;
        _viewModel.pageHeight = self.bounds.size.height;
        _viewModel.gutter = 0.0f;
        
        self.contentSize = [_viewModel contentSizeForDirection:self.scrollDirection];
        
        // expand view to accomodate gutter
        CGRect frame = self.frame;
        
        switch (self.scrollDirection) {
            case RGMScrollDirectionHorizontal: {
                frame.size.width += _viewModel.gutter;
                frame.origin.x -= _viewModel.gutter / 2;
                break;
            }
            case RGMScrollDirectionVertical: {
                frame.size.height += _viewModel.gutter;
                frame.origin.y -= _viewModel.gutter / 2;
                break;
            }
        }
        
        self.frame = frame;
    }
    
    return _viewModel;
}

- (CGRect)frameForIndex:(NSInteger)idx
{
    RGMPagingScrollViewModel *model = self.viewModel;
    
    CGFloat pageWidth = model.pageWidth;
    CGFloat pageHeight = model.pageHeight;
    CGFloat gutter = model.gutter;
    
    CGRect frame = CGRectZero;
    frame.size.width = pageWidth;
    frame.size.height = pageHeight;
    
    switch (self.scrollDirection) {
        case RGMScrollDirectionHorizontal:
            frame.origin.x = (pageWidth + gutter) * idx + floorf(gutter / 2.0f);
            break;
        case RGMScrollDirectionVertical:
            frame.origin.y = (pageHeight + gutter) * idx + floorf(gutter / 2.0f);
            break;
    }
    
    return frame;
}

- (BOOL)isDisplayingPageAtIndex:(NSInteger)idx
{
    BOOL isDisplayingPage = NO;
    
    for (UIView *page in _visiblePages) {
        if (page.tag == idx) {
            isDisplayingPage = YES;
            break;
        }
    }
    
    return isDisplayingPage;
}

- (void)registerClass:(Class)pageClass forCellReuseIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier != nil);
    
    [_registeredClasses setValue:pageClass forKey:identifier];
    [_registeredNibs removeObjectForKey:identifier];
}

- (void)registerNib:(UINib *)nib forCellReuseIdentifier:(NSString *)identifier
{
    NSParameterAssert(identifier != nil);
    
    [_registeredNibs setValue:nib forKey:identifier];
    [_registeredClasses removeObjectForKey:identifier];
}

- (UIView *)dequeueReusablePageWithIdentifer:(NSString *)identifier forIndex:(NSInteger)idx
{
    NSParameterAssert(identifier != nil);
    
    NSMutableSet *set = [self reusablePagesWithIdentifier:identifier];
    UIView *page = [set anyObject];
    
    if (page != nil) {
        [page prepareForReuse];
        [set removeObject:page];
        
        return page;
    }
    
    NSAssert([_registeredClasses.allKeys containsObject:identifier] || [_registeredNibs.allKeys containsObject:identifier], @"No registered class or nib for identifier \"%@\"", identifier);
    
    // instantiate page from registered class
    Class pageClass = [_registeredClasses objectForKey:identifier];
    page = [[pageClass alloc] initWithFrame:CGRectZero];
    
    if (page == nil) {
        // otherwise, instantiate from registered nib
        UINib *registeredNib = [_registeredNibs objectForKey:identifier];
        
        NSArray *topLevelObjects = [registeredNib instantiateWithOwner:self options:nil];
        NSParameterAssert(topLevelObjects.count == 1);
        
        page = [topLevelObjects objectAtIndex:0];
        NSParameterAssert([page isKindOfClass:[UIView class]]);
    }
    
    page.pageReuseIdentifier = identifier;
    
    return page;
}

- (NSMutableSet *)reusablePagesWithIdentifier:(NSString *)identifier
{
    if (identifier == nil) {
        return nil;
    }
    
    NSMutableSet *set = [_reusablePages objectForKey:identifier];
    if (set == nil) {
        set = [NSMutableSet set];
        [_reusablePages setObject:set forKey:identifier];
    }
    
    return set;
}

- (void)queuePageForReuse:(UIView *)page
{
    if (page.pageReuseIdentifier == nil) {
        return;
    }
    
    [[self reusablePagesWithIdentifier:page.pageReuseIdentifier] addObject:page];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    // calculate needed indexes
    CGFloat numberOfPages = self.viewModel.numberOfPages;
    CGRect visibleBounds = self.clipsToBounds ? self.bounds : [self convertRect:self.superview.bounds fromView:self.superview];
    CGFloat pageLength, min, max;
    
    switch (self.scrollDirection) {
        case RGMScrollDirectionHorizontal: {
            pageLength = self.viewModel.pageWidth + self.viewModel.gutter;
            min = CGRectGetMinX(visibleBounds) + self.viewModel.gutter / 2;
            max = CGRectGetMaxX(visibleBounds) - self.viewModel.gutter / 2;
            break;
        }
        case RGMScrollDirectionVertical: {
            pageLength = self.viewModel.pageHeight + self.viewModel.gutter;
            min = CGRectGetMinY(visibleBounds) + self.viewModel.gutter / 2;
            max = CGRectGetMaxY(visibleBounds) - self.viewModel.gutter / 2;
            break;
        }
    }
    
    max--;
    
    NSInteger firstNeededIndex = floorf(min / pageLength);
    NSInteger lastNeededIndex = floorf(max / pageLength);
    
    firstNeededIndex = MAX(firstNeededIndex, 0);
    lastNeededIndex = MIN(numberOfPages - 1, lastNeededIndex);
    
    
    
    // remove and queue reusable pages
    NSMutableSet *removedPages = [NSMutableSet set];
    
    for (UIView *visiblePage in _visiblePages) {
        if (visiblePage.tag < firstNeededIndex || visiblePage.tag > lastNeededIndex) {
            [visiblePage removeFromSuperview];
            [removedPages addObject:visiblePage];
            
            [self queuePageForReuse:visiblePage];
        }
    }
    
    [_visiblePages minusSet:removedPages];
    
    
    
    // layout visible pages
    if (numberOfPages > 0) {
        for (NSInteger idx = firstNeededIndex; idx <= lastNeededIndex; idx++) {
            if ([self isDisplayingPageAtIndex:idx] == NO) {
                UIView *page = [self.datasource pagingScrollView:self viewForIndex:idx];
                NSParameterAssert(page != nil);
                
                page.frame = [self frameForIndex:idx];
                page.tag = idx;
                
                [self insertSubview:page atIndex:0];
                [_visiblePages addObject:page];
            }
        }
    }
}

- (NSInteger)currentPage
{
    NSInteger currentPage;
    
    switch (self.scrollDirection) {
        case RGMScrollDirectionHorizontal: {
            CGFloat pageWidth = self.viewModel.pageWidth + self.viewModel.gutter;
            currentPage = floorf(CGRectGetMinX(self.bounds) / pageWidth);
            break;
        }
        case RGMScrollDirectionVertical: {
            CGFloat pageHeight = self.viewModel.pageHeight + self.viewModel.gutter;
            currentPage = floorf(CGRectGetMinY(self.bounds) / pageHeight);
            break;
        }
    }
    
    currentPage = MAX(currentPage, 0);
    currentPage = MIN((self.viewModel.numberOfPages - 1), currentPage);
    
    return currentPage;
}

- (void)setCurrentPage:(NSInteger)currentPage
{
    [self setCurrentPage:currentPage animated:NO];
}

- (void)setCurrentPage:(NSInteger)currentPage animated:(BOOL)animated
{
    CGRect frame = [self frameForIndex:currentPage];
    CGPoint offset = frame.origin;
    
    switch (self.scrollDirection) {
        case RGMScrollDirectionHorizontal:
            offset.x -= self.viewModel.gutter / 2;
            break;
        case RGMScrollDirectionVertical:
            offset.y -= self.viewModel.gutter / 2;
            break;
    }
    
    [self setContentOffset:offset animated:animated];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (decelerate == NO) {
        [self didScrollToPage:self.currentPage];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self didScrollToPage:self.currentPage];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [self didScrollToPage:self.currentPage];
}

- (void)didScrollToPage:(NSInteger)idx
{
    if ([self.delegate respondsToSelector:@selector(pagingScrollView:scrolledToPage:)]) {
        [self.delegate pagingScrollView:self scrolledToPage:idx];
    }
}

@end
