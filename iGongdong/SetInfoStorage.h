//
//  SetInfoStorage.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetInfoStorage : NSObject <NSCoding> {
	NSString *version;
}

@property (nonatomic, copy) NSString *version;

@end
