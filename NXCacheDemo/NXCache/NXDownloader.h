//
//  NXDownloader.h
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NXCacheDefine.h"

@class NXDownloader;
@protocol NXDownloaderDelegate <NSObject>
@optional
- (void)dataDownloaderDidFinish:(NXDownloader *)downloader;
- (void)dataDownloader:(NXDownloader *)downloader didFinishWithData:(UIImage *)data;
- (void)dataDownloader:(NXDownloader *)downloader didFailWithError:(NSError *)error;
@end

extern NSString *const DataDownloadStartNotification;
extern NSString *const DataDownloadStopNotification;

@interface NXDownloader : NSObject {
    NSURL *url;
    id<NXDownloaderDelegate> delegate;
    NSURLConnection *connection;
    NSMutableData *data;
    id userInfo;
    BOOL lowPriority;// 低优先级
}
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, assign) id<NXDownloaderDelegate> delegate;
@property (nonatomic, retain) NSMutableData *data;
@property (nonatomic, retain) id userInfo;
@property (nonatomic, readwrite) BOOL lowPriority;

+ (id)downloaderWithURL:(NSURL *)url delegate:(id<NXDownloaderDelegate>)delegate userInfo:(id)userInfo lowPriority:(BOOL)lowPriority;
+ (id)downloaderWithURL:(NSURL *)url delegate:(id<NXDownloaderDelegate>)delegate userInfo:(id)userInfo;
+ (id)downloaderWithURL:(NSURL *)url delegate:(id<NXDownloaderDelegate>)delegate;
- (void)start;
- (void)cancel;

@end


#pragma mark - CountableActivityIndicator

@interface NXConuntableActivityIndicatorControl : NSObject {
@private
    int counter;
}
+ (id)sharedActivityIndicatorControl;
- (void)startActivity;
- (void)stopActivity;
- (void)stopAllActivity;
@end