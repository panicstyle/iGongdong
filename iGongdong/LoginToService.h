//
//  LoginToService.h
//  iGongdong
//
//  Created by Panicstyle on 10. 10. 9..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginToService : NSObject {
//	NSString *respData;
//	id target;
//	SEL selector;
//    HTTPRequest *httpRequest;
	NSString *userid;
    NSString *userpwd;
	NSNumber *switchPush;
}
- (BOOL)LoginToService;
- (void)Logout;
- (void)PushRegister;
- (void)PushRegisterUpdate;

//- (void)setDelegate:(id)aTarget selector:(SEL)aSelector;
//- (void)didReceiveFinished:(NSString *)result;

//@property (nonatomic, assign) NSString *respData;
//@property (nonatomic, assign) id target;
//@property (nonatomic, assign) SEL selector;
@end
