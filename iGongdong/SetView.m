//
//  SetViewController.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "SetView.h"
#import "env.h"
#import "SetStorage.h"
#import "LoginToService.h"

@implementation SetView

@synthesize labelId;
@synthesize labelPwd;
@synthesize labelNoticeSet;
@synthesize labelNotice;
@synthesize labelCommunity;

@synthesize idField;
@synthesize pwdField;
@synthesize switchPush;
@synthesize switchNotice;
@synthesize target;
@synthesize selector;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
     
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryDidChangeNotification)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];

	UILabel *lblTitle = [[UILabel alloc] init];
	lblTitle.text = @"설정";
	lblTitle.backgroundColor = [UIColor clearColor];
	[lblTitle sizeToFit];
	self.navigationItem.titleView = lblTitle;

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
    
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *myPath = [documentsDirectory stringByAppendingPathComponent:@"set.dat"];
    
	SetStorage *storage = (SetStorage *)[NSKeyedUnarchiver unarchiveObjectWithFile:myPath];
	
	idField.text = storage.userid;
	pwdField.text = storage.userpwd;
    if (storage.switchPush == nil) {
        [switchPush setOn:false];
    } else {
        [switchPush setOn:[storage.switchPush intValue]];
    }
    if (storage.switchNotice == nil) {
        [switchNotice setOn:false];
    } else {
        [switchNotice setOn:[storage.switchNotice intValue]];
    }

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
											   initWithTitle:@"완료" 
											   style:UIBarButtonItemStyleDone 
											   target:self 
											   action:@selector(ActionSave:)];
    [self setFont];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)contentSizeCategoryDidChangeNotification {
    [self setFont];
}

- (void)setFont {
    UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    idField.font = titleFont;
    pwdField.font = titleFont;
    labelId.font = titleFont;
    labelPwd.font = titleFont;
    labelNoticeSet.font = titleFont;
    labelNotice.font = titleFont;
    labelCommunity.font = titleFont;
}

- (void)ActionSave:(id)sender
{
	// 입력된 id와 pwd를 저장한다.
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	NSString *myPath = [documentsDirectory stringByAppendingPathComponent:@"set.dat"];
	////NSLog(@"myPath = %@", myPath);
	SetStorage *storage = [[SetStorage alloc] init];
	storage.userid = idField.text;
	storage.userpwd = pwdField.text;
    storage.switchPush = [NSNumber numberWithBool:switchPush.on];
    storage.switchNotice = [NSNumber numberWithBool:switchNotice.on];
	[NSKeyedArchiver archiveRootObject:storage toFile:myPath];
	
	LoginToService *login = [[LoginToService alloc] init];
	BOOL result = [login LoginToService];
	
	if (result) {

		// Push 정보 업데이트
		[login PushRegister];

		[target performSelector:selector withObject:[NSNumber numberWithBool:YES] afterDelay:0];
	} else {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"로그인 오류"
																	   message:@"로그인 정보가 없거나 잘못되었습니다. 설정에서 로그인정보를 입력하세요."
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
		[self presentViewController:alert animated:YES completion:nil];
		
		[target performSelector:selector withObject:[NSNumber numberWithBool:NO] afterDelay:0];
	}
	
	[[self navigationController] popViewControllerAnimated:YES];
}

@end
