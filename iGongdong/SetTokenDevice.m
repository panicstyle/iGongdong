//
//  SetTokenDevice.m
//  iGongdong
//
//  Created by dykim on 21/06/2019.
//  Copyright © 2019 dykim. All rights reserved.
//

#import "SetTokenDevice.h"
#import "env.h"

@implementation SetTokenDevice

@synthesize tokenDevice;

-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:tokenDevice forKey:@"tokenDevice"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    self.tokenDevice = [aDecoder decodeObjectForKey:@"tokenDevice"];
    return self;
}

- (void)dealloc
{
    self.tokenDevice = nil;
}
@end
