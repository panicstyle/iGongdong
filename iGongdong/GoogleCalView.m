//
//
//  GoogleCalView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "GoogleCalView.h"
#import "env.h"
#import "Utils.h"

@interface GoogleCalView () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
}
@end

@implementation GoogleCalView
@synthesize webView;
@synthesize m_strCommId;
@synthesize m_strBoardId;
@synthesize m_strBoardName;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UILabel *lblTitle = [[UILabel alloc] init];
	lblTitle.text = m_strBoardName;
	lblTitle.backgroundColor = [UIColor clearColor];
	[lblTitle sizeToFit];
	self.navigationItem.titleView = lblTitle;

    // Replace this ad unit ID with your own ad unit ID.
    self.bannerView.adUnitID = kSampleAdUnitID;
    self.bannerView.rootViewController = self;
    [self.bannerView loadRequest:[GADRequest request]];
	
	webView.delegate = self;
	webView.scrollView.scrollEnabled = YES;
	[self fetchItems];
}

- (void)fetchItems
{
	// http://cafe.gongdong.or.kr/cafe.php?p1=menbal&sort=cal43
    NSString *url;
    if ([m_strCommId isEqualToString:@"center"]) {
        url = [NSString stringWithFormat:@"%@/bbs/board.php?bo_table=%@", WWW_SERVER, m_strBoardId];
    } else {
        url = [NSString stringWithFormat:@"%@/cafe.php?p1=%@&sort=%@", CAFE_SERVER, m_strCommId, m_strBoardId];
    }

	m_receiveData = [[NSMutableData alloc] init];
	m_connection = [[NSURLConnection alloc]
					initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[m_receiveData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *str = [[NSString alloc] initWithData:m_receiveData
									  encoding:NSUTF8StringEncoding];
	
    if ([m_strCommId isEqualToString:@"center"]) {
        NSString *strContent = [Utils findStringWith:str from:@"<!-- board contents -->" to:@"<!-- } 콘텐츠 끝 -->"];
        [webView loadHTMLString:strContent baseURL:[NSURL URLWithString:WWW_SERVER]];
    } else {
        NSString *strContent = [Utils findStringWith:str from:@"<!-- 풍선 도움말 끝 -->" to:@"<!-- content 끝 -->"];
        [webView loadHTMLString:strContent baseURL:[NSURL URLWithString:CAFE_SERVER]];
    }
}
@end
