//
//  NXCacheManager.h
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXCacheDefine.h"
#import "NXCache.h"
#import "NXDownloader.h"

@class NXCacheManager;
@protocol NXCacheManagerDelegate <NSObject>
@optional
- (void)cacheManager:(NXCacheManager *)cacheManager didFinishWithData:(NSData *)data;
- (void)cacheManager:(NXCacheManager *)cacheManager didFailWithError:(NSError *)error;
@end

@interface NXCacheManager : NSObject<NXCacheDelegate, NXDownloaderDelegate> {
    NSMutableArray *downloadDelegates;
    NSMutableArray *downloaders;
    NSMutableArray *cacheDelegates;
    NSMutableDictionary *downloaderForURL;
    NSMutableArray *failedURLs;
}

+ (id)sharedManager;

- (void)loadWithURL:(NSURL *)url delegate:(id<NXCacheManagerDelegate>)delegate;
- (void)loadWithURL:(NSURL *)url delegate:(id<NXCacheManagerDelegate>)delegate retryFailed:(BOOL)retryFailed;
- (void)loadWithURL:(NSURL *)url delegate:(id<NXCacheManagerDelegate>)delegate retryFailed:(BOOL)retryFailed lowPriority:(BOOL)lowPriority;
- (void)cancelForDelegate:(id<NXCacheManagerDelegate>)delegate;

@end
