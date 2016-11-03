//
//  MainView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "MainView.h"
#import "SetView.h"
#import "AboutView.h"
#import "BoardView.h"
#import "SetInfo.h"
#import "LoginToService.h"
#import "env.h"
#import "MainData.h"

@interface MainView ()
{
	NSMutableArray *m_arrayItems;
	NSMutableArray *m_arrayMain;
	LoginToService *m_login;
	MainData *m_mainData;
}
@end

@implementation MainView
@synthesize tbView;

- (void)viewDidLoad {
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

	SetInfo *setInfo = [[SetInfo alloc] init];
	
	if (![setInfo CheckVersionInfo]) {
		
		// 버전 업데이트 안내 다이얼로그 표시
		NSString *NotiMessage = @"새글 알림기능이 추가되었습니다. 새글알림을 설정하시겠습니까?";
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"안내"
																	   message:NotiMessage
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action)
			{
				UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:NULL];
				SetView *setView = (SetView*)[storyboard instantiateViewControllerWithIdentifier:@"SetView"];
				setView.target = self;
				setView.selector = @selector(didChangedSetting:);
				UINavigationController *navController = (UINavigationController*)self.navigationController;
				if (navController != nil) {
					[navController pushViewController:setView animated:YES];
				}
				[alert dismissViewControllerAnimated:YES completion:nil];
			}];
	
		UIAlertAction* cancel = [UIAlertAction
								 actionWithTitle:@"취소"
								 style:UIAlertActionStyleDefault
								 handler:^(UIAlertAction * action)
								 {
									 [alert dismissViewControllerAnimated:YES completion:nil];
									 
								 }];
		
		[alert addAction:defaultAction];
		[alert addAction:cancel];
		
		[self presentViewController:alert animated:YES completion:nil];
		[setInfo SaveVersionInfo];
	}

	m_arrayItems = [[NSMutableArray alloc] init];
	
	m_mainData = [[MainData alloc] init];
	m_mainData.target = self;
	m_mainData.selector = @selector(didFetchItems);
	
	if (m_login == nil) {
		// 저장된 로그인 정보를 이용하여 로그인
		m_login = [[LoginToService alloc] init];
		BOOL result = [m_login LoginToService];
		
		if (result) {
			[m_login PushRegister];
			
			[m_mainData fetchItems];
		} else {
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"로그인 오류"
																		   message:@"로그인 정보가 없거나 잘못되었습니다. 설정에서 로그인정보를 입력하세요."
																	preferredStyle:UIAlertControllerStyleAlert];
			
			UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
																  handler:^(UIAlertAction * action) {}];
			
			[alert addAction:defaultAction];
			[self presentViewController:alert animated:YES completion:nil];
		}
	}
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 44.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// Return the number of rows in the section.
	switch (section) {
		case 0 :
			return [m_arrayMain count];
			break;
		case 1 :
			return [m_arrayItems count];
			break;
	}
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	// Return the number of rows in the section.
	switch (section) {
		case 0 :
			return @"공동육아와 공동체교육";
			break;
		case 1 :
			return @"내 커뮤니티";
			break;
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	long section = indexPath.section;
	static NSString *CellIdentifier = @"reuseIdentifier";
	
	UITableViewCell *cell = [tableView
							 dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									  reuseIdentifier:CellIdentifier];
	}
	NSMutableDictionary *item;
	switch (section) {
		case 0 :
			item = [m_arrayMain objectAtIndex:[indexPath row]];
			cell.textLabel.text = [item valueForKey:@"title"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
		case 1:
			// Configure the cell...
			item = [m_arrayItems objectAtIndex:[indexPath row]];
			cell.textLabel.text = [item valueForKey:@"title"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			break;
	}
	return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	if ([[segue identifier] isEqualToString:@"Board"]) {
		BoardView *viewController = [segue destinationViewController];
		NSIndexPath *currentIndexPath = [self.tbView indexPathForSelectedRow];
		long sec = currentIndexPath.section;
		long row = currentIndexPath.row;
		if (sec == 0) {
			NSMutableDictionary *item = [m_arrayMain objectAtIndex:row];
			viewController.m_strCommId = [item valueForKey:@"code"];
			viewController.m_nMode = [NSNumber numberWithInt:CENTER];
		} else {
			NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
			viewController.m_strCommId = [item valueForKey:@"code"];
			viewController.m_nMode = [NSNumber numberWithInt:COMMUNITY];
		}
	} else if ([[segue identifier] isEqualToString:@"SetLogin"]) {
		SetView *viewController = [segue destinationViewController];
		viewController.target = self;
		viewController.selector = @selector(didChangedSetting:);
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

#pragma mark - Data Function

- (void)didFetchItems
{
	//	m_arrayItems = [NSMutableArray arrayWithArray:m_mainData.m_arrayItems];
	m_arrayItems = m_mainData.m_arrayItems;
	m_arrayMain = m_mainData.m_arrayMain;
	[self.tbView reloadData];
}

- (void)didChangedSetting:(NSNumber *)result
{
	if ([result boolValue]) {
		[m_arrayItems removeAllObjects];
		[self.tbView reloadData];
		[m_mainData fetchItems];
	}
}

@end
