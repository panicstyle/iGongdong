//
//  SetInfo.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "SetInfo.h"
#import "env.h"
#import "SetInfoStorage.h"

@implementation SetInfo

- (BOOL)CheckVersionInfo
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *myPath = [documentsDirectory stringByAppendingPathComponent:@"info.dat"];
	
	SetInfoStorage *storage = (SetInfoStorage *)[NSKeyedUnarchiver unarchiveObjectWithFile:myPath];
	
	if (storage == nil) {
		return FALSE;
	}
	
    NSString *savedVersion = storage.version;
	
	NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *currVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
	
	if ([savedVersion isEqualToString:currVersion]) {
		return TRUE;
	}

    return FALSE;
}

- (BOOL)SaveVersionInfo
{
	NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *currVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *myPath = [documentsDirectory stringByAppendingPathComponent:@"info.dat"];

	SetInfoStorage *storage = [[SetInfoStorage alloc] init];
	storage.version = currVersion;
	[NSKeyedArchiver archiveRootObject:storage toFile:myPath];
	
	return TRUE;
}

@end
