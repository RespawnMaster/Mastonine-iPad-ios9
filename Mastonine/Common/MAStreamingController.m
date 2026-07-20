#import "MAStreamingController.h"

NSString *const MAStreamingDidReceiveStatus = @"MAStreamingDidReceiveStatus";
NSString *const MAStreamingDidReceiveNotification = @"MAStreamingDidReceiveNotification";
NSString *const MAStreamingDidDeleteStatus = @"MAStreamingDidDeleteStatus";
NSString *const MAStreamingDidUpdateStatus = @"MAStreamingDidUpdateStatus";

static const NSTimeInterval kInitialReconnectDelay = 3.0;
static const NSTimeInterval kMaxReconnectDelay = 300.0;

@interface MAStreamingController () <NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSString *baseURL;
@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSURLConnection *currentConnection;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@property (nonatomic, strong) NSTimer *reconnectTimer;
@property (nonatomic, assign) NSTimeInterval currentReconnectDelay;

@end

@implementation MAStreamingController

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        _isConnected = NO;
        _isUserStream = NO;
        _dataBuffer = [NSMutableData data];
        _currentReconnectDelay = kInitialReconnectDelay;
    }
    return self;
}

- (void)dealloc {
    [self cancelReconnectTimer];
    [_currentConnection cancel];
}

#pragma mark - Public

- (void)connectToTimeline:(NSString *)timelineType {
    [self disconnect];
    self.isUserStream = NO;
    self.currentTimelineType = timelineType;
    self.currentReconnectDelay = kInitialReconnectDelay;
    [self startConnection];
}

- (void)connectToUserStream {
    [self disconnect];
    self.isUserStream = YES;
    self.currentTimelineType = @"user";
    self.currentReconnectDelay = kInitialReconnectDelay;
    [self startConnection];
}

- (void)disconnect {
    [self cancelReconnectTimer];
    [self.currentConnection cancel];
    self.currentConnection = nil;
    self.isConnected = NO;
    self.dataBuffer.length = 0;
}

#pragma mark - Private

- (void)startConnection {
    if (self.baseURL.length == 0 || self.accessToken.length == 0) {
        return;
    }

    NSString *endpoint;
    if (self.isUserStream) {
        endpoint = @"/api/v1/streaming/user";
    } else {
        endpoint = [NSString stringWithFormat:@"/api/v1/streaming/%@", self.currentTimelineType];
    }

    NSString *urlString = [NSString stringWithFormat:@"%@%@?access_token=%@",
                           self.baseURL, endpoint, self.accessToken];

    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    if (self.accessToken.length > 0) {
        NSString *authValue = [NSString stringWithFormat:@"Bearer %@", self.accessToken];
        [request addValue:authValue forHTTPHeaderField:@"Authorization"];
    }
    [request addValue:@"text/event-stream" forHTTPHeaderField:@"Accept"];
    [request addValue:@"no-cache" forHTTPHeaderField:@"Cache-Control"];

    self.dataBuffer.length = 0;
    self.currentConnection = [NSURLConnection connectionWithRequest:request delegate:self];
    self.isConnected = YES;
}

- (void)reconnectAfterDelay:(NSTimeInterval)delay {
    [self cancelReconnectTimer];

    self.reconnectTimer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                          target:self
                                                        selector:@selector(reconnectTimerFired)
                                                        userInfo:nil
                                                         repeats:NO];
}

- (void)reconnectTimerFired {
    self.reconnectTimer = nil;
    if (self.baseURL.length > 0 && self.accessToken.length > 0) {
        self.dataBuffer.length = 0;
        [self startConnection];
    }
}

- (void)cancelReconnectTimer {
    [self.reconnectTimer invalidate];
    self.reconnectTimer = nil;
}

#pragma mark - SSE Parsing

- (void)processBufferedData {
    while (YES) {
        NSData *doubleNewline = [@"\n\n" dataUsingEncoding:NSUTF8StringEncoding];
        NSRange range = [self.dataBuffer rangeOfData:doubleNewline
                                             options:0
                                               range:NSMakeRange(0, self.dataBuffer.length)];

        if (range.location == NSNotFound) {
            break;
        }

        NSData *eventBlock = [self.dataBuffer subdataWithRange:NSMakeRange(0, range.location)];

        NSUInteger consumed = range.location + range.length;
        [self.dataBuffer replaceBytesInRange:NSMakeRange(0, consumed)
                                   withBytes:NULL
                                      length:0];

        [self parseEventBlock:eventBlock];
    }
}

- (void)parseEventBlock:(NSData *)blockData {
    NSString *blockString = [[NSString alloc] initWithData:blockData encoding:NSUTF8StringEncoding];
    if (blockString.length == 0) {
        return;
    }

    NSString *eventType = nil;
    NSString *dataString = nil;

    NSArray *lines = [blockString componentsSeparatedByString:@"\n"];
    for (NSString *rawLine in lines) {
        NSString *line = [rawLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (line.length == 0) {
            continue;
        }

        if ([line hasPrefix:@"event: "]) {
            eventType = [line substringFromIndex:7];
        } else if ([line hasPrefix:@"data: "]) {
            dataString = [line substringFromIndex:6];
        }
    }

    if (eventType.length == 0 || dataString.length == 0) {
        return;
    }

    if ([eventType isEqualToString:@"update"]) {
        NSData *jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSDictionary *statusDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                  options:0
                                                                    error:&jsonError];
        if (statusDict && !jsonError) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:MAStreamingDidReceiveStatus
             object:self
             userInfo:@{@"status": statusDict}];
        }
    } else if ([eventType isEqualToString:@"delete"]) {
        [[NSNotificationCenter defaultCenter]
         postNotificationName:MAStreamingDidDeleteStatus
         object:self
         userInfo:@{@"statusID": dataString}];
    } else if ([eventType isEqualToString:@"notification"]) {
        NSData *jsonData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError = nil;
        NSDictionary *notificationDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                        options:0
                                                                          error:&jsonError];
        if (notificationDict && !jsonError) {
            [[NSNotificationCenter defaultCenter]
             postNotificationName:MAStreamingDidReceiveNotification
             object:self
             userInfo:@{@"notification": notificationDict}];
        }
    } else if ([eventType isEqualToString:@"heartbeat"]) {
        // Silence is golden
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection
didReceiveResponse:(NSURLResponse *)response {
    self.dataBuffer.length = 0;

    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            [connection cancel];
            self.isConnected = NO;
            [self reconnectAfterDelay:self.currentReconnectDelay];
            self.currentReconnectDelay = MIN(self.currentReconnectDelay * 2, kMaxReconnectDelay);
        }
    }
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data {
    if (data.length == 0) {
        return;
    }

    [self.dataBuffer appendData:data];
    [self processBufferedData];
    self.currentReconnectDelay = kInitialReconnectDelay;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    self.isConnected = NO;
    self.currentConnection = nil;

    [self processBufferedData];

    [self reconnectAfterDelay:kInitialReconnectDelay];
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error {
    self.isConnected = NO;
    self.currentConnection = nil;

    [self reconnectAfterDelay:self.currentReconnectDelay];
    self.currentReconnectDelay = MIN(self.currentReconnectDelay * 2, kMaxReconnectDelay);
}

#pragma mark - Configuration

- (void)setBaseURL:(NSString *)baseURL accessToken:(NSString *)accessToken {
    self.baseURL = baseURL;
    self.accessToken = accessToken;
}

@end
