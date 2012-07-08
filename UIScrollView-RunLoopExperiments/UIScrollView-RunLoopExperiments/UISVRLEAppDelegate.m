//
//  UISVRLEAppDelegate.m
//  UIScrollView-RunLoopExperiments
//
//  Created by Evadne Wu on 2/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UISVRLEAppDelegate.h"

@implementation UISVRLEAppDelegate

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.backgroundColor = [UIColor whiteColor];
	
	UIViewController *viewController = [(UIViewController *)[NSClassFromString(@"UISVRLERootViewController") alloc] init];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
	navigationController.navigationBar.barStyle = UIBarStyleDefault;
	navigationController.navigationBar.tintColor = [UIColor grayColor];
	
	self.window.rootViewController = navigationController;
	[self.window makeKeyAndVisible];
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

@end
