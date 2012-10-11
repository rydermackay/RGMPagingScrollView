//
//  RGMPageView.m
//  RGMPagingScrollViewExample
//
//  Created by Ryder Mackay on 2012-10-11.
//  Copyright (c) 2012 Ryder Mackay. All rights reserved.
//

#import "RGMPageView.h"

@implementation RGMPageView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _label = [[UILabel alloc] initWithFrame:frame];
        _label.font = [UIFont boldSystemFontOfSize:256.0f];
        _label.textAlignment = NSTextAlignmentCenter;
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _label.backgroundColor = [UIColor clearColor];
        [self addSubview:_label];
    }
    
    return self;
}

@end
