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
#import "DBInterface.h"
@import GoogleMobileAds;

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryDidChangeNotification)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    [self setTitle];

    // Replace this ad unit ID with your own ad unit ID.
    self.bannerView.adUnitID = kSampleAdUnitID;
    self.bannerView.rootViewController = self;
    [self.bannerView loadRequest:[GADRequest request]];

	SetInfo *setInfo = [[SetInfo alloc] init];

	if (![setInfo CheckVersionInfo]) {
/*		// 버전 업데이트 안내 다이얼로그 표시
		NSString *NotiMessage = @"어린이집 게시판과 함께 공동육아 홈페이지 새글 알림 설정이 추가되있습니다. 로그인설정에서 알림 받기를 설정해서 새글 알림을 받아보세요.";
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"알림"
																	   message:NotiMessage
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
		[self presentViewController:alert animated:YES completion:nil];
*/
        [setInfo SaveVersionInfo];
	}

	m_arrayItems = [[NSMutableArray alloc] init];
	
	m_mainData = [[MainData alloc] init];
	m_mainData.target = self;
	m_mainData.selector = @selector(didFetchItems);
	
    // DB에 6개월 지난 데이터는 삭제
    DBInterface *db;
    db = [[DBInterface alloc] init];
    [db delete];

	if (m_login == nil) {
		// 저장된 로그인 정보를 이용하여 로그인
		m_login = [[LoginToService alloc] init];
		BOOL result = [m_login LoginToService];
		
		if (result) {
			[m_login PushRegister];
		} else {
			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"로그인 오류"
																		   message:@"로그인 정보가 없거나 잘못되었습니다. 설정에서 로그인정보를 입력하세요."
																	preferredStyle:UIAlertControllerStyleAlert];
			
			UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
																  handler:^(UIAlertAction * action) {}];
			
			[alert addAction:defaultAction];
			[self presentViewController:alert animated:YES completion:nil];
		}        
        [m_mainData fetchItems];
	}
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)contentSizeCategoryDidChangeNotification {
    [self setTitle];
    [self.tbView reloadData];
}

- (void)setTitle {
    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.text = @"공동육아";
    lblTitle.backgroundColor = [UIColor clearColor];
    lblTitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.navigationItem.titleView = lblTitle;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    CGFloat cellHeight = 30.0 - 17.0 + titleFont.pointSize;
    return cellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIFont *titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    CGFloat cellHeight = 44.0 - 17.0 + titleFont.pointSize;
	return cellHeight;
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
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
			cell.textLabel.text = [item valueForKey:@"title"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//            NSLog(@" = %@", [UIFont preferredFontForTextStyle:UIFontTextStyleBody]);
//            NSLog(@" = %@", [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]);
			break;
		case 1:
			// Configure the cell...
			item = [m_arrayItems objectAtIndex:[indexPath row]];
            cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
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
			viewController.m_strCommTitle = [item valueForKey:@"title"];
			viewController.m_nMode = [NSNumber numberWithInt:CENTER];
		} else {
			NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
			viewController.m_strCommId = [item valueForKey:@"code"];
			viewController.m_strCommTitle = [item valueForKey:@"title"];
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
