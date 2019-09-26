//
//  ArticleView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "ArticleView.h"
#import "CommentWriteView.h"
#import "ArticleWriteView.h"
#import "env.h"
#import "Utils.h"
#import "ArticleData.h"
#import "WebLinkView.h"
#import "DBInterface.h"

@interface ArticleView ()
{
	UITableViewCell *m_contentCell;
	UITableViewCell *m_imageCell;
	UITableViewCell *m_replyCell;
	
	CGRect m_rectScreen;
	
	NSMutableArray *m_arrayItems;
	NSDictionary *m_attachItems;
	long m_lContentHeight;
	float m_fTitleHeight;
	
	UIWebView *m_webView;
	ArticleData *m_articleData;
	
	NSMutableData *receiveData;
	NSString *paramTitle;
	NSString *paramWriter;

	NSString *m_strContent;

	NSString *m_strTitle;
	NSString *m_strDate;
	NSString *m_strName;
	NSString *m_strHit;
	
	NSString *m_strCommentNo;
	NSString *m_strComment;
	
	NSString *DeleteBoardID;
	NSString *DeleteBoardNO;
	
	NSString *m_strEditableTitle;
	NSString *m_strEditableContent;

	NSString *m_strWebLink;
	int m_nFileType;
    
    NSString *m_strDeleteLink;
	
	NSURLConnection *conn;
}
@end

@implementation ArticleView

@synthesize tbView;
@synthesize buttonArticleMenu;
@synthesize m_isPNotice;
@synthesize m_strCommId;
@synthesize m_strBoardId;
@synthesize m_strBoardNo;
@synthesize m_strBoardName;
@synthesize m_nMode;
@synthesize target;
@synthesize selector;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];

	UILabel *lblTitle = [[UILabel alloc] init];
	lblTitle.text = m_strBoardName;
	lblTitle.backgroundColor = [UIColor clearColor];
	[lblTitle sizeToFit];
	self.navigationItem.titleView = lblTitle;

    if ([m_nMode intValue] == CAFE_TYPE_APPLY) {
        buttonArticleMenu.enabled = NO;
    }

    buttonArticleMenu.target = self;
    buttonArticleMenu.action = @selector(ArticleMenu);
	
	m_lContentHeight = 300;
	m_rectScreen = [self getScreenFrameForCurrentOrientation];
	
	m_fTitleHeight = 77.0f;
    
    tbView.estimatedRowHeight = 150.0f;
    tbView.rowHeight = UITableViewAutomaticDimension;

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
/*
	if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
		self.edgesForExtendedLayout = UIRectEdgeNone;   // iOS 7 specific
*/
/*
	// Do any additional setup after loading the view from its nib.
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"메뉴"
																			   style:UIBarButtonItemStylePlain
																			  target:self
																		  action:@selector(showMenu:)];
*/

	m_arrayItems = [[NSMutableArray alloc] init];

	m_articleData = [[ArticleData alloc] init];
	m_articleData.m_isPNotice = m_isPNotice;
	m_articleData.m_strCommId = m_strCommId;
	m_articleData.m_strBoardId = m_strBoardId;
	m_articleData.m_strBoardNo = m_strBoardNo;
	m_articleData.m_nMode = m_nMode;
	m_articleData.target = self;
	m_articleData.selector = @selector(didFetchItems:);
	[m_articleData fetchItems];
    
    // DB에 현재 읽는 글의 boardId, boardNo 를 insert
    DBInterface *db;
    db = [[DBInterface alloc] init];
    NSString *commId = @"";
    if ([m_strCommId isEqualToString:@"ing"] || [m_strCommId isEqualToString:@"edu"]) {
        commId = @"center";
    } else {
        commId = m_strCommId;
    }
    [db insertWithCommId:commId BoardId:m_strBoardId BoardNo:m_strBoardNo];
}

- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
//	[self.tbView beginUpdates];
//	[self.tbView endUpdates];
	[self.tbView reloadData];
}

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

- (void)textViewDidChange:(UITextView *)textView;
{
    [tbView beginUpdates];
    [tbView endUpdates];
}

- (void)ArticleMenu
{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* writecomment = [UIAlertAction actionWithTitle:@"댓글쓰기" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self WriteComment];
                                                   }];
    UIAlertAction* modify = [UIAlertAction actionWithTitle:@"글수정" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self ModifyArticle];
                                                   }];
    UIAlertAction* delete = [UIAlertAction actionWithTitle:@"글삭제" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self DeleteArticleConfirm];
                                                   }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        //action when pressed button
    }];
    
    [alert addAction:writecomment];
    if ([m_nMode intValue] == CAFE_TYPE_NORMAL) {
        // 커뮤니티 게시판이 아니면 수정, 삭제 버튼을 동작하지 않게 한다.
        [alert addAction:modify];
        [alert addAction:delete];
    }
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath section] == 0) {
        if ([indexPath row] == 0) {
            return UITableViewAutomaticDimension;
        } else if ([indexPath row] == 1) {
            return (float)m_lContentHeight;
        } else {
            return UITableViewAutomaticDimension;
        }
    } else {
        return UITableViewAutomaticDimension;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	// Return the number of sections.
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
	// Return the number of rows in the section.
	switch (section) {
		case 0 :
			return 2;
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
	NSString *strMsg;
	switch (section) {
		case 0 :
			return @"";
			break;
		case 1 :
			strMsg = [[NSString alloc] initWithFormat:@"%lu개의 댓글", (unsigned long)[m_arrayItems count]];
			return strMsg;
			break;
	}
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifierTitle = @"Title";
	static NSString *CellIdentifierContent = @"Content";
	static NSString *CellIdentifierReply = @"Reply";
	static NSString *CellIdentifierReReply = @"ReReply";
	
	long row = indexPath.row;
	long section = indexPath.section;
	
	UITableViewCell *cell;
	NSMutableDictionary *item;
	switch (section) {
		case 0 :
			if (row == 0) {		// Title Row
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierTitle];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierTitle];
				}
				cell.showsReorderControl = YES;
				
				UITextView *textSubject = (UITextView *)[cell viewWithTag:101];
				textSubject.text = m_strTitle;
                [textSubject sizeToFit];
				
				UILabel *labelName = (UILabel *)[cell viewWithTag:100];
				NSString *strNameDate;
				if (m_strName != nil) {
					strNameDate = [NSString stringWithFormat:@"%@  %@  %@명 읽음", m_strName, m_strDate, m_strHit];
				} else {
					strNameDate = @"";
				}
				
				labelName.text = strNameDate;
			} else if (row == 1){		// Content Row
				m_contentCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierContent];
				if (m_contentCell == nil) {
					m_contentCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierContent];
				}
				cell = m_contentCell;
				[cell addSubview:m_webView];
			}
			break;
		case 1 :
			item = [m_arrayItems objectAtIndex:[indexPath row]];
			if ([[item valueForKey:@"isRe"] intValue] == 0) {
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierReply];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierReply];
				}
				NSString *strName = [item valueForKey:@"name"];
				NSString *strDate = [item valueForKey:@"date"];
				NSString *strNameDate = [NSString stringWithFormat:@"%@  %@", strName, strDate];

				UILabel *labelName = (UILabel *)[cell viewWithTag:200];
				labelName.text = strNameDate;
								
				UITextView *viewComment = (UITextView *)[cell viewWithTag:202];
				viewComment.text = [item valueForKey:@"comment"];
			} else {
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierReReply];
				if (cell == nil) {
					cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierReReply];
				}
				
				NSString *strName = [item valueForKey:@"name"];
				NSString *strDate = [item valueForKey:@"date"];
				NSString *strNameDate = [NSString stringWithFormat:@"%@  %@", strName, strDate];
				
				UILabel *labelName = (UILabel *)[cell viewWithTag:300];
				labelName.text = strNameDate;
				
				UITextView *viewComment = (UITextView *)[cell viewWithTag:302];
				viewComment.text = [item valueForKey:@"comment"];
			}
				
			break;
	}
	return cell;
}

#pragma mark - WebView Delegate

- (void) webViewDidFinishLoad:(UIWebView *)sender {
	NSString *padding = @"document.body.style.padding='0px 8px 0px 8px';";
	[sender stringByEvaluatingJavaScriptFromString:padding];
	[self performSelector:@selector(calculateWebViewSize) withObject:nil afterDelay:0.1];
    [tbView beginUpdates];
    [tbView endUpdates];
}

-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {
	
	NSURL *url = request.URL;
	NSString *urlString = url.absoluteString;
	NSLog(@"request = %@", urlString);
	
	NSString *fileName;
	if ([m_nMode intValue] == CAFE_TYPE_NORMAL) {
		fileName = [Utils findStringRegex:urlString regex:@"(?<=&name=).*?(?=$)"];
		fileName = [fileName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	} else {
		fileName = [m_attachItems valueForKey:urlString];
	}
	NSLog(@"fileName = %@", fileName);
	NSString *loweredExtension = [[fileName pathExtension] lowercaseString];
	NSLog(@"loweredExtension = %@", loweredExtension);
	// Valid extensions may change.  Check the UIImage class reference for the most up to date list.
	NSSet *validImageExtensions = [NSSet setWithObjects:@"tif", @"tiff", @"jpg", @"jpeg", @"gif", @"png", @"bmp", @"bmpf", @"ico", @"cur", @"xbm", nil];
	
	if (navigationType == UIWebViewNavigationTypeLinkClicked) {
		
		if ([validImageExtensions containsObject:loweredExtension])
		{
			m_nFileType = FILE_TYPE_IMAGE;
			m_strWebLink = urlString;
			[self performSegueWithIdentifier:@"WebLink" sender:self];
		} else if ([loweredExtension hasSuffix:@"hwp"]|| [loweredExtension hasSuffix:@"pdf"]) {
			NSData	*tempData = [NSData dataWithContentsOfURL:url];
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSAllDomainsMask, YES);
			NSString *documentDirectory = [paths objectAtIndex:0];
			NSString *filePath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]];
			BOOL isWrite = [tempData writeToFile:filePath atomically:YES];
			NSString *tempFilePath;
			
			if (isWrite) {
				tempFilePath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]];
			}
			NSURL *resultURL = [NSURL fileURLWithPath:tempFilePath];
			
			self.doic = [UIDocumentInteractionController interactionControllerWithURL:resultURL];
			self.doic.delegate = self;
			[self.doic presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
			return NO;
		} else {
			[[UIApplication sharedApplication] openURL:[request URL]];
		}
		
		return NO;
	} else if (navigationType == UIWebViewNavigationTypeOther) {
		if ([[[request URL] absoluteString] hasPrefix:@"jscall:"]) {
			
			NSString *requestString = [[request URL] absoluteString];
			NSArray *components = [requestString componentsSeparatedByString:@"://"];
			NSString *functionName = [components objectAtIndex:1];
			
			NSLog(@"requestString = [%@]", requestString);
			NSLog(@"functionName = [%@]", functionName);
			
			NSString *fileName = [functionName stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSLog(@"fileName = [%@]", fileName);
			
			m_nFileType = FILE_TYPE_IMAGE;
			m_strWebLink = fileName;
			[self performSegueWithIdentifier:@"WebLink" sender:self];
			return NO;
		} else if ([loweredExtension hasSuffix:@"hwp"]|| [loweredExtension hasSuffix:@"pdf"]) {
			NSData	*tempData = [NSData dataWithContentsOfURL:url];
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSAllDomainsMask, YES);
			NSString *documentDirectory = [paths objectAtIndex:0];
			NSString *filePath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]];
			BOOL isWrite = [tempData writeToFile:filePath atomically:YES];
			NSString *tempFilePath;
			
			if (isWrite) {
				tempFilePath = [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@", fileName]];
			}
			NSURL *resultURL = [NSURL fileURLWithPath:tempFilePath];
			
			self.doic = [UIDocumentInteractionController interactionControllerWithURL:resultURL];
			self.doic.delegate = self;
			[self.doic presentOpenInMenuFromRect:self.view.frame inView:self.view animated:YES];
			return NO;
		} else {
			return YES;
		}
	}
 	return YES;
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    long row = indexPath.row;
    long section = indexPath.section;
    if (section < 1) return;    // subject & content 에서 클릭되는 것은 무시한다.
    NSLog(@"selected section = %ld, row = %ld", section, row);
    
    NSMutableDictionary *item;
    item = [m_arrayItems objectAtIndex:[indexPath row]];
    
    NSString *strTitle = [NSString stringWithFormat:@"%@님의 댓글", [item valueForKey:@"name"]];
    
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:strTitle
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
// moojigae_web 에서 comment modify 를 지원하지 않음.

    UIAlertAction* modify = [UIAlertAction actionWithTitle:@"댓글수정" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self ModifyComment:row];
                                                   }];

    UIAlertAction* delete = [UIAlertAction actionWithTitle:@"댓글삭제" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self DeleteCommentConfirm:row];
                                                   }];
    
    UIAlertAction* reply = [UIAlertAction actionWithTitle:@"댓글답변" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self WriteReComment:row];
                                                   }];
    
    UIAlertAction* copy = [UIAlertAction actionWithTitle:@"댓글복사" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self CopyComment:row];
                                                   }];
    
    UIAlertAction* share = [UIAlertAction actionWithTitle:@"댓글공유" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       [self ShareComment:row];
                                                   }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        //action when pressed button
    }];
    
    [alert addAction:modify];
    [alert addAction:reply];
    [alert addAction:delete];
    [alert addAction:copy];
    [alert addAction:share];
    [alert addAction:cancelAction];
    [self presentViewController:alert animated:YES completion:nil];
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
		m_strContent = m_articleData.m_strContent;
		m_arrayItems = m_articleData.m_arrayItems;
		m_attachItems = m_articleData.m_attachItems;
		m_strEditableContent = m_articleData.m_strEditableContent;
		m_strEditableTitle = m_articleData.m_strTitle;
		m_strTitle = m_articleData.m_strTitle;
		m_strName = m_articleData.m_strName;
		m_strDate = m_articleData.m_strDate;
		m_strHit = m_articleData.m_strHit;
		
		
		NSLog(@"htmlString = [%@]", m_strContent);
		
		m_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, m_contentCell.frame.size.width, m_contentCell.frame.size.height)];
		m_webView.delegate = self;
//        m_webView.scrollView.scrollEnabled = YES;
        m_webView.scrollView.scrollEnabled = NO;
		m_webView.scrollView.bounces = NO;
        m_webView.dataDetectorTypes = UIDataDetectorTypePhoneNumber | UIDataDetectorTypeLink;
		if ([m_nMode intValue] == CAFE_TYPE_NORMAL) {
			[m_webView loadHTMLString:m_strContent baseURL:[NSURL URLWithString:CAFE_SERVER]];
		} else {
			[m_webView loadHTMLString:m_strContent baseURL:[NSURL URLWithString:WWW_SERVER]];
		}

//		m_arrayItems = [NSMutableArray arrayWithArray:m_articleData.m_arrayItems];
		[self.tbView reloadData];
	}
}

- (void) calculateWebViewSize {
	NSUInteger contentHeight = [[m_webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.body.scrollHeight;"]] intValue];
	m_lContentHeight = contentHeight;
	
	CGRect contentRect = m_contentCell.frame;
	contentRect.size.height = m_lContentHeight;
	m_contentCell.frame = contentRect;

	CGRect webRect = m_webView.frame;
	webRect.size.height = m_lContentHeight;
	m_webView.frame = webRect;

	[self.tbView reloadData];
}

#pragma mark Navigation Controller

-(void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
	if(item.tag==100)
	{
		[self DeleteArticleConfirm];
	}
}

#pragma mark WriteComment

- (void)CopyComment:(long)row
{
    NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
    NSString *strComment = [item valueForKey:@"comment"];

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = strComment;
    
    NSString *message = @"댓글이 복사되었습니다.";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [self presentViewController:alert animated:YES completion:nil];

    int duration = 1; // duration in seconds

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, duration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)ShareComment:(long)row
{
    NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
    NSString *strComment = [item valueForKey:@"comment"];
    
    NSMutableArray *shareItems = [[NSMutableArray alloc] init];
    [shareItems addObject:strComment];

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:shareItems applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAirDrop
                                         , UIActivityTypeCopyToPasteboard
                                         , UIActivityTypeMail
                                         , UIActivityTypeMessage
                                         , UIActivityTypePrint
                                        ];
    [self presentViewController:activityVC animated:YES completion:nil];
}

- (void)WriteComment
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:NULL];
    
    CommentWriteView *view = (CommentWriteView*)[storyboard instantiateViewControllerWithIdentifier:@"CommentWriteView"];
    if (view != nil) {
        view.m_nModify = [NSNumber numberWithInt:CommentWrite];
        view.m_nMode = m_nMode;
        view.m_isPNotice = m_isPNotice;
        view.m_strCommId = m_strCommId;
        view.m_strBoardId = m_strBoardId;
        view.m_strBoardNo = m_strBoardNo;
        view.m_strCommentNo = @"";
        view.m_strComment = @"";
        view.target = self;
        view.selector = @selector(didWrite:);
        
        [self.navigationController pushViewController:view animated:YES];
    }
}

- (void)ModifyComment:(long)row
{
    NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:NULL];
    
    CommentWriteView *view = (CommentWriteView*)[storyboard instantiateViewControllerWithIdentifier:@"CommentWriteView"];
    if (view != nil) {
        view.m_nModify = [NSNumber numberWithInt:CommentModify];
        view.m_nMode = m_nMode;
        view.m_isPNotice = m_isPNotice;
        view.m_strCommId = m_strCommId;
        view.m_strBoardId = m_strBoardId;
        view.m_strBoardNo = m_strBoardNo;
        view.m_strCommentNo = [item valueForKey:@"no"];
        view.m_strComment = [item valueForKey:@"comment"];
        view.target = self;
        view.selector = @selector(didWrite:);
        
        [self.navigationController pushViewController:view animated:YES];
    }
}

- (void)DeleteCommentConfirm:(long)row
{
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
																   message:@"삭제하시겠습니까?"
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action) {
														[self DeleteComment:row];
													}];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action) {}];
	
	
	[alert addAction:okAction];
	[alert addAction:cancelAction];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)DeleteComment:(long)row
{
	NSLog(@"DeleteArticleConfirm start");
	
	NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
	m_strCommentNo = [item valueForKey:@"no"];
    NSString *strDeleteLink = [item valueForKey:@"deletelink"];
	
    bool result = [m_articleData DeleteComment:m_strCommId boardId:m_strBoardId boardNo:m_strBoardNo commentNo:m_strCommentNo deleteLink:strDeleteLink isPNotice:[m_isPNotice intValue] Mode:[m_nMode intValue]];

	if (result == false) {
		NSString *errmsg = @"글을 삭제할 수 없습니다. 잠시후 다시 해보세요.";
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"글 삭제 오류"
														message:errmsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
		[alert show];
		return;
	}

	// 삭제된 코멘트를 TableView에서 삭제한다.
	[m_arrayItems removeObjectAtIndex:row];
	[self.tbView reloadData];

	NSLog(@"delete article success");
}

- (void)WriteReComment:(long)row
{
    NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:NULL];
    
    CommentWriteView *view = (CommentWriteView*)[storyboard instantiateViewControllerWithIdentifier:@"CommentWriteView"];
    if (view != nil) {
        view.m_nModify = [NSNumber numberWithInt:CommentReply];
        view.m_nMode = m_nMode;
        view.m_isPNotice = m_isPNotice;
        view.m_strCommId = m_strCommId;
        view.m_strBoardId = m_strBoardId;
        view.m_strBoardNo = m_strBoardNo;
        view.m_strCommentNo = [item valueForKey:@"no"];
        view.m_strComment = @"";
        view.target = self;
        view.selector = @selector(didWrite:);
        
        [self.navigationController pushViewController:view animated:YES];
    }
}

- (void)ModifyArticle
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:NULL];
    
    ArticleWriteView *view = (ArticleWriteView*)[storyboard instantiateViewControllerWithIdentifier:@"ArticleWriteView"];
    if (view != nil) {
        view.m_nModify = [NSNumber numberWithInt:ArticleModify];
        view.m_nMode = m_nMode;
        view.m_strCommId = m_strCommId;
        view.m_strBoardId = m_strBoardId;
        view.m_strBoardNo = m_strBoardNo;
        NSString *strEditableTitle = [Utils replaceStringHtmlTag:m_strTitle];
        //        NSString *strEditableContent = [Utils replaceStringHtmlTag:m_strContent];
        view.m_strTitle = strEditableTitle;
        view.m_strContent = m_strEditableContent;
        view.target = self;
        view.selector = @selector(didWrite:);
        
        [self.navigationController pushViewController:view animated:YES];
    }
}

- (void)DeleteArticleConfirm
{
	NSLog(@"DeleteArticleConfirm start");

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
																   message:@"삭제하시겠습니까?"
															preferredStyle:UIAlertControllerStyleAlert];
	
	UIAlertAction* okAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
													 handler:^(UIAlertAction * action) {
														 [self DeleteArticle];
													 }];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"취소" style:UIAlertActionStyleDefault
														 handler:^(UIAlertAction * action) {}];
	
	
	[alert addAction:okAction];
	[alert addAction:cancelAction];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)DeleteArticle
{
	NSLog(@"DeleteArticleConfirm start");
	NSLog(@"boardID=[%@], boardNo=[%@]", m_strBoardId, m_strBoardNo);
	
	bool result = [m_articleData DeleteArticle:m_strCommId boardId:m_strBoardId boardNo:m_strBoardNo];
	
	if (result == false) {
        NSString *errmsg = @"글을 삭제할 수 없습니다. 잠시후 다시 해보세요.";
		
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"글 삭제 오류"
																	   message:errmsg
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
        return;
    }
    
    NSLog(@"delete article success");
    [target performSelector:selector withObject:nil afterDelay:0];
    [[self navigationController] popViewControllerAnimated:YES];
}


- (void)didWrite:(id)sender
{
	[m_arrayItems removeAllObjects];
	[self.tbView reloadData];
	[m_articleData fetchItems];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
/*	if ([[segue identifier] isEqualToString:@"Comment"]) {
		CommentWriteView *view = [segue destinationViewController];
		view.m_nModify = [NSNumber numberWithInt:CommentWrite];
		view.m_nMode = m_nMode;
		view.m_isPNotice = m_isPNotice;
		view.m_strCommId = m_strCommId;
		view.m_strBoardId = m_strBoardId;
		view.m_strBoardNo = m_strBoardNo;
		view.m_strCommentNo = @"";
		view.m_strComment = @"";
		view.target = self;
		view.selector = @selector(didWrite:);
	} else if ([[segue identifier] isEqualToString:@"CommentModify"]) {
		UITableViewCell *clickedCell = (UITableViewCell *)[[sender superview] superview];
		NSIndexPath *clickedButtonPath = [self.tbView indexPathForCell:clickedCell];
//		[self tableView:self.tbView didSelectRowAtIndexPath:clickedButtonPath];
		
		CommentWriteView *view = [segue destinationViewController];
//		NSIndexPath *currentIndexPath = [self.tbView indexPathForSelectedRow];
		long row = clickedButtonPath.row;
		NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
		view.m_nModify = [NSNumber numberWithInt:CommentModify];
		view.m_nMode = m_nMode;
		view.m_isPNotice = m_isPNotice;
		view.m_strCommId = m_strCommId;
		view.m_strBoardId = m_strBoardId;
		view.m_strBoardNo = m_strBoardNo;
		view.m_strCommentNo = [item valueForKey:@"no"];
		view.m_strComment = [item valueForKey:@"comment"];
		view.target = self;
		view.selector = @selector(didWrite:);
	} else if ([[segue identifier] isEqualToString:@"CommentReply"]) {
		UITableViewCell *clickedCell = (UITableViewCell *)[[sender superview] superview];
		NSIndexPath *clickedButtonPath = [self.tbView indexPathForCell:clickedCell];
//		[self tableView:self.tbView didSelectRowAtIndexPath:clickedButtonPath];

		CommentWriteView *view = [segue destinationViewController];
//		NSIndexPath *currentIndexPath = [self.tbView indexPathForSelectedRow];
		long row = clickedButtonPath.row;
		NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
		view.m_nModify = [NSNumber numberWithInt:CommentReply];
		view.m_nMode = m_nMode;
		view.m_isPNotice = m_isPNotice;
		view.m_strCommId = m_strCommId;
		view.m_strBoardId = m_strBoardId;
		view.m_strBoardNo = m_strBoardNo;
		view.m_strCommentNo = [item valueForKey:@"no"];
		view.m_strComment = @"";
		view.target = self;
		view.selector = @selector(didWrite:);
	} else if ([[segue identifier] isEqualToString:@"ArticleModify"]) {
		ArticleWriteView *view = [segue destinationViewController];
		view.m_nModify = [NSNumber numberWithInt:ArticleModify];
		view.m_nMode = m_nMode;
		view.m_strCommId = m_strCommId;
		view.m_strBoardId = m_strBoardId;
		view.m_strBoardNo = m_strBoardNo;
		NSString *strEditableTitle = [Utils replaceStringHtmlTag:m_strTitle];
		//		NSString *strEditableContent = [Utils replaceStringHtmlTag:m_strContent];
		view.m_strTitle = strEditableTitle;
		view.m_strContent = m_strEditableContent;
		view.target = self;
		view.selector = @selector(didWrite:);
	} else */if ([[segue identifier] isEqualToString:@"WebLink"]) {
		WebLinkView *view = [segue destinationViewController];
		view.m_nFileType = [NSNumber numberWithInt:m_nFileType];
		view.m_strLink = m_strWebLink;
	}
}

@end
