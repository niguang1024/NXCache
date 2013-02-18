//
//  NXCache.h
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXCacheDefine.h"


@class NXCache;

@protocol NXCacheDelegate <NSObject>
@optional
- (void)cache:(NXCache *)cache didFindData:(NSData *)data forKey:(NSString *)key userInfo:(NSDictionary *)info;
- (void)cache:(NXCache *)cache didNotFindDataForKey:(NSString *)key userInfo:(NSDictionary *)info;
@end

@interface NXCache : NSObject {
    NSMutableDictionary *memCache;
    NSString *diskCachePath;
    NSOperationQueue *cacheInQueue, *cacheOutQueue;
}

+ (NXCache *)sharedCache;
- (void)storeData:(NSData *)data forKey:(NSString *)key;
- (void)storeData:(NSData *)data forKey:(NSString *)key toDisk:(BOOL)toDisk;
- (void)storeData:(NSData *)data data:(NSData *)oldData forKey:(NSString *)key toDisk:(BOOL)toDisk;

- (NSData *)dataFromKey:(NSString *)key;
- (NSData *)dataFromKey:(NSString *)key fromDisk:(BOOL)fromDisk;
- (void)queryDiskCacheForKey:(NSString *)key delegate:(id <NXCacheDelegate>)delegate userInfo:(NSDictionary *)info;

- (void)removeImageForKey:(NSString *)key;
- (void)clearMemory;
- (void)cleanDisk;// 按缓存日期清理
- (void)clearDisk;// 全部清空缓存

@end
