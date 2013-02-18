//
//  NXDownloader.m
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NXDownloader.h"

NSString *const DataDownloadStartNotification = @"DataDownloadStartNotification";
NSString *const DataDownloadStopNotification = @"DataDownloadStopNotification";

@interface NXDownloader( )
@property (nonatomic, retain) NSURLConnection *connection;
@end

#pragma mark - ======NXDownloader====== -

@implementation NXDownloader

@synthesize url, delegate, connection, data, userInfo, lowPriority;

- (void)dealloc {NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [url release];
    url = nil;
    [connection release];
    connection = nil;
    [data release];
    data = nil;
    [userInfo release];
    userInfo = nil;
    [super dealloc];
}

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<NXDownloaderDelegate>)delegate userInfo:(id)userInfo lowPriority:(BOOL)lowPriority {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    NXConuntableActivityIndicatorControl *activityIndicatorControl = [NXConuntableActivityIndicatorControl sharedActivityIndicatorControl];
    [[NSNotificationCenter defaultCenter] addObserver:activityIndicatorControl selector:@selector(startActivity) name:DataDownloadStartNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:activityIndicatorControl selector:@selector(stopActivity) name:DataDownloadStopNotification object:nil];
    
    NXDownloader *downloader = [[[NXDownloader alloc] init] autorelease];
    downloader.url = url;
    downloader.delegate = delegate;
    downloader.userInfo = userInfo;
    downloader.lowPriority = lowPriority;
    [downloader performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:YES];
    return downloader;
}
+ (id)downloaderWithURL:(NSURL *)url delegate:(id<NXDownloaderDelegate>)delegate userInfo:(id)userInfo {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return [self downloaderWithURL:url delegate:delegate userInfo:userInfo lowPriority:NO];
}
+ (id)downloaderWithURL:(NSURL *)url delegate:(id<NXDownloaderDelegate>)delegate {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return [self downloaderWithURL:url delegate:delegate userInfo:nil];
}
- (void)start {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:15];
    self.connection = [[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO] autorelease];
    
    // NSURLConnection的runloop模式是NSEventTrackingRunLoopMode，修改。以确保在高优先级时，不被UI阻塞。
    if (!lowPriority) {
        [connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    [connection start];
    [request release];
    
    if (connection) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DataDownloadStartNotification object:nil];
    }
    else {
        if ([delegate respondsToSelector:@selector(dataDownloader:didFailWithError:)]) {
            [delegate performSelector:@selector(dataDownloader:didFailWithError:) withObject:self withObject:nil];
        }
    }
}
- (void)cancel {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (connection) {
        [connection cancel];
        self.connection = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:DataDownloadStopNotification object:nil];
    }
}

#pragma mark NSURLConnection (delegate)

- (void)connection:(NSURLConnection *)aConnection didReceiveData:(NSData *)aData {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (data == nil) {
        data = [[NSMutableData alloc] initWithCapacity:2048];
    }
    [data appendData:aData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    self.connection = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:DataDownloadStopNotification object:nil];
    
    if ([delegate respondsToSelector:@selector(dataDownloaderDidFinish:)]) {
        [delegate performSelector:@selector(dataDownloaderDidFinish:) withObject:self];
    }
    
    if ([delegate respondsToSelector:@selector(dataDownloader:didFinishWithData:)]) {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
        [delegate performSelector:@selector(dataDownloader:didFinishWithData:) withObject:self withObject:data];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] postNotificationName:DataDownloadStopNotification object:nil];
    
    if ([delegate respondsToSelector:@selector(dataDownloader:didFailWithError:)]) {
        [delegate performSelector:@selector(dataDownloader:didFailWithError:) withObject:self withObject:error];
    }
    self.connection = nil;
    self.data = nil;
}

@end


#pragma mark - ======NXConuntableActivityIndicatorControl====== -

static NXConuntableActivityIndicatorControl *instance;
@implementation NXConuntableActivityIndicatorControl

- (id)init {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if ((self = [super init])) {
        counter = 0;
    }
    return self;
}

- (void)startActivity {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    @synchronized(self) {
        if (counter == 0) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        }
        counter++;
    }
}
- (void)stopActivity {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    @synchronized(self) {
        if (counter > 0 && --counter == 0) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        }
    }
}
- (void)stopAllActivity {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    @synchronized(self) {
        counter = 0;
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
}

#pragma mark - Singlton
+ (NXConuntableActivityIndicatorControl *)sharedActivityIndicatorControl {
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (instance == nil) {
            instance = [super allocWithZone:zone];
            return instance;
        }
    }
    return nil;
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (id)retain {
    return self;
}
- (unsigned)retainCount {
    return UINT_MAX;
}
- (id)autorelease {
    return self;
}
- (oneway void)release {}

@end
