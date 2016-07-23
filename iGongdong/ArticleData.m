//
//  ArticleData.m
//  iMoojigae
//
//  Created by dykim on 2016. 3. 13..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "ArticleData.h"
#import "Utils.h"
#import "env.h"
#import "LoginToService.h"

@interface ArticleData () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
	BOOL m_isConn;
	BOOL m_isLogin;
	LoginToService *m_login;
	int m_intMode;
}
@end

@implementation ArticleData

@synthesize m_strTitle;
@synthesize m_strName;
@synthesize m_strDate;
@synthesize m_strHit;
@synthesize m_strHtml;
@synthesize m_strContent;
@synthesize m_strEditableContent;
@synthesize m_isPNotice;
@synthesize m_strLink;
@synthesize m_arrayItems;
@synthesize m_nMode;
@synthesize target;
@synthesize selector;

- (void)fetchItems
{
	m_arrayItems = [[NSMutableArray alloc] init];
	
	m_isConn = TRUE;
	m_isLogin = FALSE;
	
	m_intMode = [m_nMode intValue];
	
	[self fetchItems2];
}

- (void)fetchItems2
{
	NSString *url;
 
	if (m_intMode == CAFE_TYPE_NORMAL) {
		if ([m_isPNotice intValue] == 0) {
			url = [NSString stringWithFormat:@"%@%@", CAFE_SERVER, m_strLink];
		} else {
			url = m_strLink;
		}
	} else {
		url = m_strLink;
	}
	
	m_arrayItems = [[NSMutableArray alloc] init];
	
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
	if ([m_receiveData length] < 200) {
		if (m_isLogin == FALSE) {
			NSLog(@"retry login");
			// 저장된 로그인 정보를 이용하여 로그인
			m_login = [[LoginToService alloc] init];
			BOOL result = [m_login LoginToService];
			if (result) {
				m_isLogin = TRUE;
				[self fetchItems2];
			}
		} else {
			[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_LOGIN_FAIL] afterDelay:0];
			return;
		}
		[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_AUTH_FAIL] afterDelay:0];
		return;
	}
	
/*
	<script type="text/javascript">
	window.alert("권한이 없습니다. (권한_테이블1)");
	history.go(-1);
	</script>
	
*/
	
	/* <script type="text/javascript">
	 window.alert("로그인 하세요");
	 history.go(-1);
	 </script> */
	
	m_strHtml = [[NSString alloc] initWithData:m_receiveData
									  encoding:NSUTF8StringEncoding];
	
	if ([Utils numberOfMatches:m_strHtml regex:@"window.alert(\\\"권한이 없습니다"] > 0) {
		[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_AUTH_FAIL] afterDelay:0];
		return;
	}
	if ([Utils numberOfMatches:m_strHtml regex:@"history.go\\(-1\\)"] > 0) {
		if (m_isLogin == FALSE) {
			NSLog(@"retry login");
			// 저장된 로그인 정보를 이용하여 로그인
			m_login = [[LoginToService alloc] init];
			BOOL result = [m_login LoginToService];
			if (result) {
				m_isLogin = TRUE;
				[self fetchItems2];
			} else {
				[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_LOGIN_FAIL] afterDelay:0];
				return;
			}
		} else {
			[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_LOGIN_FAIL] afterDelay:0];
			return;
		}
	}

	if (m_intMode == CAFE_TYPE_NORMAL) {
		if ([m_isPNotice intValue] == 0) {
			[self parseNormal];
		} else {
			[self parsePNotice];
		}
	} else if (m_intMode == CAFE_TYPE_NOTICE){
		[self parsePNotice];
	} else if (m_intMode == CAFE_TYPE_CENTER) {
		[self parseCenter];
	}
}
	
- (void)parseNormal
{
	//<!---- contents start ---->
	//<!---- contents end ---->
	
/*
	if ([m_nServerType intValue] == 1) {
		strContent = @"(?<=<!---- contents start 본문 표시 부분 DJ ---->).*?(?=<!---- contents end ---->)";
	} else {
		strContent = @"(?<=<!---- contents start ---->).*?(?=<!---- contents end ---->)";
	}
*/
	m_strTitle = [Utils findStringRegex:m_strHtml regex:@"(?<=<div style=\"margin-right:10; margin-left:10;\"><B>).*?(?=</div>)"];
	m_strTitle = [Utils replaceStringHtmlTag:m_strTitle];

	m_strName = [Utils findStringRegex:m_strHtml regex:@"(<div align=\"right\"><b>작성자 : <a).*?(</a>)"];
	m_strName = [Utils replaceStringHtmlTag:m_strName];
	m_strName = [m_strName stringByReplacingOccurrencesOfString:@"작성자 : " withString:@""];
	
	m_strDate = [Utils findStringRegex:m_strHtml regex:@"(입력 : <span title=).*?(</span>)"];
	m_strDate = [Utils replaceStringHtmlTag:m_strDate];
	m_strDate = [m_strDate stringByReplacingOccurrencesOfString:@"입력 : " withString:@""];
	m_strDate = [Utils replaceStringRegex:m_strDate regex:@"(\\().*?(\\))" replace:@""];

	m_strHit = [Utils findStringRegex:m_strHtml regex:@"(?<=</span>, &nbsp;조회 : ).*?(?=</div>)"];
	
	NSString *strContent;
	strContent = @"(?<=<!---- contents start 본문 표시 부분 DJ ---->).*?(?=<!---- contents end ---->)";
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strContent options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:m_strHtml options:0 range:NSMakeRange(0, [m_strHtml length])];
	if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
		m_strContent = [m_strHtml substringWithRange:rangeOfFirstMatch];
	} else {
		m_strContent = @"";
	}
	
	NSString *strAttach = [Utils findStringRegex:m_strHtml regex:@"(?<=<!-- view image file -->).*?(?=<tr><td bgcolor=)"];
	
	NSRange find7 = [m_strHtml rangeOfString:@"<p align=center><img onload=\"resizeImage2(this)\""];
	NSString *imageString = nil;
	if (find7.location != NSNotFound) {
		// 사진이 없을 수 도 있음.
		NSRange range1 = {find7.location, [m_strHtml length] - find7.location};
		NSRange find8 = [m_strHtml rangeOfString:@"</td>" options:NSLiteralSearch range:range1];
		if (find8.location != NSNotFound) {
			NSRange range2 = {find7.location, (find8.location - find7.location)};
			imageString = [m_strHtml substringWithRange:range2];
		}
	}
	
	NSString *strComment = [Utils findStringWith:m_strHtml from:@"<!-- 댓글 시작 -->" to:@"<!-- 댓글 끝 -->"];
	
	NSArray *commentItems = [strComment componentsSeparatedByString:@"<tr><td bgcolor=\"#DDDDDD\" height=\"1\" ></td></tr>"];
	
	NSMutableDictionary *currItem;
	
	int isReply = 0;
	for (int i = 1; i < [commentItems count]; i++) {
		NSString *s = [commentItems objectAtIndex:i];
		currItem = [[NSMutableDictionary alloc] init];
		
		NSRange find1 = [s rangeOfString:@"<img src=\"images/reply.gif\" border=\"0\" vspace=\"0\" hspace=\"2\" />"];
		if (find1.location == NSNotFound) {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
			isReply = 0;
		} else {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isRe"];
			isReply = 1;
		}
		
		NSString *strNo = [Utils findStringRegex:s regex:@"(?<=&number=).*?(?=')"];
		[currItem setValue:strNo forKey:@"no"];
		
		// Name
		NSString *strName = [Utils findStringRegex:s regex:@"(<font color=\"black\"><a href=\"javascript:ui).*?(</a>)"];
		strName = [Utils replaceStringHtmlTag:strName];
		[currItem setValue:strName forKey:@"name"];
		
		// Date
		NSString *strDate = [Utils findStringRegex:s regex:@"(/ <span title=\").*?(</span>)"];
		strDate = [Utils replaceStringHtmlTag:strDate];
		strDate = [Utils replaceStringRegex:strDate regex:@"/ " replace:@""];
		[currItem setValue:strDate forKey:@"date"];
		
		if (isReply == 0) {
			// Comment
			NSString *strComm = [Utils findStringRegex:s regex:@"(?<=<td bgcolor=\"#ffffff\" style=\"padding:7pt;\">).*?(?=<div id=\"reply_)"];
			strComm = [Utils replaceStringHtmlTag:strComm];
			[currItem setValue:strComm forKey:@"comment"];
		} else {
			// Comment
			NSString *strComm = [Utils findStringRegex:s regex:@"(?<=<td colspan=\"2\">).*?(?=</td>)"];
			strComm = [Utils replaceStringHtmlTag:strComm];
			[currItem setValue:strComm forKey:@"comment"];
		}
		
		[currItem setValue:[NSNumber numberWithFloat:80.0f] forKey:@"height"];
		
		[m_arrayItems addObject:currItem];
	}

	m_strEditableContent = [Utils replaceStringHtmlTag:m_strContent];
	
	if (imageString != nil) {
		NSString *resizeStr = @"<script>function resizeImage2(mm){var width = eval(mm.width);var height = eval(mm.height);if( width > 300 ){var p_height = 300 / width;var new_height = height * p_height;eval(mm.width = 300);eval(mm.height = new_height);}}</script>";
		//        NSString *imageopenStr = [NSString stringWithString:@"<script>function image_open(src, mm){var src1 = 'image2.php?imgsrc='+src;window.open(src1,'image','width=1,height=1,scrollbars=yes,resizable=yes');}</script>"];
		
		m_strContent = [NSString stringWithFormat:@"%@%@%@%@", resizeStr, m_strContent, imageString, strAttach];
	} else {
		m_strContent = [NSString stringWithFormat:@"%@%@", m_strContent, strAttach];
	}
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (void)parsePNotice
{
	//<!---- contents start ---->
	//<!---- contents end ---->
	
	/*
	 if ([m_nServerType intValue] == 1) {
		strContent = @"(?<=<!---- contents start 본문 표시 부분 DJ ---->).*?(?=<!---- contents end ---->)";
	 } else {
		strContent = @"(?<=<!---- contents start ---->).*?(?=<!---- contents end ---->)";
	 }
	 */
	m_strTitle = [Utils findStringRegex:m_strHtml regex:@"(?<=<h3 class=\"title\">).*?(?=</h3>)"];
	m_strTitle = [Utils replaceStringHtmlTag:m_strTitle];
	
	m_strName = [Utils findStringRegex:m_strHtml regex:@"(<div class=\"authorArea\">).*?(</div>)"];
	m_strName = [Utils replaceStringHtmlTag:m_strName];
	
	m_strDate = [Utils findStringRegex:m_strHtml regex:@"(<span class=\"date\">).*?(</span>)"];
	m_strDate = [Utils replaceStringHtmlTag:m_strDate];
	m_strDate = [Utils replaceStringRegex:m_strDate regex:@"(\\().*?(\\))" replace:@""];
	
	m_strHit = [Utils findStringRegex:m_strHtml regex:@"(?<=<span class=\"num\">).*?(?=</span>)"];
	
	NSString *strContent;
	strContent = @"(<!--BeforeDocument).*?(</div><!--AfterDocument)";
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strContent options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:m_strHtml options:0 range:NSMakeRange(0, [m_strHtml length])];
	if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
		m_strContent = [m_strHtml substringWithRange:rangeOfFirstMatch];
	} else {
		m_strContent = @"";
	}
	[Utils replaceStringRegex:m_strContent regex:@"(<!--).*?[(-->)" replace:@""];
	[Utils replaceStringRegex:m_strContent regex:@"<!--AfterDocument" replace:@""];
	
	NSString *imageString = [Utils findStringRegex:m_strHtml regex:@"(?<=<ul class=\"files\">).*?(?=</ul>)"];
	NSString *strComment = [Utils findStringRegex:m_strHtml regex:@"(?<=<div class=\"feedbackList\" id=\"reply\">).*?(?=<form action=)"];
	
	NSArray *commentItems = [strComment componentsSeparatedByString:@"<div class=\"item "];
	
	NSMutableDictionary *currItem;
	
	int isReply = 0;
	for (int i = 1; i < [commentItems count]; i++) {
		NSString *s = [commentItems objectAtIndex:i];
		currItem = [[NSMutableDictionary alloc] init];
		
		NSString *strLink = [Utils findStringRegex:s regex:@"(?<=<a href=\\\"http://www.gongdong.or.kr/).*?(?=\\\">)"];
		// number
		NSString *strNumber = [Utils findStringRegex:strLink regex:@"(?<=comment_srl=).*?(?=&)"];
		if ([strNumber length] <= 0) {
			strNumber = [Utils findStringRegex:strLink regex:@"(?<=comment_srl=).*?(?=$)"];
		}
		[currItem setValue:strNumber forKey:@"no"];

		if ([Utils numberOfMatches:s regex:@"<div class=\"indent\"  style=\"margin-left:"] <= 0) {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
			isReply = 0;
		} else {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isRe"];
			isReply = 1;
		}
		
		// Name
		NSString *strName = [Utils findStringRegex:s regex:@"(<a href=\"#popup_menu_area\" class=\"member_).*?(</a>)"];
		strName = [Utils replaceStringHtmlTag:strName];
		[currItem setValue:strName forKey:@"name"];
		
		// Date
		NSString *strDate = [Utils findStringRegex:s regex:@"(?<=<p class=\"meta\">).*?(?=</p>)"];
		strDate = [Utils replaceStringHtmlTag:strDate];
		strDate = [Utils replaceStringRegex:strDate regex:@"\t\t\t\t\t\t\t" replace:@" "];
		[currItem setValue:strDate forKey:@"date"];
		
		NSString *strComm = [Utils findStringRegex:s regex:@"(<!--BeforeComment).*?(?=<!--AfterComment)"];
		strComm = [Utils replaceStringHtmlTag:strComm];
		[currItem setValue:strComm forKey:@"comment"];
		
		[currItem setValue:[NSNumber numberWithFloat:80.0f] forKey:@"height"];
		
		[m_arrayItems addObject:currItem];
	}
	
	m_strEditableContent = [Utils replaceStringHtmlTag:m_strContent];
	
	if (imageString != nil) {
		NSString *resizeStr = @"<script>function resizeImage2(mm){var width = eval(mm.width);var height = eval(mm.height);if( width > 300 ){var p_height = 300 / width;var new_height = height * p_height;eval(mm.width = 300);eval(mm.height = new_height);}}</script>";
		//        NSString *imageopenStr = [NSString stringWithString:@"<script>function image_open(src, mm){var src1 = 'image2.php?imgsrc='+src;window.open(src1,'image','width=1,height=1,scrollbars=yes,resizable=yes');}</script>"];
		
		m_strContent = [NSString stringWithFormat:@"%@%@%@", resizeStr, m_strContent, imageString];
	}
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (void)parseCenter
{
	//<!---- contents start ---->
	//<!---- contents end ---->
	
	/*
	 if ([m_nServerType intValue] == 1) {
		strContent = @"(?<=<!---- contents start 본문 표시 부분 DJ ---->).*?(?=<!---- contents end ---->)";
	 } else {
		strContent = @"(?<=<!---- contents start ---->).*?(?=<!---- contents end ---->)";
	 }
	 */
	m_strTitle = [Utils findStringRegex:m_strHtml regex:@"(?<=<h3 class=\"title\">).*?(?=</h3>)"];
	m_strTitle = [Utils replaceStringHtmlTag:m_strTitle];
	
	m_strName = [Utils findStringRegex:m_strHtml regex:@"(<div class=\"authorArea\">).*?(</div>)"];
	m_strName = [Utils replaceStringHtmlTag:m_strName];
	
	m_strDate = [Utils findStringRegex:m_strHtml regex:@"(<span class=\"date\">).*?(</span>)"];
	m_strDate = [Utils replaceStringHtmlTag:m_strDate];
	m_strDate = [Utils replaceStringRegex:m_strDate regex:@"(\\().*?(\\))" replace:@""];
	
	m_strHit = [Utils findStringRegex:m_strHtml regex:@"(?<=<span class=\"num\">).*?(?=</span>)"];
	
	NSString *strContent;
	strContent = @"(<!--BeforeDocument).*?(</div><!--AfterDocument)";
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strContent options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:m_strHtml options:0 range:NSMakeRange(0, [m_strHtml length])];
	if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
		m_strContent = [m_strHtml substringWithRange:rangeOfFirstMatch];
	} else {
		m_strContent = @"";
	}
	[Utils replaceStringRegex:m_strContent regex:@"(<!--).*?[(-->)" replace:@""];
	[Utils replaceStringRegex:m_strContent regex:@"<!--AfterDocument" replace:@""];
	
	NSString *imageString = [Utils findStringRegex:m_strHtml regex:@"(?<=<ul class=\"files\">).*?(?=</ul>)"];
	NSString *strComment = [Utils findStringRegex:m_strHtml regex:@"(?<=<div class=\"feedbackList\" id=\"reply\">).*?(?=<form action=)"];
	
	NSArray *commentItems = [strComment componentsSeparatedByString:@"<div class=\"item "];
	
	NSMutableDictionary *currItem;
	
	int isReply = 0;
	for (int i = 1; i < [commentItems count]; i++) {
		NSString *s = [commentItems objectAtIndex:i];
		currItem = [[NSMutableDictionary alloc] init];
		
		NSString *strLink = [Utils findStringRegex:s regex:@"(?<=<a href=\\\"http://www.gongdong.or.kr/).*?(?=\\\">)"];
		// number
		NSString *strNumber = [Utils findStringRegex:strLink regex:@"(?<=comment_srl=).*?(?=&)"];
		if ([strNumber length] <= 0) {
			strNumber = [Utils findStringRegex:strLink regex:@"(?<=comment_srl=).*?(?=$)"];
		}
		[currItem setValue:strNumber forKey:@"no"];
		
		if ([Utils numberOfMatches:s regex:@"<div class=\"indent\"  style=\"margin-left:"] <= 0) {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
			isReply = 0;
		} else {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isRe"];
			isReply = 1;
		}
		
		// Name
		NSString *strName = [Utils findStringRegex:s regex:@"(<a href=\"#popup_menu_area\" class=\"member_).*?(</a>)"];
		strName = [Utils replaceStringHtmlTag:strName];
		[currItem setValue:strName forKey:@"name"];
		
		// Date
		NSString *strDate = [Utils findStringRegex:s regex:@"(?<=<p class=\"meta\">).*?(?=</p>)"];
		strDate = [Utils replaceStringHtmlTag:strDate];
		strDate = [Utils replaceStringRegex:strDate regex:@"\t\t\t\t\t\t\t" replace:@" "];
		[currItem setValue:strDate forKey:@"date"];
		
		NSString *strComm = [Utils findStringRegex:s regex:@"(<!--BeforeComment).*?(?=<!--AfterComment)"];
		strComm = [Utils replaceStringHtmlTag:strComm];
		[currItem setValue:strComm forKey:@"comment"];
		
		[currItem setValue:[NSNumber numberWithFloat:80.0f] forKey:@"height"];
		
		[m_arrayItems addObject:currItem];
	}
	
	m_strEditableContent = [Utils replaceStringHtmlTag:m_strContent];
	
	if (imageString != nil) {
		NSString *resizeStr = @"<script>function resizeImage2(mm){var width = eval(mm.width);var height = eval(mm.height);if( width > 300 ){var p_height = 300 / width;var new_height = height * p_height;eval(mm.width = 300);eval(mm.height = new_height);}}</script>";
		//        NSString *imageopenStr = [NSString stringWithString:@"<script>function image_open(src, mm){var src1 = 'image2.php?imgsrc='+src;window.open(src1,'image','width=1,height=1,scrollbars=yes,resizable=yes');}</script>"];
		
		m_strContent = [NSString stringWithFormat:@"%@%@%@", resizeStr, m_strContent, imageString];
	}
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}


- (bool)DeleteArticle:(NSString *)strCommNo boardNo:(NSString *)strBoardNo articleNo:(NSString *)strArticleNo
{
	// POST http://cafe.gongdong.or.kr/cafe.php?mode=del&sort=1225&sub_sort=&p1=tuntun&p2=
	// number=977381&passwd=
	
	NSString *url;
	url = [NSString stringWithFormat:@"%@/cafe.php?mode=del&sort=%@&sub_sort=&p1=%@&p2=",
			   CAFE_SERVER, strBoardNo, strCommNo];
	NSLog(@"url = [%@]", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	
	NSMutableData *body = [NSMutableData data];
	// usetag = n
	[body appendData:[[NSString stringWithFormat:@"number=%@&passwd=", strArticleNo] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:body];
	
	//returningResponse:(NSURLResponse **)response error:(NSError **)error
	NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	NSString *str = [[NSString alloc] initWithData:respData
										  encoding:NSUTF8StringEncoding];
	//history.go(-1);
	NSLog(@"returnData = [%@]", str);
	
	if ([Utils numberOfMatches:str regex:@"<meta http-equiv=\"refresh\" content=\"0;"] > 0) {
		NSLog(@"delete article success");
		return true;
	} else {
		NSString *errMsg = [Utils findStringRegex:str regex:@"(?<=window.alert\\(\\\").*?(?=\\\")"];
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"글 삭제 오류"
														message:errMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
		[alert show];
		return false;
	}
}

- (bool)DeleteComment:(NSString *)strCommNo boardNo:(NSString *)strBoardNo articleNo:(NSString *)strArticleNo commentNo:(NSString *)strCommentNo isPNotice:(int)isPNotice
{
	if (isPNotice == 0) {
		return [self DeleteCommentNormal:strCommNo boardNo:strBoardNo articleNo:strArticleNo commentNo:strCommentNo];
	} else {
		return [self DeleteCommentPNotice:strCommNo boardNo:strBoardNo articleNo:strArticleNo commentNo:strCommentNo];
	}
}

- (bool)DeleteCommentNormal:(NSString *)strCommNo boardNo:(NSString *)strBoardNo articleNo:(NSString *)strArticleNo commentNo:(NSString *)strCommentNo
{
	NSLog(@"DeleteArticleConfirm start");
	NSLog(@"commID=[%@], boardID=[%@], numberID=[%@]", strCommNo, strBoardNo, strCommentNo);
	
	// POST http://cafe.gongdong.or.kr/cafe.php?mode=del_reply&sort=1225&sub_sort=&p1=tuntun&p2=
	// number=1588986&passwd=
	
	NSString *s;
	s = @"%@/cafe.php?mode=del_reply&sort=%@&sub_sort=&p1=%@&p2=";
	
	NSString *url = [NSString stringWithFormat:s,
					 CAFE_SERVER, strBoardNo, strCommNo];
	NSLog(@"url = [%@]", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	
	NSMutableData *body = [NSMutableData data];
	// usetag = n
	[body appendData:[[NSString stringWithFormat:@"number=%@&passwd=", strCommentNo] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:body];
	
	//returningResponse:(NSURLResponse **)response error:(NSError **)error
	NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	NSString *str = [[NSString alloc] initWithData:respData
										  encoding:NSUTF8StringEncoding];
	//history.go(-1);
	NSLog(@"returnData = [%@]", str);
	
	if ([Utils numberOfMatches:str regex:@"<meta http-equiv=\"refresh\" content=\"0;"] > 0) {
		NSLog(@"delete comment success");
		return true;
	} else {
		NSString *errMsg = [Utils findStringRegex:str regex:@"(?<=window.alert\\(\\\").*?(?=\\\")"];
		
		UIAlertView *alert= [[UIAlertView alloc] initWithTitle:@"댓글 삭제 오류"
													   message:errMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
		[alert show];
		return false;
	}
}

- (bool)DeleteCommentPNotice:(NSString *)strCommNo boardNo:(NSString *)strBoardNo articleNo:(NSString *)strArticleNo commentNo:(NSString *)strCommentNo
{
	NSLog(@"DeleteCommentPNotice start");
	NSLog(@"articleNo=[%@], numberID=[%@]", strArticleNo, strCommentNo);
	
	NSString *url = @"http://www.gongdong.or.kr/index.php";
	NSLog(@"url = [%@]", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	
	[request setValue:@"http://www.gongdong.or.kr" forHTTPHeaderField:@"Origin"];
	[request setValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
	NSString *strReferer = [NSString stringWithFormat:@"http://www.gongdong.or.kr/index.php?mid=notice&document_srl=%@&act=dispBoardDeleteComment&comment_srl=%@", strArticleNo, strCommentNo];
	[request setValue:strReferer forHTTPHeaderField:@"Referer"];
	
	NSMutableData *body = [NSMutableData data];
	// usetag = n
	[body appendData:[[NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"utf-8\" ?>\n"
					   "<methodCall>\n"
					   "<params>\n"
					   "<_filter><![CDATA[delete_comment]]></_filter>\n"
					   "<error_return_url><![CDATA[/index.php?mid=notice&document_srl=%@"
					   "&act=dispBoardDeleteComment&comment_srl=%@]]></error_return_url>\n"
					   "<act><![CDATA[procBoardDeleteComment]]></act>\n"
					   "<mid><![CDATA[notice]]></mid>\n"
					   "<document_srl><![CDATA[%@]]></document_srl>\n"
					   "<comment_srl><![CDATA[%@]]></comment_srl>\n"
					   "<module><![CDATA[board]]></module>\n"
					   "</params>\n"
					   "</methodCall>", strArticleNo, strCommentNo, strArticleNo, strCommentNo] dataUsingEncoding:NSUTF8StringEncoding]];
	
	[request setHTTPBody:body];
	
	//returningResponse:(NSURLResponse **)response error:(NSError **)error
	NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	NSString *str = [[NSString alloc] initWithData:respData
										  encoding:NSUTF8StringEncoding];
	//history.go(-1);
	NSLog(@"returnData = [%@]", str);
	
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

@end
