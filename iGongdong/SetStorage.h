//
//  SetStorage.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetStorage : NSObject <NSCoding> {
	NSString *userid;
	NSString *userpwd;
}

@property (nonatomic, copy) NSString *userid;
@property (nonatomic, copy) NSString *userpwd;

@end
