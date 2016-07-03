//
//  ArticleWriteView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "ArticleWriteView.h"

@interface ArticleWriteView ()
{
	int m_bUpMode;
	UITextField *m_titleField;
	UITextView *m_contentView;
	long m_lContentHeight;
	UITableViewCell *m_contentCell;
	UITableViewCell *m_imageCell;
	int m_nAddPic;
}

@end

@implementation ArticleWriteView
@synthesize m_nMode;
@synthesize m_strCommNo;
@synthesize m_strBoardNo;
@synthesize m_strArticleNo;
@synthesize m_strTitle;
@synthesize m_strContent;
@synthesize target;
@synthesize selector;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	m_bUpMode = false;
	m_nAddPic = false;
	
	if ([m_nMode intValue] == ArticleWrite) {
		[(UILabel *)self.navigationItem.titleView setText:@"글쓰기"];
	} else if ([m_nMode intValue] == ArticleModify) {
		[(UILabel *)self.navigationItem.titleView setText:@"글수정"];
	}

	CGRect rectScreen = [self getScreenFrameForCurrentOrientation];
	m_lContentHeight = rectScreen.size.height;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
											   initWithTitle:@"완료"
											   style:UIBarButtonItemStyleDone
											   target:self
											   action:@selector(doneEditing:)];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
											  initWithTitle:@"취소"
											  style:UIBarButtonItemStylePlain
											  target:self
											  action:@selector(cancelEditing:)];

	// Listen for keyboard appearances and disappearances
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardDidShow:)
												 name:UIKeyboardDidShowNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardDidHide:)
												 name:UIKeyboardDidHideNotification
											   object:nil];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)keyboardDidShow: (NSNotification *) notif{
	// Do something here
	[self animateTextView:notif up:YES];
}

- (void)keyboardDidHide: (NSNotification *) notif{
	// Do something here
	[self animateTextView:notif up:NO];
}

-(void)animateTextView:(NSNotification *)notif up:(BOOL)up
{
	if (m_bUpMode == up) return;
	
	NSDictionary* keyboardInfo = [notif userInfo];
	NSValue* keyboardFrameBegin = [keyboardInfo valueForKey:UIKeyboardFrameBeginUserInfoKey];
	CGRect keyboardFrameBeginRect = [keyboardFrameBegin CGRectValue];
	
	const int movementDistance = keyboardFrameBeginRect.size.height; // tweak as needed
	const float movementDuration = 0.3f; // tweak as needed
	
	int movement = (up ? -movementDistance : movementDistance);

	[UIView beginAnimations: @"animateTextView" context: nil];
	[UIView setAnimationBeginsFromCurrentState: YES];
	[UIView setAnimationDuration: movementDuration];
	
	CGRect viewRect = self.view.frame;
	viewRect.size.height = viewRect.size.height + movement;
	self.view.frame = viewRect;
	
//	CGRect tableRect = self.tbView.frame;
//	tableRect.size.height = tableRect.size.height + movement;
//	self.tbView.frame = tableRect;
	
	CGRect contentRect = m_contentCell.frame;
	contentRect.size.height = contentRect.size.height + movement;
	m_contentCell.frame = contentRect;

	[self.tbView beginUpdates];
	[self.tbView endUpdates];
	
//	CGRect textRect = m_contentView.frame;
//	textRect.size.height = textRect.size.height + movement;
//	m_contentView.frame = textRect;
	
//	CGRect imageRect = m_imageCell.frame;
//	imageRect.size.height = imageRect.size.height;
//	m_imageCell.frame = imageRect;

	[UIView commitAnimations];
	m_bUpMode = up;
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

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([indexPath row] == 0) {
		return 40.0f;
	} else if ([indexPath row] == 1) {
		return (float)m_lContentHeight;
	} else {
		return 40.0f;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifierTitle = @"Title";
	static NSString *CellIdentifierContent = @"Content";
	static NSString *CellIdentifierImage = @"Image";
	
	UITableViewCell *cell;
	if ([indexPath row] == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierTitle];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierTitle];
		}
		m_titleField = (UITextField *)[cell viewWithTag:100];
		m_titleField.text = m_strTitle;
		return cell;
	} else if ([indexPath row] == 1){
		m_contentCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierContent];
		if (m_contentCell == nil) {
			m_contentCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierContent];
		}
		m_contentView = (UITextView *)[m_contentCell viewWithTag:101];
		m_contentView.text = m_strContent;
		return m_contentCell;
	} else {
		m_imageCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierImage];
		if (m_imageCell == nil) {
			m_imageCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierImage];
		}
		m_imageCell.textLabel.text = @"Image Line";
		return m_imageCell;
	}
}


- (void) cancelEditing:(id)sender
{
	//	[contentView resignFirstResponder];
	[[self navigationController] popViewControllerAnimated:YES];
}

- (void) doneEditing:(id)sender
{
	//	[contentView resignFirstResponder];
	////NSLog(@"donEditing start...");
	NSString *url;
	
	if (m_titleField.text.length <= 0 || m_contentView.text.length <= 0) {
		// 쓰여진 내용이 없으므로 저장하지 않는다.
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"확인"
														message:@"입력된 내용이 없습니다."
													   delegate:nil
											  cancelButtonTitle:nil
											  otherButtonTitles:nil];
		[alert addButtonWithTitle:@"확인"];
		[alert show];
		return;
	}
	
	//		/cafe.php?mode=up&sort=354&p1=tuntun&p2=HTTP/1.1
	if ([m_nMode intValue] == ArticleModify) {
		url = [NSString stringWithFormat:@"%@/cafe.php?mode=edit&p2=&p1=%@&sort=%@",
				   CAFE_SERVER, m_strCommNo, m_strBoardNo];
	} else {
		url = [NSString stringWithFormat:@"%@/cafe.php?mode=up&p2=&p1=%@&sort=%@",
			   CAFE_SERVER, m_strCommNo, m_strBoardNo];
	}
	
	NSData *respData;
	if (m_nAddPic) {
/*
		// 사진첨부됨, Multipart message로 전송
		//        NSData *imageData = UIImagePNGRepresentation(addPicture.image);
		NSData *imageData = UIImageJPEGRepresentation(addPicture.image, 0.5f);
		
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		[request setURL:[NSURL URLWithString:url]];
		[request setHTTPMethod:@"POST"];
		
		NSString *boundary = @"0xKhTmLbOuNdArY";  // important!!!
		NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
		[request addValue:contentType forHTTPHeaderField: @"Content-Type"];
		
		NSMutableString *strBody1 = [[NSMutableString alloc] init];
		NSMutableString *strBody2 = [[NSMutableString alloc] init];
		
		
		// number
		[strBody1 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody1 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"number\"\n"]];
		[strBody1 appendString:@"\n"];
		if (isEdit) {
			[strBody1 appendString:[NSString stringWithFormat:@"%@\n", numberID]];
		} else {
			[strBody1 appendString:@"\n"];
		}
		
		// usetag = n
		[strBody1 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody1 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"usetag\"\n"]];
		[strBody1 appendString:@"\n"];
		[strBody1 appendString:@"n\n"];
		//        [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// subject
		[strBody1 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody1 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"subject\"\n"]];
		[strBody1 appendString:@"\n"];
		[strBody1 appendString:[NSString stringWithFormat:@"%@\n", subjectField.text]];
		//        [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// sample
		[strBody1 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody1 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"sample\"\n"]];
		[strBody1 appendString:@"\n"];
		[strBody1 appendString:@"\n"];
		//        [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// content
		[strBody1 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody1 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"content\"\n"]];
		[strBody1 appendString:@"\n"];
		[strBody1 appendString:[NSString stringWithFormat:@"%@\n", contentField.text]];
		//        [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// imgfile[]
		[strBody1 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody1 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"imgfile[]\"; filename=\"1234.png\"\n"]];
		[strBody1 appendString:@"Content-Type: image/png\n"];
		[strBody1 appendString:@"\n"];
		//        [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// file_text[]
		[strBody2 appendString:@"\n"];
		[strBody2 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody2 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file_text[]\"\n"]];
		[strBody2 appendString:@"\n"];
		[strBody2 appendString:@"\n"];
		//        [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// img_file[]
		[strBody2 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody2 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"img_file[]\"; filename=\"\"\n"]];
		[strBody2 appendString:@"\n"];
		[strBody2 appendString:@"\n"];
		//        [body appendData:[[NSString stringWithFormat:@"\n--%@--\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
		// file_text[]
		[strBody2 appendString:[NSString stringWithFormat:@"--%@\n",boundary]];
		[strBody2 appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file_text[]\"\n"]];
		[strBody2 appendString:@"\n"];
		[strBody2 appendString:@"\n"];
		
		[strBody2 appendString:[NSString stringWithFormat:@"--%@--\n",boundary]];
		
		NSMutableData *body = [NSMutableData data];
		
		[body appendData:[strBody1 dataUsingEncoding:NSUTF8StringEncoding]];
		[body appendData:[NSData dataWithData:imageData]];
		[body appendData:[strBody2 dataUsingEncoding:NSUTF8StringEncoding]];
		
		[request setHTTPBody:body];
		
		respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
*/
	} else {
		
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
		[request setURL:[NSURL URLWithString:url]];
		[request setHTTPMethod:@"POST"];
		
		NSMutableData *body = [NSMutableData data];
		// usetag = n
		[body appendData:[[NSString stringWithFormat:@"number=%@&usetag=n&subject=%@&content=%@", m_strArticleNo, m_titleField.text, m_contentView.text] dataUsingEncoding:NSUTF8StringEncoding]];
		
		[request setHTTPBody:body];
		
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		
		respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
		
	}
	
	NSString *str = [[NSString alloc] initWithData:respData
										  encoding:NSUTF8StringEncoding];
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<meta http-equiv=\"refresh\" content=\"0;" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSUInteger numberOfMatches = [regex numberOfMatchesInString:str options:0 range:NSMakeRange(0, [str length])];
	
	if (numberOfMatches > 0) {
		NSLog(@"write article success");
		[target performSelector:selector withObject:nil];
		[[self navigationController] popViewControllerAnimated:YES];
	} else {
		regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=window.alert\\(\\\").*?(?=\\\")" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
		
		NSString *errmsg;
		if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
			errmsg = [str substringWithRange:rangeOfFirstMatch];
			NSLog(@"errmsg=[%@]", errmsg);
		} else {
			NSLog(@"errmsg line not found");
			errmsg = @"글 작성중 오류가 발생했습니다. 잠시후 다시 해보세요.";
		}
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"글 작성 오류"
														message:errmsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
		[alert show];
	}
}

@end
