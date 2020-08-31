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
#import "Photos/Photos.h"
@import GoogleMobileAds;

@interface WebLinkView () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
}
@end

@implementation WebLinkView
@synthesize mainView;
@synthesize m_strLink;
@synthesize m_nFileType;
@synthesize m_imageView;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	UILabel *lblTitle = [[UILabel alloc] init];
	lblTitle.text = @"이미지보기";
	lblTitle.backgroundColor = [UIColor clearColor];
	[lblTitle sizeToFit];
	self.navigationItem.titleView = lblTitle;
	
    // Replace this ad unit ID with your own ad unit ID.
    self.bannerView.adUnitID = kSampleAdUnitID;
    self.bannerView.rootViewController = self;
    [self.bannerView loadRequest:[GADRequest request]];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
											  initWithTitle:@"저장"
											  style:UIBarButtonItemStyleDone
											  target:self
											  action:@selector(saveImage:)];
	
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
	
	return m_imageView;
	
}

- (void)viewDidLayoutSubviews
{
	if ([m_nFileType intValue] == FILE_TYPE_IMAGE) {
		
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, mainView.bounds.size.width, mainView.bounds.size.height)];
		
		//		[mainView addSubview:imageView];
		
		[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:m_strLink]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
			imageView.image = [UIImage imageWithData:data];
			imageView.contentMode = UIViewContentModeScaleAspectFit;
		}];
		
		self.m_imageView = imageView;
		mainView.maximumZoomScale = 3.0;
		mainView.minimumZoomScale = 0.6;
		mainView.clipsToBounds = YES;
		mainView.delegate = self;
		[mainView addSubview:m_imageView];
		
	} else {
		UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, mainView.bounds.size.width, mainView.bounds.size.height)];
		
		[mainView addSubview:webView];
		
		webView.delegate = self;
		webView.scalesPageToFit = TRUE;
		webView.scrollView.scrollEnabled = YES;
		[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:m_strLink]]];
	}
}

- (void) saveImage:(id)sender
{
	UIImage *snapshot = self.m_imageView.image;
	
	[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
		PHAssetChangeRequest *changeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:snapshot];
		changeRequest.creationDate          = [NSDate date];
	} completionHandler:^(BOOL success, NSError *error) {
		if (success) {
			NSLog(@"successfully saved");
			[self AlertSuccess];
		}
		else {
			NSLog(@"error saving to photos: %@", error);
			[self AlertFail:[error localizedDescription]];
		}
	}];
}

-(void)AlertSuccess {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"성공"
													message:@"이미지가 사진보관함에 저장되었습니다." delegate:self cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
	[alert performSelector:@selector(show)
				  onThread:[NSThread mainThread]
				withObject:nil
			 waitUntilDone:NO];
}

-(void)AlertFail:(NSString *)errMsg {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"오류"
													message:errMsg delegate:self cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
	[alert performSelector:@selector(show)
				  onThread:[NSThread mainThread]
				withObject:nil
			 waitUntilDone:NO];
}

@end
