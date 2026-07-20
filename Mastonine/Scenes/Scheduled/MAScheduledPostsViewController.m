#import "MAScheduledPostsViewController.h"
#import "MAAPIClient.h"
#import "MATheme.h"

@interface MAScheduledPostsViewController ()

@property (nonatomic, strong) NSMutableArray *scheduledPosts;
@property (nonatomic, assign) BOOL isLoading;

@end

@implementation MAScheduledPostsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Scheduled Posts";
    self.tableView.backgroundColor = [MATheme backgroundColor];

    self.scheduledPosts = [NSMutableArray array];

    UIRefreshControl *rc = [[UIRefreshControl alloc] init];
    [rc addTarget:self action:@selector(refreshPosts) forControlEvents:UIControlEventValueChanged];
    rc.tintColor = [MATheme accentColor];
    self.refreshControl = rc;

    [self loadScheduledPosts];
}

#pragma mark - Data Loading

- (void)loadScheduledPosts {
    if (self.isLoading) return;
    self.isLoading = YES;

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/scheduled_statuses", [MAAPIClient sharedClient].baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:[NSString stringWithFormat:@"Bearer %@", [MAAPIClient sharedClient].accessToken] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = @"GET";

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            strongSelf.isLoading = NO;
            [strongSelf.refreshControl endRefreshing];

            if (error) {
                return;
            }

            NSError *jsonError = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            if (jsonError || ![jsonArray isKindOfClass:[NSArray class]]) {
                return;
            }

            [strongSelf.scheduledPosts removeAllObjects];
            [strongSelf.scheduledPosts addObjectsFromArray:jsonArray];
            [strongSelf.tableView reloadData];
        });
    }];
    [task resume];
}

- (void)refreshPosts {
    self.isLoading = NO;
    [self loadScheduledPosts];
}

#pragma mark - Delete

- (void)deleteScheduledPostAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *post = self.scheduledPosts[indexPath.row];
    NSString *postId = post[@"id"];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/scheduled_statuses/%@", [MAAPIClient sharedClient].baseURL, postId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:[NSString stringWithFormat:@"Bearer %@", [MAAPIClient sharedClient].accessToken] forHTTPHeaderField:@"Authorization"];
    request.HTTPMethod = @"DELETE";

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf) return;

            if (error) {
                [strongSelf loadScheduledPosts];
                return;
            }

            [strongSelf.scheduledPosts removeObjectAtIndex:indexPath.row];
            [strongSelf.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        });
    }];
    [task resume];
}

#pragma mark - Cancel Post Action

- (void)cancelScheduledPostAtIndexPath:(NSIndexPath *)indexPath {
    [self deleteScheduledPostAtIndexPath:indexPath];
}

#pragma mark - Date Formatting

- (NSString *)formattedDateString:(NSString *)isoDateString {
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    inputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    inputFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    inputFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSDate *date = [inputFormatter dateFromString:isoDateString];

    if (!date) {
        inputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        date = [inputFormatter dateFromString:isoDateString];
    }

    if (!date) return isoDateString;

    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
    outputFormatter.dateStyle = NSDateFormatterMediumStyle;
    outputFormatter.timeStyle = NSDateFormatterShortStyle;
    return [NSString stringWithFormat:@"Scheduled for: %@", [outputFormatter stringFromDate:date]];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.scheduledPosts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"ScheduledPostCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }

    NSDictionary *post = self.scheduledPosts[indexPath.row];
    NSDictionary *params = post[@"params"];
    NSString *text = params[@"text"];
    NSString *scheduledAt = post[@"scheduled_at"];

    cell.textLabel.text = text;
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    cell.detailTextLabel.text = [self formattedDateString:scheduledAt];
    cell.detailTextLabel.textColor = [MATheme secondaryTextColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [MATheme cardColor];

    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil
                                                                        message:nil
                                                                 preferredStyle:UIAlertControllerStyleActionSheet];

    __weak typeof(self) weakSelf = self;
    UIAlertAction *cancelPostAction = [UIAlertAction actionWithTitle:@"Cancel Post"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
        [weakSelf cancelScheduledPostAtIndexPath:indexPath];
    }];

    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss"
                                                            style:UIAlertActionStyleCancel
                                                          handler:nil];

    [actionSheet addAction:cancelPostAction];
    [actionSheet addAction:dismissAction];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        actionSheet.popoverPresentationController.sourceView = cell;
        actionSheet.popoverPresentationController.sourceRect = cell.bounds;
    }

    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self deleteScheduledPostAtIndexPath:indexPath];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"Delete";
}

@end
