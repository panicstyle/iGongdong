//
//  LoginToService.h
//  iGongdong
//
//  Created by Panicstyle on 10. 10. 9..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginToService : NSObject {
	NSString *userid;
    NSString *userpwd;
    NSNumber *switchPush;
    NSNumber *switchNotice;
}
- (BOOL)LoginToService;
- (void)Logout;
- (void)PushRegister;
@end
