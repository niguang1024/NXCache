//
//  ViewController.h
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NXCacheManager.h"

@interface ViewController : UIViewController<NXCacheManagerDelegate>
@property (nonatomic, retain) NSMutableArray *array;
@property (nonatomic, assign) int count;
@end
