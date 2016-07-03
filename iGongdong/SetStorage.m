//
//  SetStorage.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "SetStorage.h"
#import "env.h"

@implementation SetStorage

@synthesize userid, userpwd;

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:userid forKey:@"id"];
	[aCoder encodeObject:userpwd forKey:@"pwd"];
}

- (id)initWithCoder:(NSCoder *)aDecoder 
{
	self = [super init];
	self.userid = [aDecoder decodeObjectForKey:@"id"];
	self.userpwd = [aDecoder decodeObjectForKey:@"pwd"];
	return self;
}

- (void)dealloc
{
	self.userid = nil;
	self.userpwd = nil;
}
@end
