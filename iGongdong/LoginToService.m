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
//#import "HTTPRequest.h"

@implementation LoginToService

//@synthesize respData;
//@synthesize target;
//@synthesize selector;


- (BOOL)LoginToService
{
	BOOL result = FALSE;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *myPath = [documentsDirectory stringByAppendingPathComponent:@"set.dat"];
	
	SetStorage *storage = (SetStorage *)[NSKeyedUnarchiver unarchiveObjectWithFile:myPath];
	
	userid = storage.userid;
	userpwd = storage.userpwd;
	
	NSLog(@"LoginToService...");
	NSLog(@"id = %@", userid);
	NSLog(@"pwd = %@", userpwd);
	
	if (userid == nil || [userid isEqualToString:@""] || userpwd == nil || [userpwd isEqualToString:@""]) {
		return FALSE;
	}
	
	NSString *url;
	url = [NSString stringWithFormat:@"%@/index.php", WWW_SERVER];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"http://www.gongdong.or.kr" forHTTPHeaderField:@"Referer"];
	//    [request setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X_Requested-With"];
	[request setValue:@"http://www.gongdong.or.kr" forHTTPHeaderField:@"Origin"];
	[request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
	
 
	NSMutableData *body = [NSMutableData data];
	[body appendData:[[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
					   "<methodCall>\n"
					   "<params>\n"
					   "<_filter><![CDATA[login]]></_filter>\n"
					   "<error_return_url><![CDATA[/]]></error_return_url>\n"
					   "<mid><![CDATA[front]]></mid>\n"
					   "<act><![CDATA[procMemberLogin]]></act>\n"
					   "<user_id><![CDATA[%@]]></user_id>\n"
					   "<password><![CDATA[%@]]></password>\n"
					   "<module><![CDATA[member]]></module>\n"
					   "</params>\n"
					   "</methodCall>", userid, userpwd]  dataUsingEncoding:NSUTF8StringEncoding]];
	[request setHTTPBody:body];
 
	NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
	/*
	 url = [NSString stringWithFormat:@"%@/front", WWW_SERVER];
	 
	 request = [[[NSMutableURLRequest alloc] init] autorelease];
	 [request setURL:[NSURL URLWithString:url]];
	 [request setHTTPMethod:@"GET"];
	 
	 body = [NSMutableData data];
	 [request setHTTPBody:body];
	 [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	 
	 returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	 NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
	 */
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	
	if (returnString && [returnString rangeOfString:@"<error>0</error>"].location != NSNotFound) {
		NSLog(@"LoginToService Success");
		result = TRUE;
	} else {
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

@end
