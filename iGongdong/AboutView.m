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
	
	UILabel *lblTitle = [[UILabel alloc] init];
	lblTitle.text = @"앱정보";
	lblTitle.backgroundColor = [UIColor clearColor];
	[lblTitle sizeToFit];
	self.navigationItem.titleView = lblTitle;
	
	NSString *msgAbout;
	
    // Do any additional setup after loading the view from its nib.
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
//    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
	msgAbout = [NSString stringWithFormat:@"공동육아앱 for iOS\n버전 : %@\n개발자 : 호랑이(과천맨발어린이집 졸업조합원)\n문의메일 : panicstyle@gmail.com\n홈페이지 : http://www.panicstyle.net/?page_id=7\n소스 : https://github.com/panicstyle/iGongdong\n\n광고수익은 공동육아 저소득기금으로 사용됩니다.",  version];
    textView.text = msgAbout;
}

@end
