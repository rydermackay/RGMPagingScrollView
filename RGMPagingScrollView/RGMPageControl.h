//
//  RGMPageControl.h
//  RGMPagingScrollView
//
//  Created by Ryder Mackay on 2012-07-06.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    RGMPageIndicatorHorizontal,
    RGMPageIndicatorVertical
} RGMPageIndicatorOrientation;

@interface RGMPageControl : UIControl

@property(nonatomic) NSInteger numberOfPages;          // default is 0
@property(nonatomic) NSInteger currentPage;            // default is 0. value pinned to 0..numberOfPages-1

@property(nonatomic) BOOL hidesForSinglePage;          // hide the the indicator if there is only one page. default is NO

- (CGSize)sizeForNumberOfPages:(NSInteger)pageCount;   // returns minimum size required to display dots for given page count. can be used to size control if page count could change

- (id)initWithItemImage:(UIImage *)image activeImage:(UIImage *)activeImage;

@property (assign, nonatomic) CGFloat itemSpacing; // default is 10.0f
@property (assign, nonatomic) RGMPageIndicatorOrientation orientation;  // default is horizontal

@end
