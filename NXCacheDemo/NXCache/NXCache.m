//
//  NXCache.m
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NXCache.h"
#import <CommonCrypto/CommonDigest.h>

#define CACHE_MAX_Time  ((60 * 60 * 24) * CACHE_MAX_DAY)

static NXCache *sharedSinglton = nil;

@interface NXCache ( )

- (NSString *)cachePathForKey:(NSString *)key;
- (void)storeKeyWithDataToDisk:(NSArray *)keyAndData;

@end


@implementation NXCache

- (void)dealloc {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [memCache release];
    memCache = nil;
    [diskCachePath release];
    diskCachePath = nil;
    [cacheInQueue release];
    cacheInQueue = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super dealloc];
}

- (id)init {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if ((self = [super init])) {
        /**
          * 初始化
          */
        {
            // 初始化-缓存字典
            memCache = [[NSMutableDictionary alloc] init];
            
            // 初始化-存储路径
            diskCachePath = [CACHE_DIR retain];
            if (![[NSFileManager defaultManager] fileExistsAtPath:diskCachePath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
            }
            
            // 初始化-操作队列
            cacheInQueue = [[NSOperationQueue alloc] init];
            cacheInQueue.maxConcurrentOperationCount = 1;
            cacheOutQueue = [[NSOperationQueue alloc] init];
            cacheOutQueue.maxConcurrentOperationCount = 1;
        }
        
        /**
         * 处理系统通知
         */
        {
            // 处理系统通知-内存警告
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemory) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
            // 处理系统通知-退出程序（<4.0）
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cleanDisk) name:UIApplicationWillTerminateNotification object:nil];
            // 处理系统通知-转入后台（>=4.0）
            UIDevice *device = [UIDevice currentDevice];
            if ([device respondsToSelector:@selector(isMultitaskingSupported)] && device.multitaskingSupported) {
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearMemory) name:UIApplicationDidEnterBackgroundNotification object:nil];
            }
        }
    }
    return self;
}

#pragma mark - Private
/**
 * MD5加密生成缓存文件名
 */
- (NSString *)cachePathForKey:(NSString *)key {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    const char *str = [key UTF8String];
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    return [diskCachePath stringByAppendingPathComponent:filename];
}
/**
 * 根据key和data存储缓存文件
 */
- (void)storeKeyWithDataToDisk:(NSArray *)keyAndData {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    // 防止冲突，重新生成一个FileManager
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *key = [keyAndData objectAtIndex:0];
    NSData *data = [keyAndData count] > 1 ? [keyAndData objectAtIndex:1] : nil;
    
    if (data) {
        [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
    }
    else {
        NSData *data = [[self dataFromKey:key fromDisk:YES] retain];
        if (data) {
            [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
            [data release];
        }
    }
    [fileManager release];
}
/**
 * Delegate消息
 */
- (void)notifyDelegate:(NSDictionary *)arguments {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSString *key = [arguments objectForKey:@"key"];
    id<NXCacheDelegate> delegate = [arguments objectForKey:@"delegate"];
    NSDictionary *info = [arguments objectForKey:@"userInfo"];
    NSData *data = [arguments objectForKey:@"data"];
    if (data) {
        [memCache setObject:data forKey:key];
        if ([delegate respondsToSelector:@selector(cache:didFindData:forKey:userInfo:)]) {
            [delegate cache:self didFindData:data forKey:key userInfo:info];
        }
    }
    else {
        if ([delegate respondsToSelector:@selector(cache:didNotFindDataForKey:userInfo:)]) {
            [delegate cache:self didNotFindDataForKey:key userInfo:info];
        }
    }
}
- (void)queryDiskCacheOperation:(NSDictionary *)arguments {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSString *key = [arguments objectForKey:@"key"];
    NSMutableDictionary *mutableArguments = [[arguments mutableCopy] autorelease];
    NSData *data = [[[NSData alloc] initWithContentsOfFile:[self cachePathForKey:key]] autorelease];
    if (data) {
        [mutableArguments setObject:data forKey:@"data"];
    }
    [self performSelectorOnMainThread:@selector(notifyDelegate:) withObject:mutableArguments waitUntilDone:NO];
}

#pragma mark - Interface
- (void)storeData:(NSData *)data data:(NSData *)oldData forKey:(NSString *)key toDisk:(BOOL)toDisk {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (!data || !key) {
        return;
    }
    if (toDisk && !data) {
        return;
    }
    
    [memCache setObject:data forKey:key];
    
    if (toDisk) {
        NSArray *keyWithData;
        if (data) {
            keyWithData = [NSArray arrayWithObjects:key, oldData, nil];
        }
        else {
            keyWithData = [NSArray arrayWithObjects:key, nil];
        }
        [cacheInQueue addOperation:[[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(storeKeyWithDataToDisk:) object:keyWithData] autorelease]];
    }
}
- (void)storeData:(NSData *)data forKey:(NSString *)key {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self storeData:data data:nil forKey:key toDisk:YES];
}
- (void)storeData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [self storeData:data data:nil forKey:key toDisk:YES];
}
- (NSData *)dataFromKey:(NSString *)key {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return [self dataFromKey:key fromDisk:YES];
}
- (NSData *)dataFromKey:(NSString *)key fromDisk:(BOOL)fromDisk {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (key == nil) {
        return nil;
    }
    NSData *data = [memCache objectForKey:key];
    if (!data && fromDisk) {
        data = [[[NSData alloc] initWithContentsOfFile:[self cachePathForKey:key]] autorelease];
        if (data) {
            [memCache setObject:data forKey:key];
        }
    }
    return data;
}
- (void)queryDiskCacheForKey:(NSString *)key delegate:(id <NXCacheDelegate>)delegate userInfo:(NSDictionary *)info {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (!delegate) {
        return;
    }
    
    if (!key) {
        if ([delegate respondsToSelector:@selector(cache:didNotFindDataForKey:userInfo:)]) {
            [delegate cache:self didNotFindDataForKey:key userInfo:info];
        }
        return;
    }
    
    // 首次检查缓存
    NSData *data = [memCache objectForKey:key];
    if (data) {
        // 发送通知，不需要下载
        if ([delegate respondsToSelector:@selector(cache:didFindData:forKey:userInfo:)]) {
            [delegate cache:self didFindData:data forKey:key userInfo:info];
        }
        return;
    }
    
    NSMutableDictionary *arguments = [NSMutableDictionary dictionaryWithCapacity:3];
    [arguments setObject:key forKey:@"key"];
    [arguments setObject:delegate forKey:@"delegate"];
    if (info) {
        [arguments setObject:info forKey:@"userInfo"];
    }
    [cacheOutQueue addOperation:[[[NSInvocationOperation alloc] initWithTarget:self selector:@selector(queryDiskCacheOperation:) object:arguments] autorelease]];
}

- (void)removeImageForKey:(NSString *)key {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (key == nil) {
        return;
    }
    [memCache removeObjectForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
}
- (void)clearMemory {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [cacheInQueue cancelAllOperations];
    [memCache removeAllObjects];
}
- (void)clearDisk {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    [cacheInQueue cancelAllOperations];
    [[NSFileManager defaultManager] removeItemAtPath:diskCachePath error:nil];
    [[NSFileManager defaultManager] createDirectoryAtPath:diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
}
- (void)cleanDisk {//NSLog(@"%@-%@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:0 - CACHE_MAX_Time];
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        if ([[[attrs fileModificationDate] laterDate:expirationDate] isEqualToDate:expirationDate]) {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }
}

#pragma mark - siglton
+ (NXCache *)sharedCache {
    @synchronized(self) {
        if (sharedSinglton == nil) {
            sharedSinglton = [[self alloc] init];
        }
    }
    return sharedSinglton;
}
+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedSinglton == nil) {
            sharedSinglton = [super allocWithZone:zone];
            return sharedSinglton;
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
