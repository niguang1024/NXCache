//
//  ViewController.m
//  NXCacheDemo
//
//  Created by Ni Nori on 12-1-12.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"


@implementation ViewController
@synthesize array, count;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)nextImage {
    if (count < [array count]) {
        count ++;
        [[NXCacheManager sharedManager] loadWithURL:[NSURL URLWithString:[array objectAtIndex:count - 1]] delegate:self];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"End" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    array = [[NSMutableArray alloc] initWithObjects:
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/189/422/10189422.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/259/585/10259585.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/259/509/10259509.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/259/507/10259507.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/133/883/10133883.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/184/852/10184852.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/150/625/10150625.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/133/848/10133848.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/171/841/10171841.jpg",
             @"http://bzimg.spriteapp.cn/bizhi/middle/10/186/551/10186551.jpg",
             nil];
    count = 0;
    [self nextImage];
}

- (void)cacheManager:(NXCacheManager *)cacheManager didFinishWithData:(NSData *)data {NSLog(@"Finish one.");
    UIImage *image = [UIImage imageWithData:data];//NSLog(@"%@", image);
    UIImageView *imageView = nil;
    if([[self.view subviews] count] == 0){
        imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:imageView];
        [imageView release];
    }
    else {
        imageView = [[self.view subviews] objectAtIndex:0];
    }
    [imageView setImage:image];
    [self performSelector:@selector(nextImage) withObject:nil afterDelay:1];
}
- (void)cacheManager:(NXCacheManager *)cacheManager didFailWithError:(NSError *)error {NSLog(@"Fail one.");
    [self performSelector:@selector(nextImage) withObject:nil afterDelay:1];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
