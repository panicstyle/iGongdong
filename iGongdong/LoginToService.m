//
//  LoginToService.m
//  iGongdong
//
//  Created by Panicstyle on 10. 10. 9..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LoginToService.h"
#import "env.h"
#import "SetStorage.h"
#import "SetTokenDevice.h"
#import "AppDelegate.h"
//#import "HTTPRequest.h"

@implementation LoginToService

- (BOOL)LoginToService
{
	BOOL result = FALSE;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *myPath = [documentsDirectory stringByAppendingPathComponent:@"set.dat"];
	
	SetStorage *storage = (SetStorage *)[NSKeyedUnarchiver unarchiveObjectWithFile:myPath];
	
	userid = storage.userid;
	userpwd = storage.userpwd;
	switchPush = storage.switchPush;
    switchNotice = storage.switchNotice;
	
	NSLog(@"LoginToService...");
	NSLog(@"id = %@", userid);
	NSLog(@"pwd = %@", userpwd);
    NSLog(@"push = %@", switchPush);
    NSLog(@"pushNotice = %@", switchNotice);

	if (userid == nil || [userid isEqualToString:@""] || userpwd == nil || [userpwd isEqualToString:@""]) {
		return FALSE;
	}
	NSString *url;
	url = [NSString stringWithFormat:@"%@/bbs/login_check.php", WWW_SERVER];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"http://www.gongdong.or.kr/bbs/login.php?url=%2F" forHTTPHeaderField:@"Referer"];
//  [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X_Requested-With"];
//	[request setValue:@"http://www.gongdong.or.kr" forHTTPHeaderField:@"Origin"];
//	[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
	
    NSString *escaped = [userid stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
	NSMutableData *body = [NSMutableData data];
    [body appendData:[[NSString stringWithFormat:@"url=%%252F&mb_id=%@&mb_password=%@", escaped, userpwd] dataUsingEncoding:NSUTF8StringEncoding]];

	[request setHTTPBody:body];
 
	NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
    AppDelegate *getVar = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	if (returnString && [returnString rangeOfString:@"<title>오류안내 페이지"].location == NSNotFound) {
		NSLog(@"LoginToService Success");
		getVar.strUserId = userid;
		if (switchPush == nil) {
            switchPush = [NSNumber numberWithBool:false];
            switchNotice = [NSNumber numberWithBool:false];
		}
        getVar.switchPush = switchPush;
        getVar.switchNotice = switchNotice;
		result = TRUE;
	} else {
        getVar.strUserId = @"";
        getVar.switchPush = [NSNumber numberWithBool:false];
        getVar.switchNotice = [NSNumber numberWithBool:false];
		result = FALSE;
	}
	return result;
}

- (void)Logout
{
	NSString *url;
	url = [NSString stringWithFormat:@"%@/index.php?mid=front&act=dispMemberLogout", WWW_SERVER];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	NSMutableData *body = [NSMutableData data];
	[request setHTTPBody:body];
	[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}

- (void)PushRegister
{
	AppDelegate *getVar = (AppDelegate *)[[UIApplication sharedApplication] delegate];
	NSString *tokenDevice = getVar.strDevice;
	NSString *userId = getVar.strUserId;
    NSNumber *nPushYN = getVar.switchPush;
    NSString *strPushYN = @"Y";
    NSNumber *nPushNotice = getVar.switchNotice;
    NSString *strPushNotice = @"Y";

    if ( tokenDevice == nil || [tokenDevice isEqualToString:@""] ) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPath = [documentsDirectory stringByAppendingPathComponent:@"setToken.dat"];
        
        SetTokenDevice *storage = (SetTokenDevice *)[NSKeyedUnarchiver unarchiveObjectWithFile:myPath];
        
        tokenDevice = storage.tokenDevice;
    }

	if (tokenDevice == nil || userId == nil) {
		NSLog(@"PushRegister fail. tokenDevice or userId is nil\n");
		return;
	}
    if ([tokenDevice isEqualToString:@""] || [userId isEqualToString:@""]) {
        NSLog(@"PushRegister fail. tokenDevice or userId is empty\n");
        return;
    }
	if ([nPushYN boolValue] == true) {
		strPushYN = @"Y";
	} else {
		strPushYN = @"N";
	}
    if ([nPushNotice boolValue] == true) {
        strPushNotice = @"Y";
    } else {
        strPushNotice = @"N";
    }
	NSLog(@"Device : %@", tokenDevice);
	
	NSString *url;
	url = [NSString stringWithFormat:@"%@/push/PushRegister", PUSH_SERVER];
	
	NSLog(@"URL : %@", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	
	NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"{\"type\":\"iOS\",\"ver\":\"%@\",\"push_yn\":\"%@\",\"push_notice\":\"%@\",\"uuid\":\"%@\",\"userid\":\"%@\"}", PUSH_VER, strPushYN, strPushNotice, tokenDevice, userId]  dataUsingEncoding:NSUTF8StringEncoding]];
 
	[request setHTTPBody:body];
	
	NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
	
	NSLog(@"returnString = [%@]", returnString);
}
@end
