//
//  SetStorage.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetStorage : NSObject <NSCoding> {

}

@property (nonatomic, copy) NSString *userid;
@property (nonatomic, copy) NSString *userpwd;
@property (nonatomic, copy) NSNumber *switchPush;
@property (nonatomic, copy) NSNumber *switchNotice;

@end
