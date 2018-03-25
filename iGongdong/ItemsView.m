//
//  ItemsView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "ItemsView.h"
#import "env.h"
#import "LoginToService.h"
#import "ArticleView.h"
#import "ArticleWriteView.h"
#import "ItemsData.h"

@interface ItemsView ()
{
	NSMutableArray *m_arrayItems;
	NSString *m_strTitle;
	int m_nPage;
	ItemsData *m_itemsData;
	NSNumber *m_nItemMode;

	CGRect m_rectScreen;
	
//	BOOL m_isLogin;
//	LoginToService *m_login;
//	NSMutableData *m_receiveData;
//	NSURLConnection *m_conn;
//	BOOL m_isConn;
}
@end

@implementation ItemsView

@synthesize m_strCommId;
@synthesize m_strBoardId;
@synthesize m_strBoardName;
@synthesize m_nMode;

- (void)viewDidLoad
{
	[super viewDidLoad];

	UILabel *lblTitle = [[UILabel alloc] init];
	lblTitle.text = m_strBoardName;
	lblTitle.backgroundColor = [UIColor clearColor];
	[lblTitle sizeToFit];
	self.navigationItem.titleView = lblTitle;

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
	
	if ([m_nMode intValue] != CAFE_TYPE_NORMAL) {
		// 커뮤니티 게시판이 아니면 "새글" 버튼을 동작하지 않게 한다.
		[self.m_newArticle setEnabled:FALSE];
	}
	
	m_arrayItems = [[NSMutableArray alloc] init];
	
	m_itemsData = [[ItemsData alloc] init];
	m_itemsData.m_strCommId = m_strCommId;
	m_itemsData.m_strBoardId = m_strBoardId;
	m_itemsData.m_nMode = m_nMode;
	m_itemsData.target = self;
	m_itemsData.selector = @selector(didFetchItems:);
	m_nPage = 1;
	[m_itemsData fetchItems:m_nPage];

	
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//////NSLog(@"count = %d", [arrayItems count]);
	// 더보기를 표시하기 위하여 +1
	if ([m_arrayItems count] > 0) {
		return [m_arrayItems count] + 1;
	} else {
		return [m_arrayItems count];
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath row] == [m_arrayItems count]) {
		return 50.0f;
	} else {
		if ([m_nItemMode intValue] == PictureItems) {
			return 100.0f;
		} else {
			NSMutableDictionary *item = [m_arrayItems objectAtIndex:[indexPath row]];
			NSNumber *height = [item valueForKey:@"height"];
			return [height floatValue];
		}
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifierMore = @"More";
	static NSString *CellIdentifierItem = @"Item";
	static NSString *CellIdentifierReItem = @"ReItem";
	static NSString *CellIdentifierPicItem = @"PicItem";
	
	UITableViewCell *cell;
	if ([indexPath row] == [m_arrayItems count]) {
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierMore];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierMore];
		}
		// 더보기 표시
		CGRect tRect1 = CGRectMake(0.0f, 0.0f, 320.0f, 44.0f);
		id title1 = [[UILabel alloc] initWithFrame:tRect1];
		[title1 setText:@"더  보  기"];
		[title1 setTextAlignment:NSTextAlignmentCenter];
		[title1 setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
		[title1 setFont:[UIFont fontWithName:@"Helvetica" size:18.0f]];
		[title1 setBackgroundColor:[UIColor clearColor]];
		[cell addSubview:title1];
		return cell;
	} else {
		if ([m_nItemMode intValue] == PictureItems) {
			// 사진첩 보기
			NSMutableDictionary *item = [m_arrayItems objectAtIndex:[indexPath row]];
			
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierPicItem];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierPicItem];
			}
			cell.showsReorderControl = YES;
			
			UIImageView *imageNew = (UIImageView *)[cell viewWithTag:210];
			if ([[item valueForKey:@"isNew"] intValue] == 0) {
				[imageNew setImage:[UIImage imageNamed:@"circle-blank"]];
			} else {
				[imageNew setImage:[UIImage imageNamed:@"circle"]];
			}
			
			UIImageView *imageView = (UIImageView *)[cell viewWithTag:200];
			NSString *strPicLink = [item valueForKey:@"piclink"];
			NSURL *url = [NSURL URLWithString:strPicLink];
			imageView.image = [UIImage imageWithCIImage:[CIImage imageWithContentsOfURL:url]];
//			imageView.contentMode = UIViewContentModeScaleAspectFit;
			
			UITextView *textSubject = (UITextView *)[cell viewWithTag:201];
			textSubject.text = [item valueForKey:@"subject"];
			
			UILabel *labelName = (UILabel *)[cell viewWithTag:202];
			NSString *strName = [item valueForKey:@"name"];
//			NSString *strDate = [item valueForKey:@"date"];
//			NSString *strNameDate = [NSString stringWithFormat:@"%@  %@", strName, strDate];
			
			NSMutableAttributedString *textName = [[NSMutableAttributedString alloc] initWithString:strName];
//			[textName addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange([strName length] + 2, [strDate length])];
			labelName.attributedText = textName;
			
			UILabel *labelComment = (UILabel *)[cell viewWithTag:203];
			NSString *strComment = [item valueForKey:@"comment"];
			if ([strComment isEqualToString:@""]) {
				[labelComment setHidden:YES];
			} else {
				[labelComment setHidden:NO];
				labelComment.layer.cornerRadius = 8;
				labelComment.layer.borderWidth = 1.0;
				labelComment.layer.borderColor = labelComment.textColor.CGColor;
				labelComment.text = strComment;
			}
		} else {
			NSMutableDictionary *item = [m_arrayItems objectAtIndex:[indexPath row]];
			int isRe = [[item valueForKey:@"isRe"] intValue];
			if (isRe == 0) {
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierItem];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierItem];
				}
				cell.showsReorderControl = YES;
				
				UIImageView *imageNew = (UIImageView *)[cell viewWithTag:110];
				if ([[item valueForKey:@"isNew"] intValue] == 0) {
					[imageNew setImage:[UIImage imageNamed:@"circle-blank"]];
				} else {
					[imageNew setImage:[UIImage imageNamed:@"circle"]];
				}
				
				UILabel *labelName = (UILabel *)[cell viewWithTag:100];
				NSString *strName = [item valueForKey:@"name"];
				NSString *strDate = [item valueForKey:@"date"];
				NSString *strNameDate = [NSString stringWithFormat:@"%@  %@", strName, strDate];
				
				NSMutableAttributedString *textName = [[NSMutableAttributedString alloc] initWithString:strNameDate];
				[textName addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange([strName length] + 2, [strDate length])];
				labelName.attributedText = textName;
				
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
						textViewWidth = m_rectScreen.size.width - 32 - 20;
						break;
					case UIDeviceOrientationLandscapeLeft:
					case UIDeviceOrientationLandscapeRight:
						textViewWidth = m_rectScreen.size.height - 32 - 20;
				}
				
				CGSize size = [textSubject sizeThatFits:CGSizeMake(textViewWidth, FLT_MAX)];
				float height = (77 - 32) + (size.height);
				[item setObject:[NSNumber numberWithFloat:height] forKey:@"height"];
				NSLog(@"row = %ld, width=%f, height=%f", (long)[indexPath row], textViewWidth, height);
				
				UILabel *labelComment = (UILabel *)[cell viewWithTag:103];
				NSString *strComment = [item valueForKey:@"comment"];
				if ([strComment isEqualToString:@""]) {
					[labelComment setHidden:YES];
				} else {
					[labelComment setHidden:NO];
					labelComment.layer.cornerRadius = 8;
					labelComment.layer.borderWidth = 1.0;
					//					labelComment.layer.borderColor = [UIColor orangeColor].CGColor;
					labelComment.layer.borderColor = labelComment.textColor.CGColor;
					labelComment.text = strComment;
				}
			} else {
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierReItem];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierReItem];
				}
				cell.showsReorderControl = YES;
				
				UIImageView *imageNew = (UIImageView *)[cell viewWithTag:310];
				if ([[item valueForKey:@"isNew"] intValue] == 0) {
					[imageNew setImage:[UIImage imageNamed:@"circle-blank"]];
				} else {
					[imageNew setImage:[UIImage imageNamed:@"circle"]];
				}
				
				UILabel *labelName = (UILabel *)[cell viewWithTag:300];
				NSString *strName = [item valueForKey:@"name"];
				NSString *strDate = [item valueForKey:@"date"];
				NSString *strNameDate = [NSString stringWithFormat:@"%@  %@", strName, strDate];
				
				NSMutableAttributedString *textName = [[NSMutableAttributedString alloc] initWithString:strNameDate];
				[textName addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:NSMakeRange([strName length] + 2, [strDate length])];
				labelName.attributedText = textName;
				
				UITextView *textSubject = (UITextView *)[cell viewWithTag:301];
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
						textViewWidth = m_rectScreen.size.width - 64 - 20;
						break;
					case UIDeviceOrientationLandscapeLeft:
					case UIDeviceOrientationLandscapeRight:
						textViewWidth = m_rectScreen.size.height - 64 - 20;
				}
				
				CGSize size = [textSubject sizeThatFits:CGSizeMake(textViewWidth, FLT_MAX)];
				float height = (77 - 32) + (size.height);
				[item setObject:[NSNumber numberWithFloat:height] forKey:@"height"];
				NSLog(@"row = %ld, width=%f, height=%f", (long)[indexPath row], textViewWidth, height);
				
				UILabel *labelComment = (UILabel *)[cell viewWithTag:303];
				NSString *strComment = [item valueForKey:@"comment"];
				if ([strComment isEqualToString:@""]) {
					[labelComment setHidden:YES];
				} else {
					[labelComment setHidden:NO];
					labelComment.layer.cornerRadius = 8;
					labelComment.layer.borderWidth = 1.0;
					labelComment.layer.borderColor = labelComment.textColor.CGColor;
					labelComment.text = strComment;
				}
			}
		}
	}
	return cell;
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath row] == [m_arrayItems count]) {
		// 더보기를 수행한다.
		//		[arrayItems release];
		m_nPage++;
		
		[m_itemsData fetchItems:m_nPage];
	}
	
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	if ([[segue identifier] isEqualToString:@"Article"]) {
		ArticleView *view = [segue destinationViewController];
		NSIndexPath *currentIndexPath = [self.tbView indexPathForSelectedRow];
		long row = currentIndexPath.row;
		NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
		view.m_isPNotice = [item valueForKey:@"isPNotice"];
		view.m_strCommId = [item valueForKey:@"commId"];
		view.m_strBoardId = [item valueForKey:@"boardId"];
		view.m_strBoardNo = [item valueForKey:@"boardNo"];
		view.m_strBoardName = m_strBoardName;
		if ([m_nMode intValue] == CAFE_TYPE_EDU_APP) {
			view.m_strApplyLink = [item valueForKey:@"applyLink"];
		} else {
			view.m_strApplyLink = @"";
		}
		view.m_nMode = m_nMode;
		view.target = self;
		view.selector = @selector(didWrite:);
	} else 	if ([[segue identifier] isEqualToString:@"ArticleWrite"]) {
		ArticleWriteView *view = [segue destinationViewController];
		view.m_nMode = [NSNumber numberWithInt:ArticleWrite];
		view.m_strCommId = m_strCommId;
		view.m_strBoardId = m_strBoardId;
		view.m_strBoardNo = @"";
		view.m_strTitle = @"";
		view.m_strContent = @"";
		view.m_nMode = m_nMode;
		view.target = self;
		view.selector = @selector(didWrite:);
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

#pragma mark Data Function

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
		if (m_nPage == 1) {
			m_nItemMode = m_itemsData.m_nItemMode;
			m_arrayItems = [NSMutableArray arrayWithArray:m_itemsData.m_arrayItems];
		} else {
			[m_arrayItems addObjectsFromArray:m_itemsData.m_arrayItems];
		}
		[self.tbView reloadData];
	}
}

- (void)didWrite:(id)sender
{
	NSLog(@"didWrite");
	
	[m_arrayItems removeAllObjects];
	[self.tbView reloadData];
	
	m_nPage = 1;
	
	[m_itemsData fetchItems:1];
	
}

@end
