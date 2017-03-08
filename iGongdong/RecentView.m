//
//  RecentView.m
//  iGongdong
//
//  Created by Kim DY on 12. 6. 11..
//  Copyright (c) 2012년 이니라인. All rights reserved.
//

#import "RecentView.h"
#import "env.h"
#import "LoginToService.h"
#import "ArticleView.h"
#import "RecentData.h"

@interface RecentView ()
{
	NSMutableArray *m_arrayItems;
	RecentData *m_recentData;
	CGRect m_rectScreen;

//	NSString *m_strTitle;
//	NSString *m_strURL;
//	int m_nPage;
	
//	BOOL m_isLogin;
//	LoginToService *m_login;
//	NSMutableData *m_receiveData;
//	NSURLConnection *m_conn;
//	BOOL m_isConn;
}
@end

@implementation RecentView

@synthesize m_strCommId;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	m_rectScreen = [self getScreenFrameForCurrentOrientation];

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
	
	m_arrayItems = [[NSMutableArray alloc] init];
	
	m_recentData = [[RecentData alloc] init];
	m_recentData.m_strCommNo = m_strCommId;
	m_recentData.target = self;
	m_recentData.selector = @selector(didFetchItems:);
	[m_recentData fetchItems];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [m_arrayItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableDictionary *item = [m_arrayItems objectAtIndex:[indexPath row]];
	NSNumber *height = [item valueForKey:@"height"];
	return [height floatValue];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Item";
	
	UITableViewCell *cell;
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

	NSMutableDictionary *item = [m_arrayItems objectAtIndex:[indexPath row]];
	cell.showsReorderControl = YES;
	
	UILabel *labelName = (UILabel *)[cell viewWithTag:100];
	labelName.text = [item valueForKey:@"writer"];
	
	UITextView *textSubject = (UITextView *)[cell viewWithTag:101];
	textSubject.text = [item valueForKey:@"subject"];
	
	//			CGFloat textViewWidth = viewComment.frame.size.width;
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	CGFloat textViewWidth;
	switch (orientation) {
		case UIDeviceOrientationUnknown:
		case UIDeviceOrientationPortrait:
		case UIDeviceOrientationPortraitUpsideDown:
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
			textViewWidth = m_rectScreen.size.width - 40;
			break;
		case UIDeviceOrientationLandscapeLeft:
		case UIDeviceOrientationLandscapeRight:
			textViewWidth = m_rectScreen.size.height - 40;
	}
	
	CGSize size = [textSubject sizeThatFits:CGSizeMake(textViewWidth, FLT_MAX)];
	float height = (77 - 32) + (size.height);
	[item setObject:[NSNumber numberWithFloat:height] forKey:@"height"];
	NSLog(@"row = %ld, width=%f, height=%f", (long)[indexPath row], textViewWidth, height);
	
	UILabel *labelDate = (UILabel *)[cell viewWithTag:102];
	labelDate.text = [item valueForKey:@"date"];
	
	UILabel *labelComment = (UILabel *)[cell viewWithTag:103];
	NSString *strComment = [item valueForKey:@"comment"];
	if ([strComment isEqualToString:@""]) {
		[labelComment setHidden:YES];
	} else {
		[labelComment setHidden:NO];
		labelComment.layer.cornerRadius = 8;
		labelComment.text = strComment;
	}
	
	return cell;

}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	if ([[segue identifier] isEqualToString:@"Article"]) {
/*
		ArticleView *view = [segue destinationViewController];
		NSIndexPath *currentIndexPath = [self.tbView indexPathForSelectedRow];
		long row = currentIndexPath.row;
		NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
		view.m_strCommId = @"";
		view.m_strBoardId = @"";
		view.m_strBoardNo = @"";
 */
	}
}

#pragma mark - Screen Function

- (CGRect)getScreenFrameForCurrentOrientation {
	return [self getScreenFrameForOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (CGRect)getScreenFrameForOrientation:(UIInterfaceOrientation)orientation {
	
	CGRect fullScreenRect = [[UIScreen mainScreen] bounds];
	
	// implicitly in Portrait orientation.
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		CGRect temp = CGRectZero;
		temp.size.width = fullScreenRect.size.height;
		temp.size.height = fullScreenRect.size.width;
		fullScreenRect = temp;
	}
	
	CGFloat statusBarHeight = 20; // Needs a better solution, FYI statusBarFrame reports wrong in some cases..
	fullScreenRect.size.height -= statusBarHeight;
	fullScreenRect.size.height -= self.navigationController.navigationBar.frame.size.height;
	fullScreenRect.size.height -= 40 + 40;
	
	return fullScreenRect;
}

#pragma mark WriteArticle

- (void)didFetchItems:(NSNumber *)result
{
	if ([result intValue] == RESULT_AUTH_FAIL) {
		NSLog(@"already login : auth fail");
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"권한오류"
																	   message:@"게시판을 볼 권한이 없습니다."
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
		[self presentViewController:alert animated:YES completion:nil];
	} else if ([result intValue] == RESULT_LOGIN_FAIL) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"로그인 오류"
																	   message:@"로그인 정보가 없거나 잘못되었습니다. 설정에서 로그인정보를 입력하세요."
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
		[self presentViewController:alert animated:YES completion:nil];
	} else {
		m_arrayItems = [NSMutableArray arrayWithArray:m_recentData.m_arrayItems];
		[self.tbView reloadData];
	}
}

@end
