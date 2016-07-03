//
//  AboutView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "AboutView.h"

@interface AboutView ()

@end

@implementation AboutView
@synthesize textView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	NSString *msgAbout;
	
    // Do any additional setup after loading the view from its nib.
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
//    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
	msgAbout = [NSString stringWithFormat:@"공동육아 / 아이폰\n버전 : %@\n문의메일 : panicstyle@gmail.com\n홈페이지 : http://www.panicstyle.net/?page_id=7",  version];
    textView.text = msgAbout;
}

@end
