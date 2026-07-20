#import "MAEditHistoryViewController.h"
#import "MAAPIClient.h"
#import "MATheme.h"
#import "MAHTMLRenderer.h"
#import "MALoadingView.h"
#import "MAEmptyStateView.h"

@interface MAEditHistoryViewController ()

@property (nonatomic, strong) MALoadingView *loadingView;
@property (nonatomic, strong) MAEmptyStateView *emptyView;

@end

@implementation MAEditHistoryViewController

- (instancetype)initWithStatusID:(NSString *)statusID {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _statusID = statusID;
        _edits = @[];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    return [self initWithStatusID:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Edit History";
    self.view.backgroundColor = [MATheme backgroundColor];
    self.tableView.backgroundColor = [MATheme backgroundColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 120;

    if (@available(iOS 9.0, *)) {
        self.tableView.cellLayoutMarginsFollowReadableWidth = NO;
    }

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"EditCell"];

    _loadingView = [[MALoadingView alloc] initWithFrame:self.view.bounds];
    _loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_loadingView];

    _emptyView = [[MAEmptyStateView alloc] initWithIcon:@"i" title:@"No Edit History" subtitle:@"This post has not been edited"];
    _emptyView.frame = self.view.bounds;
    _emptyView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _emptyView.hidden = YES;
    [self.view addSubview:_emptyView];

    [self loadHistory];
}

- (void)loadHistory {
    [_loadingView showWithMessage:@"Loading..."];

    [[MAAPIClient sharedClient] fetchEditHistoryForStatus:_statusID completion:^(NSArray *edits, NSError *error) {
        [self->_loadingView hide];

        if (error || edits.count == 0) {
            self->_emptyView.hidden = NO;
            return;
        }

        self->_edits = edits;
        [self.tableView reloadData];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _edits.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditCell" forIndexPath:indexPath];

    NSDictionary *edit = _edits[indexPath.row];

    NSString *content = edit[@"content"] ?: @"";
    NSString *spoilerText = edit[@"spoiler_text"] ?: @"";
    NSString *createdAt = edit[@"created_at"] ?: @"";

    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    inputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    inputFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    inputFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSDate *date = [inputFormatter dateFromString:createdAt];

    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    outputFormatter.dateStyle = NSDateFormatterMediumStyle;
    outputFormatter.timeStyle = NSDateFormatterShortStyle;
    NSString *dateString = date ? [outputFormatter stringFromDate:date] : createdAt;

    NSString *plainContent = [self stripHTML:content];

    NSMutableString *display = [NSMutableString string];
    if (spoilerText.length > 0) {
        [display appendFormat:@"[CW: %@]\n", spoilerText];
    }
    [display appendString:plainContent];

    UILabel *contentLabel = [[UILabel alloc] init];
    contentLabel.text = display;
    contentLabel.font = [MATheme fontWithSize:15];
    contentLabel.textColor = [MATheme textColor];
    contentLabel.numberOfLines = 0;

    UILabel *dateLabel = [[UILabel alloc] init];
    dateLabel.text = dateString;
    dateLabel.font = [MATheme fontWithSize:12];
    dateLabel.textColor = [MATheme secondaryTextColor];

    UIView *container = [[UIView alloc] init];

    UILabel *numberLabel = [[UILabel alloc] init];
    numberLabel.text = [NSString stringWithFormat:@"#%lu", (unsigned long)(_edits.count - indexPath.row)];
    numberLabel.font = [MATheme boldFontWithSize:14];
    numberLabel.textColor = [MATheme primaryColor];
    numberLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:numberLabel];

    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:contentLabel];

    dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:dateLabel];

    [NSLayoutConstraint activateConstraints:@[
        [numberLabel.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
        [numberLabel.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
        [numberLabel.widthAnchor constraintEqualToConstant:32],

        [contentLabel.leadingAnchor constraintEqualToAnchor:numberLabel.trailingAnchor constant:8],
        [contentLabel.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],
        [contentLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16],

        [dateLabel.leadingAnchor constraintEqualToAnchor:numberLabel.trailingAnchor constant:8],
        [dateLabel.topAnchor constraintEqualToAnchor:contentLabel.bottomAnchor constant:6],
        [dateLabel.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16],
        [dateLabel.bottomAnchor constraintEqualToAnchor:container.bottomAnchor constant:-12],
    ]];

    cell.contentView.backgroundColor = [MATheme cardColor];
    cell.backgroundColor = [MATheme cardColor];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    for (UIView *subview in cell.contentView.subviews) {
        [subview removeFromSuperview];
    }
    container.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:container];
    [NSLayoutConstraint activateConstraints:@[
        [container.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor],
        [container.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor],
        [container.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor],
        [container.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor],
    ]];

    return cell;
}

- (NSString *)stripHTML:(NSString *)html {
    if (!html) return @"";
    NSMutableString *result = [NSMutableString string];
    NSScanner *scanner = [NSScanner scannerWithString:html];
    while (![scanner isAtEnd]) {
        NSString *text = nil;
        [scanner scanUpToString:@"<" intoString:&text];
        if (text) [result appendString:text];
        [scanner scanUpToString:@">" intoString:NULL];
        [scanner scanString:@">" intoString:NULL];
    }
    return [result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
