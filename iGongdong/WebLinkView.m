//
//  WebLinkView.m
//  iGongdong
//
//  Created by dykim on 2016. 7. 24..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "WebLinkView.h"
#import "env.h"
#import "Utils.h"

@interface WebLinkView () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
}
@end

@implementation WebLinkView
@synthesize webView;
@synthesize m_strLink;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Replace this ad unit ID with your own ad unit ID.
	self.bannerView.adUnitID = kSampleAdUnitID;
	self.bannerView.rootViewController = self;
	
	GADRequest *request = [GADRequest request];
	// Requests test ads on devices you specify. Your test device ID is printed to the console when
	// an ad request is made. GADBannerView automatically returns test ads when running on a
	// simulator.
	request.testDevices = @[
							@"2077ef9a63d2b398840261c8221a0c9a"  // Eric's iPod Touch
							];
	[self.bannerView loadRequest:request];
	
	webView.delegate = self;
	webView.scrollView.scrollEnabled = YES;
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:m_strLink]]];
}
@end
