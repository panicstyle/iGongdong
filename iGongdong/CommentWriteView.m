//
//  CommentWriteView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//


#import "CommentWriteView.h"
#import "env.h"
#import "utils.h"

@interface CommentWriteView () {
	NSString *m_strErrorMsg;
	long m_lContentHeight;
	UIAlertView *alertWait;
}
@end

@implementation CommentWriteView
@synthesize m_nModify;
@synthesize m_nMode;
@synthesize m_isPNotice;
@synthesize m_textView;
@synthesize m_strCommId;
@synthesize m_strBoardId;
@synthesize m_strBoardNo;
@synthesize m_strCommentNo;
@synthesize m_strComment;
@synthesize target;
@synthesize selector;

- (void)viewDidLoad
{
	m_strErrorMsg = @"";
	
	CGRect rectScreen = [self getScreenFrameForCurrentOrientation];
	m_lContentHeight = rectScreen.size.height;
	
	UILabel *lblTitle = [[UILabel alloc] init];
	if ([m_nModify intValue] == CommentWrite) {
		lblTitle.text = @"댓글쓰기";
	} else if ([m_nModify intValue] == CommentModify) {
		lblTitle.text = @"댓글수정";
		m_textView.text = m_strComment;
	} else {
		lblTitle.text = @"댓글답변쓰기";
	}
	lblTitle.backgroundColor = [UIColor clearColor];
	[lblTitle sizeToFit];
	self.navigationItem.titleView = lblTitle;
	
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
	
	CGRect contentRect = m_textView.frame;
	contentRect.size.height = contentRect.size.height + movement;
	m_textView.frame = contentRect;
	
	[UIView commitAnimations];
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

- (void) cancelEditing:(id)sender
{
	//	[contentView resignFirstResponder];
	[[self navigationController] popViewControllerAnimated:YES];
}	

- (void)AlertShow
{
    alertWait = [[UIAlertView alloc] initWithTitle:@"저장중입니다." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
    [alertWait show];
    
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Adjust the indicator so it is up a few pixels from the bottom of the alert
    indicator.center = CGPointMake(alertWait.bounds.size.width / 2, alertWait.bounds.size.height - 50);
    [indicator startAnimating];
    [alertWait addSubview:indicator];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)AlertDismiss
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [alertWait dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)doneEditing:(id)sender
{
	BOOL result = [self writeComment];
	
	if (result) {
		[target performSelector:selector withObject:nil afterDelay:0];
		[[self navigationController] popViewControllerAnimated:YES];
	} else {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"댓글 쓰기 오류"
																	   message:m_strErrorMsg
																preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"확인" style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {}];
		
		[alert addAction:defaultAction];
	}
}

- (BOOL)writeComment
{
	if ([m_nMode intValue] == CAFE_TYPE_NORMAL) {
		if ([m_isPNotice intValue] == 0) {
			return [self writeCommentNormal];
		} else {
			return [self writeCommentPNotice];
		}
	} else {
		return [self writeCommentPNotice];
	}
}

- (BOOL)writeCommentNormal
{
	NSString *url;
	
	//		/cafe.php?mode=up&sort=354&p1=tuntun&p2=HTTP/1.1
	if ([m_nModify intValue] == CommentWrite || [m_nModify intValue] == CommentReply) {
		url = [NSString stringWithFormat:@"%@/cafe.php?mode=up_add&sort=%@&sub_sort=&p1=%@&p2=",
			   CAFE_SERVER, m_strBoardId, m_strCommId];
	} else if ([m_nModify intValue] == CommentModify) {
		url = [NSString stringWithFormat:@"%@/cafe.php?mode=edit_reply&sort=%@&sub_sort=&p1=%@&p2=",
			   CAFE_SERVER, m_strBoardId, m_strCommId];
	}
	
	NSLog(@"url = [%@]", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	
	NSMutableData *body = [NSMutableData data];
	
	if ([m_nModify intValue] == CommentWrite) {
		[body appendData:[[NSString stringWithFormat:@"number=%@&content=%@", m_strBoardNo, m_textView.text] dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([m_nModify intValue] == CommentModify) {
		[body appendData:[[NSString stringWithFormat:@"number=%@&content=%@", m_strCommentNo, m_textView.text] dataUsingEncoding:NSUTF8StringEncoding]];
	} else {	// CommentReply
		[body appendData:[[NSString stringWithFormat:@"number=%@&number_re=%@&content=%@", m_strBoardNo, m_strCommentNo, m_textView.text] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[request setHTTPBody:body];
	
	NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	NSString *str = [[NSString alloc] initWithData:respData
										  encoding:NSUTF8StringEncoding];
	NSLog(@"str = [%@]", str);
	
	if ([Utils numberOfMatches:str regex:@"<meta http-equiv=\"refresh\" content=\"0;"] > 0) {
		NSLog(@"delete comment success");
		return true;
	} else {
		NSString *errMsg = [Utils findStringRegex:str regex:@"(?<=window.alert\\(\\\").*?(?=\\\")"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"댓글 작성 오류"
														message:errMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
		[alert show];
		return false;
	}
}

- (BOOL)writeCommentPNotice
{
	NSString *url = @"http://www.gongdong.or.kr/index.php";
	
	NSLog(@"url = [%@]", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	
	NSMutableData *body = [NSMutableData data];
	
	[request setValue:@"http://www.gongdong.or.kr" forHTTPHeaderField:@"Origin"];
	[request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
	
	if ([m_nModify intValue] == CommentWrite) {
		NSString *strReferer = [NSString stringWithFormat:@"http://www.gongdong.or.kr/notice/%@", m_strBoardNo];
		[request setValue:strReferer forHTTPHeaderField:@"Referer"];
		[body appendData:[[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
						   "<methodCall>\n"
						   "<params>\n"
						   "<_filter><![CDATA[insert_comment]]></_filter>\n"
						   "<error_return_url><![CDATA[/notice/%@]]></error_return_url>\n"
						   "<mid><![CDATA[notice]]></mid>\n"
						   "<document_srl><![CDATA[%@]]></document_srl>\n"
						   "<comment_srl><![CDATA[0]]></comment_srl>\n"
						   "<content><![CDATA[<p>%@</p>\n"
						   "]]></content>\n"
						   "<module><![CDATA[board]]></module>\n"
						   "<act><![CDATA[procBoardInsertComment]]></act>\n"
						   "</params>\n"
						   "</methodCall>", m_strBoardNo, m_strBoardNo, m_textView.text] dataUsingEncoding:NSUTF8StringEncoding]];
	} else if ([m_nModify intValue] == CommentModify) {
		NSString *strReferer = [NSString stringWithFormat:@"http://www.gongdong.or.kr/index.php?mid=notice&document_srl=%@&act=dispBoardModifyComment&comment_srl=%@", m_strBoardNo, m_strCommentNo];
		[request addValue:strReferer forHTTPHeaderField:@"Referer"];
		[body appendData:[[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
						   "<methodCall>\n"
						   "<params>\n"
						   "<_filter><![CDATA[insert_comment]]></_filter>\n"
						   "<error_return_url><![CDATA[/index.php?mid=notice&document_srl=%@"
						   "&act=dispBoardModifyComment&comment_srl=%@]]></error_return_url>\n"
						   "<act><![CDATA[procBoardInsertComment]]></act>\n"
						   "<mid><![CDATA[notice]]></mid>\n"
						   "<document_srl><![CDATA[%@]]></document_srl>\n"
						   "<comment_srl><![CDATA[%@]]></comment_srl>\n"
						   "<content><![CDATA[<p>%@</p>\n"
						   "]]></content>\n"
						   "<parent_srl><![CDATA[0]]></parent_srl>\n"
						   "<module><![CDATA[board]]></module>\n"
						   "</params>\n"
						   "</methodCall>", m_strBoardNo, m_strCommentNo, m_strBoardNo, m_strCommentNo, m_textView.text] dataUsingEncoding:NSUTF8StringEncoding]];
	} else {	// CommentReply
		NSString *strReferer = [NSString stringWithFormat:@"http://www.gongdong.or.kr/index.php?mid=notice&document_srl=%@&act=dispBoardReplyComment&comment_srl=%@", m_strBoardNo, m_strCommentNo];
		[request addValue:strReferer forHTTPHeaderField:@"Referer"];
		[body appendData:[[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
						   "<methodCall>\n"
						   "<params>\n"
						   "<_filter><![CDATA[insert_comment]]></_filter>\n"
						   "<error_return_url><![CDATA[/index.php?mid=notice&document_srl=%@&act=dispBoardReplyComment&comment_srl=%@]]></error_return_url>\n"
						   "<mid><![CDATA[notice]]></mid>\n"
						   "<document_srl><![CDATA[%@]]></document_srl>\n"
						   "<comment_srl><![CDATA[0]]></comment_srl>\n"
						   "<parent_srl><![CDATA[%@]]></parent_srl>\n"
						   "<content><![CDATA[<p>%@</p>\n"
						   "]]></content>\n"
						   "<module><![CDATA[board]]></module>\n"
						   "<act><![CDATA[procBoardInsertComment]]></act>\n"
						   "</params>\n"
						   "</methodCall>", m_strBoardNo, m_strCommentNo, m_strBoardNo, m_strCommentNo, m_textView.text] dataUsingEncoding:NSUTF8StringEncoding]];
	}
	
	[request setHTTPBody:body];
	
	NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	NSString *str = [[NSString alloc] initWithData:respData
										  encoding:NSUTF8StringEncoding];
	NSLog(@"str = [%@]", str);
	
	if ([Utils numberOfMatches:str regex:@"<error>0</error>"] > 0) {
		NSLog(@"write comment success");
		return true;
	} else {
		NSString *errMsg = [Utils findStringRegex:str regex:@"(?<=<message>).*?(?=</message>)"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"댓글 작성 오류"
														message:errMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
		[alert show];
		return false;
	}
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end
