#import "MAImageViewerController.h"
#import "MAImageCache.h"

@interface MAImageViewerController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *pageLabel;
@property (nonatomic, strong) NSMutableArray *imageViews;

@end

@implementation MAImageViewerController

- (instancetype)initWithImageURLs:(NSArray *)urls initialIndex:(NSInteger)index {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _imageURLs = urls ?: @[];
        _initialIndex = index;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.pagingEnabled = YES;
    _scrollView.delegate = self;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scrollView];

    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height;

    _scrollView.contentSize = CGSizeMake(w * _imageURLs.count, h);
    _scrollView.contentOffset = CGPointMake(w * _initialIndex, 0);

    _imageViews = [NSMutableArray array];

    for (NSInteger i = 0; i < (NSInteger)_imageURLs.count; i++) {
        UIScrollView *zoomScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(w * i, 0, w, h)];
        zoomScroll.delegate = self;
        zoomScroll.maximumZoomScale = 3.0;
        zoomScroll.minimumZoomScale = 1.0;
        zoomScroll.showsHorizontalScrollIndicator = NO;
        zoomScroll.showsVerticalScrollIndicator = NO;
        [_scrollView addSubview:zoomScroll];

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.clipsToBounds = YES;
        imageView.tag = 100;
        [zoomScroll addSubview:imageView];
        [_imageViews addObject:imageView];

        NSURL *url = [NSURL URLWithString:_imageURLs[i]];
        if (url) {
            [[MAImageCache sharedCache] fetchImageAtURL:url completion:^(UIImage *image) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    imageView.image = image;
                });
            }];
        }
    }

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];

    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapped:)];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.view addGestureRecognizer:singleTap];

    if (_imageURLs.count > 1) {
        _pageLabel = [[UILabel alloc] init];
        _pageLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _pageLabel.textColor = [UIColor whiteColor];
        _pageLabel.font = [UIFont systemFontOfSize:14];
        _pageLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:_pageLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_pageLabel.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-40],
            [_pageLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        ]];
        [self updatePageLabel];
    }

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [closeButton setTitle:@"Done" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];

    [NSLayoutConstraint activateConstraints:@[
        [closeButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:30],
        [closeButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)singleTapped:(UITapGestureRecognizer *)gesture {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doubleTapped:(UITapGestureRecognizer *)gesture {
    CGPoint point = [gesture locationInView:self.view];
    NSInteger page = (NSInteger)(point.x / self.view.frame.size.width);
    if (page >= 0 && page < (NSInteger)_scrollView.subviews.count) {
        UIScrollView *zoomScroll = _scrollView.subviews[page];
        if (zoomScroll.zoomScale > 1.0) {
            [zoomScroll setZoomScale:1.0 animated:YES];
        } else {
            CGFloat w = self.view.frame.size.width;
            CGFloat h = self.view.frame.size.height;
            CGFloat newScale = 2.0;
            CGFloat scrollW = w / newScale;
            CGFloat scrollH = h / newScale;
            [zoomScroll zoomToRect:CGRectMake(point.x - scrollW / 2, point.y - scrollH / 2, scrollW, scrollH) animated:YES];
        }
    }
}

- (void)updatePageLabel {
    NSInteger page = (NSInteger)(_scrollView.contentOffset.x / _scrollView.frame.size.width + 0.5);
    _pageLabel.text = [NSString stringWithFormat:@"%ld / %ld", (long)(page + 1), (long)_imageURLs.count];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == _scrollView) {
        [self updatePageLabel];
    }
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    if (scrollView != _scrollView) {
        return [scrollView viewWithTag:100];
    }
    return nil;
}

@end
