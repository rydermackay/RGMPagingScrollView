# RGMPagingScrollView
> “This is my paging scroll view. There are many like it, but this one is mine.”

`RGMPagingScrollView` is a simple `UIScrollView` subclass that manages presentation of a single horizontal or vertical row of reusable views, similar to the Photos app on iOS. The API follows the patterns set by `UITableView` and `UICollectionView` which makes it easy to understand and use.

On iOS 6, `UIPageViewController` provides similar behaviour out of the box. I’ve made the source available for developers targeting older versions of iOS. I hope you find it useful.

## Usage
See the example Xcode project in */RGMPagingScrollViewExample*.

Instantiate `RGMPagingScrollView` in code or as part of a nib or storyboard. Set the `datasource` and `delegate` properties and adopt the corresponding protocols. Reusable views can be registered in advance using the `-registerClass:forReuseIdentifier:` or `-registerNib:forReuseIdentifier:` methods.

	_pagingScrollView = [[RMGPagingScrollView alloc] initWithFrame:self.view.bounds]
	_pagingScrollView.datasource = self;
	_pagingScrollView.delegate = self;
	[_pagingScrollView registerClass:[XYZPageView class] forReuseIdentifier:@"identifier"];
	[self.view addSubview:_pagingScrollView];

### RGMPagingScrollViewDatasource
Implement the two required methods, `-pagingScrollViewNumberOfPages:` and `-pagingScrollView:viewForIndex:`, which are analogous to those of `UITableViewDatasource`.

	- (UIView *)pagingScrollView:(RGMPagingScrollView *)pagingScrollView viewForIndex:(NSInteger)idx
	{
		XYZPageView *view = (XYZPageView *)[pagingScrollView dequeueReusablePageWithIdentifer:@"identifier" forIndex:idx];
		
		// customize view…
		
	    return view;
	}

Following the behaviour of `UITableView` in iOS 5 and up, `-dequeueReusablePageWithIdentifer:` is guaranteed to return a view through reuse or by instantiating a new one from a registered class or nib.

### RGMPagingScrollViewDelegate
The `RGMPagingScrollViewDelegate` protocol cleanly extends `UIScrollViewDelegate`. Thanks to the Objective-C runtime’s message forwarding system, any object that conforms to `RGMPagingScrollViewDelegate` will also receive any `UIScrollViewDelegate` method calls it can respond to.

There is one optional delegate method, `-pagingScrollView:scrolledToPage:`, which is called when the view finishes scrolling to a page boundary as a result of user action or explicit animation.

# RGMPageControl

`RGMPageControl` is a customizable replacement for `UIPageControl`. It supports custom indicator images and spacing, and both horizontal and vertical layout.

	_pageControl = [[RGMPageControl alloc] initWithItemImage:itemImage activeImage:activeImage];
	_pageControl.numberOfPages = 3;
	_pageControl.currentPage = 0;
	[_pageControl addTarget:self action:@selector(pageControlValueChanged:) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:_pageControl];

# Credits

`RGMPagingScrollView` is provided as-is by [Ryder Mackay][rgm]. If you’re using it in a project, I’d love to hear about it on [Twitter][twitter]. If you’d like to contribute (thanks!), please send a pull request or [open a new issue on GitHub][bug].

[rgm]: http://analogkid.ca "Ryder Mackay"
[twitter]: http://twitter.com/rydermackay "Twitter.com: Ryder Mackay"
[bug]: https://github.com/rydermackay/RGMPagingScrollView/issues/new "New Issue: rydermackay/RGMPagingScrollView"