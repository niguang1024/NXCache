//
//  NXCacheManager.m
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NXCacheManager.h"

#define CACHED_Runtime_DIR [NSString stringWithFormat:@"%@/Runtime", CACHE_DIR]
#define CACHED_Bytime_DIR [NSString stringWithFormat:@"%@/Bytime", CACHE_DIR]

static NXCacheManager *instance = nil;

@implementation NXCacheManager

- (void)dealloc {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [downloadDelegates release];
    downloadDelegates = nil;
    [downloaders release];
    downloaders = nil;
    [cacheDelegates release];
    cacheDelegates = nil;
    [downloaderForURL release];
     downloaderForURL = nil;
    [failedURLs release];
    failedURLs = nil;
    [super dealloc];
}

- (id)init {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if ((self = [super init])) {
        downloadDelegates = [[NSMutableArray alloc] init];
        downloaders = [[NSMutableArray alloc] init];
        cacheDelegates = [[NSMutableArray alloc] init];
        downloaderForURL = [[NSMutableDictionary alloc] init];
        failedURLs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)loadWithURL:(NSURL *)url delegate:(id<NXCacheManagerDelegate>)delegate {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self loadWithURL:url delegate:delegate retryFailed:NO];
}
- (void)loadWithURL:(NSURL *)url delegate:(id<NXCacheManagerDelegate>)delegate retryFailed:(BOOL)retryFailed {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self loadWithURL:url delegate:delegate retryFailed:retryFailed lowPriority:NO];
}
- (void)loadWithURL:(NSURL *)url delegate:(id<NXCacheManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (!url || !delegate || (!retryFailed && [failedURLs containsObject:url])) {
        return;
    }
    // 检查磁盘上的缓存，异步(所以不阻塞主线程)
    [cacheDelegates addObject:delegate];
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:delegate, @"delegate", url, @"url", [NSNumber numberWithBool:lowPriority], @"low_priority", nil];
    [[NXCache sharedCache] queryDiskCacheForKey:[url absoluteString] delegate:self userInfo:info];
}
- (void)cancelForDelegate:(id<NXCacheManagerDelegate>)delegate {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    // 删除从cacheDelegates委托的所有和参数相同的实例。
    [cacheDelegates removeObjectIdenticalTo:delegate];
    
    NSUInteger idx;
    while ((idx = [downloadDelegates indexOfObjectIdenticalTo:delegate]) != NSNotFound) {
        NXDownloader *downloader = [[downloaders objectAtIndex:idx] retain];
        [downloadDelegates removeObjectAtIndex:idx];
        [downloaders removeObjectAtIndex:idx];
        
        if (![downloaders containsObject:downloader]) {
            [downloader cancel];
            [downloaderForURL removeObjectForKey:downloader.url];
        }
        [downloader release];
    }
}

#pragma mark NXCacheDelegate
- (void)cache:(NXCache *)cache didFindData:(NSData *)data forKey:(NSString *)key userInfo:(NSDictionary *)info {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    id<NXCacheManagerDelegate> delegate = [info objectForKey:@"delegate"];
    
    NSUInteger idx = [cacheDelegates indexOfObjectIdenticalTo:delegate];
    if (idx == NSNotFound) {// 已经取消了
        return;
    }
    
    if ([delegate respondsToSelector:@selector(cacheManager:didFinishWithData:)]) {
        [delegate performSelector:@selector(cacheManager:didFinishWithData:) withObject:self withObject:data];
    }
    [cacheDelegates removeObjectAtIndex:idx];
}
- (void)cache:(NXCache *)cache didNotFindDataForKey:(NSString *)key userInfo:(NSDictionary *)info {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSURL *url = [info objectForKey:@"url"];
    id<NXCacheManagerDelegate> delegate = [info objectForKey:@"delegate"];
    BOOL lowPriority = [[info objectForKey:@"low_priority"] boolValue];
    
    NSUInteger idx = [cacheDelegates indexOfObjectIdenticalTo:delegate];
    if (idx == NSNotFound) {// 已经取消了
        return;
    }
    
    [cacheDelegates removeObjectAtIndex:idx];
    
    // 如果正在下载，则不再重复下载
    NXDownloader *downloader = [downloaderForURL objectForKey:url];
    if (!downloader) {
        downloader = [NXDownloader downloaderWithURL:url delegate:self userInfo:nil lowPriority:lowPriority];
        [downloaderForURL setObject:downloader forKey:url];
    }
    
    if (!lowPriority && downloader.lowPriority) {
        downloader.lowPriority = NO;
    }
    
    [downloadDelegates addObject:delegate];
    [downloaders addObject:downloader];
}

#pragma mark NXDownloaderDelegate
- (void)dataDownloaderDidFinish:(NXDownloader *)downloader {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    //NSLog(@"%@", @"dataDownloaderDidFinish");
}
- (void)dataDownloader:(NXDownloader *)downloader didFinishWithData:(NSData *)data {
    [downloader retain];
    
    // 通知所有downloadDelegates
    for (NSInteger idx = (NSInteger)[downloaders count] - 1; idx >= 0; idx--) {
        NSUInteger uidx = (NSUInteger)idx;
        NXDownloader *aDownloader = [downloaders objectAtIndex:uidx];
        if (aDownloader == downloader) {
            id<NXCacheManagerDelegate> delegate = [downloadDelegates objectAtIndex:uidx];
            if (data) {
                if ([delegate respondsToSelector:@selector(cacheManager:didFinishWithData:)]) {
                    [delegate performSelector:@selector(cacheManager:didFinishWithData:) withObject:self withObject:data];
                }
            }
            else {
                if ([delegate respondsToSelector:@selector(cacheManager:didFailWithError:)]) {
                    [delegate performSelector:@selector(cacheManager:didFailWithError:) withObject:self withObject:nil];
                }
            }
            [downloaders removeObjectAtIndex:uidx];
            [downloadDelegates removeObjectAtIndex:uidx];
        }
    }
    
    if (data) {
        // 缓存
        [[NXCache sharedCache] storeData:data data:downloader.data forKey:[downloader.url absoluteString] toDisk:YES];
    }
    else {
        // 标记已经坏链失败的
        [failedURLs addObject:downloader.url];
    }
    
    [downloaderForURL removeObjectForKey:downloader.url];
    [downloader release];
}
- (void)dataDownloader:(NXDownloader *)downloader didFailWithError:(NSError *)error {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [downloader retain];
    
    // 通知所有downloadDelegates
    for (NSInteger idx = (NSInteger)[downloaders count] - 1; idx >= 0; idx--) {
        NSUInteger uidx = (NSUInteger)idx;
        NXDownloader *aDownloader = [downloaders objectAtIndex:uidx];
        if (aDownloader == downloader) {
            id<NXCacheManagerDelegate> delegate = [downloadDelegates objectAtIndex:uidx];
            if ([delegate respondsToSelector:@selector(cacheManager:didFailWithError:)]) {
                [delegate performSelector:@selector(cacheManager:didFailWithError:) withObject:self withObject:error];
            }
            [downloaders removeObjectAtIndex:uidx];
            [downloadDelegates removeObjectAtIndex:uidx];
        }
    }
    
    [downloaderForURL removeObjectForKey:downloader.url];
    [downloader release];
}

#pragma mark - Singlton
+ (NXCacheManager *)sharedManager {
    @synchronized(self) {
        if (instance == nil) {
            [[self alloc] init];
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
