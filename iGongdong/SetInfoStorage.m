//
//  SetStorage.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "SetInfoStorage.h"
#import "env.h"

@implementation SetInfoStorage

@synthesize version;

-(void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:version forKey:@"version"];
}

- (id)initWithCoder:(NSCoder *)aDecoder 
{
	self = [super init];
	self.version = [aDecoder decodeObjectForKey:@"version"];
	return self;
}

- (void)dealloc
{
	self.version = nil;
}
@end
