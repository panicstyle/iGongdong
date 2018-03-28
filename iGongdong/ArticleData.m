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
}
@end

@implementation ArticleData

@synthesize m_isPNotice;
@synthesize m_strCommId;
@synthesize m_strBoardId;
@synthesize m_strBoardNo;
@synthesize m_strApplyLink;
@synthesize m_arrayItems;
@synthesize m_attachItems;
@synthesize m_nMode;
@synthesize target;
@synthesize selector;

@synthesize m_strHtml;
@synthesize m_strTitle;
@synthesize m_strName;
@synthesize m_strDate;
@synthesize m_strHit;
@synthesize m_strContent;
@synthesize m_strEditableContent;

- (void)fetchItems
{
	m_arrayItems = [[NSMutableArray alloc] init];
	
	m_isConn = TRUE;
	m_isLogin = FALSE;
	
	[self fetchItems2];
}

- (void)fetchItems2
{
	NSString *url;
 //http://cafe.gongdong.or.kr/cafe.php?sort=35&sub_sort=&page=2&startpage=1&keyfield=&key_bs=&p1=menbal&p2=&p3=&number=1283064&mode=view
	if ([m_nMode intValue] == CAFE_TYPE_NORMAL) {
		if ([m_isPNotice intValue] == 0) {
			url = [NSString stringWithFormat:@"%@/cafe.php?sort=%@&sub_sort=&page=1&startpage=1&keyfield=&key_bs=&p1=%@&p2=&p3=&number=%@&mode=view", CAFE_SERVER, m_strBoardId, m_strCommId, m_strBoardNo];
		} else {
			// http://www.gongdong.or.kr/notice/342940
			url = [NSString stringWithFormat:@"http://www.gongdong.or.kr/bbs/board.php?bo_table=%@&wr_id=%@", m_strBoardId, m_strBoardNo];
		}
	} else if ([m_nMode intValue] == CAFE_TYPE_EDU_APP_ADMIN) {
		// http://www.gongdong.or.kr/index.php?mid=edu_app&module=admin&act=dispEnrollByCourse&course_no=225
		// http://www.gongdong.or.kr/index.php?mid=edu_app&module=admin&course_no=225&act=dispEnrollByCourse
		url = [NSString stringWithFormat:@"http://www.gongdong.or.kr/index.php?mid=edu_app&module=admin&course_no=%@&act=dispEnrollByCourse", m_strBoardNo];
	} else {
		// http://www.gongdong.or.kr/ing/343335
		url = [NSString stringWithFormat:@"http://www.gongdong.or.kr/%@/%@", m_strBoardId, m_strBoardNo];
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

	switch ([m_nMode intValue]) {
		case CAFE_TYPE_NORMAL:
			if ([m_isPNotice intValue] == 0) {
				[self parseNormal];
			} else {
				[self parsePNotice];
			}
			break;
		case CAFE_TYPE_NOTICE:
			[self parsePNotice];
			break;
		case CAFE_TYPE_CENTER:
			[self parseCenter];
			break;
		case CAFE_TYPE_ING:
			[self parseIng];
			break;
		case CAFE_TYPE_TEACHER:
			[self parseTeacher];
			break;
		case CAFE_TYPE_EDU_APP:
			[self parseEduApp];
			break;
		case CAFE_TYPE_EDU_APP_ADMIN:
			if ([Utils numberOfMatches:m_strHtml regex:@"msg_is_not_administrator"] > 0) {
				[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_AUTH_FAIL] afterDelay:0];
				return;
			}
			
			[self parseEduAppAdmin];
			break;
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
	strContent = [Utils findStringRegex:m_strHtml regex:@"(?<=<!---- contents start 본문 표시 부분 DJ ---->).*?(?=<!---- contents end ---->)"];
	
    NSString *strAttach = [Utils findStringRegex:m_strHtml regex:@"(?<=<!-- view image file -->).*?(?=<tr><td  height=1  ></td></tr>)"];
//    strAttach = [strAttach stringByReplacingOccurrencesOfString:@"height=30 class=default" withString:@""];
    if ([strAttach length] < 140) {
        strAttach = @"";
    }
	NSRange find7 = [m_strHtml rangeOfString:@"<p align=center><img onload=\"resizeImage2(this)\""];
	NSString *imageString = @"";
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
			NSString *strComm = [Utils findStringRegex:s regex:@"(?<=<td style=\"padding:7pt;\">).*?(?=<div id=\"reply_)"];
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

	m_strEditableContent = [Utils replaceStringHtmlTag:strContent];
	
	NSMutableString *strHeader = [[NSMutableString alloc] init];
	[strHeader appendString:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"];
	[strHeader appendString:@"<html><head>"];
	[strHeader appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	[strHeader appendString:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, target-densitydpi=medium-dpi\">"];
	[strHeader appendString:@"<script>function myapp_clickImg(obj){window.location=\"jscall://\"+encodeURIComponent(obj.src);}</script>"];
	[strHeader appendString:@"</head>"];
	
	NSString *strBottom = @"</body></html>";
	//        String cssStr = "<link href=\"./css/default.css\" rel=\"stylesheet\">";
	NSString *strBody = @"<body>";
	
	[strContent stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	[imageString stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	
	/* 이미지 테크에 width 값과 click 시 javascript 를 호출하도록 수정한다. */
	m_strContent = [[NSString alloc] initWithFormat:@"%@%@<table>%@</table><div>%@</div>%@%@",
					strHeader,
					strBody,
                    strAttach,
					[strContent stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					[imageString stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					strBottom];

	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (NSDictionary *)parseAttach:(NSString *)strAttach
{
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<li).*?(</li>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
	NSArray *matches = [regex matchesInString:strAttach options:0 range:NSMakeRange(0, [strAttach length])];
	NSMutableDictionary *currItem = [[NSMutableDictionary alloc] init];
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *str = [strAttach substringWithRange:matchRange];
		
		NSString *strKey = [Utils findStringRegex:str regex:@"(?<=href=\").*?(?=\">)"];
		strKey = [strKey stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];

		NSString *strValue= [Utils findStringRegex:str regex:@"(?<=\">).*?(?=<span class)"];
		strValue = [strValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		[currItem setValue:strValue forKey:strKey];
	}
	return currItem;
}

- (void)parsePNotice
{
    m_strTitle = [Utils findStringRegex:m_strHtml regex:@"(?<=<h1 id=\\\"bo_v_title\\\">).*?(?=</h1>)"];
    m_strTitle = [Utils replaceStringHtmlTag:m_strTitle];
    
    m_strName = [Utils findStringRegex:m_strHtml regex:@"(?<=<span class=\\\"sv_member\\\">).*?(?=</span>)"];
    
    m_strDate = [Utils findStringRegex:m_strHtml regex:@"(?<=작성일</span><strong>).*?(?=</strong>)"];
    
    m_strHit = [Utils findStringRegex:m_strHtml regex:@"(?<=조회<strong>).*?(?=회</strong>)"];
    
    m_strContent = [Utils findStringRegex:m_strHtml regex:@"(<!-- 본문 내용 시작).*?(본문 내용 끝 -->)"];
    m_strContent = [m_strContent stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onload=\"resizeImage2(this)\" "];
    
    NSString *strAttach = [Utils findStringRegex:m_strHtml regex:@"(<!-- 첨부파일 시작).*?(첨부파일 끝 -->)"];
    strAttach = [strAttach stringByReplacingOccurrencesOfString:@"<h2>첨부파일</h2>" withString:@""];
    
    NSString *strImage = [Utils findStringRegex:m_strHtml regex:@"(<div id=\\\"bo_v_img\\\">).*?(</div>)"];
    strImage = [strImage stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onload=\"resizeImage2(this)\" "];
    
    m_attachItems = [self parseAttach:strAttach];
    
    NSString *strComment = [Utils findStringRegex:m_strHtml regex:@"(<!-- 댓글 시작).*?(댓글 끝 -->)"];
    
    NSArray *commentItems = [strComment componentsSeparatedByString:@"<article id="];
    
    NSMutableDictionary *currItem;
    
    int isReply = 0;
    for (int i = 1; i < [commentItems count]; i++) {
        NSString *s = [commentItems objectAtIndex:i];
        currItem = [[NSMutableDictionary alloc] init];
        
        if ([Utils numberOfMatches:s regex:@"icon_reply.gif"] > 0) {
            [currItem setValue:[NSNumber numberWithInt:1] forKey:@"isRe"];
            isReply = 1;
        } else {
            [currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
            isReply = 0;
        }
        
        NSString *strNo = [Utils findStringRegex:s regex:@"(?<=span id=\\\"edit_).*?(?=\\\")"];
        [currItem setValue:strNo forKey:@"no"];
        
        // Name
        NSString *strName = [Utils findStringRegex:s regex:@"(?<=<span class=\\\"member\\\">).*?(?=</span>)"];
        [currItem setValue:strName forKey:@"name"];
        
        // Date
        NSString *strDate = [Utils findStringRegex:s regex:@"(<time datetime=).*?(</time>)"];
        strDate = [Utils replaceStringHtmlTag:strDate];
        [currItem setValue:strDate forKey:@"date"];
        
        // Comment
        NSString *strComm = [Utils findStringRegex:s regex:@"(<!-- 댓글 출력 -->).*?(<!-- 수정 -->)"];
        strComm = [Utils replaceStringHtmlTag:strComm];
        [currItem setValue:strComm forKey:@"comment"];

        // delete link 법인공지의 경우 삭제시 별도의 token 정보가 필요함.
        NSString *strDeleteLink = [Utils findStringRegex:s regex:@"(./delete_comment.php).*?(page=)"];
        if (strDeleteLink == nil) strDeleteLink = @"";
        strDeleteLink = [strDeleteLink stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        [currItem setValue:strDeleteLink forKey:@"deletelink"];

        [currItem setValue:[NSNumber numberWithFloat:80.0f] forKey:@"height"];
        
        [m_arrayItems addObject:currItem];
    }
    
    m_strEditableContent = [Utils replaceStringHtmlTag:m_strContent];
    
    NSString *resizeStr = @"<script>function resizeImage2(mm){var window_innerWidth = window.innerWidth - 30;var width = eval(mm.width);var height = eval(mm.height);if( width > window_innerWidth ){var p_height = window_innerWidth / width;var new_height = height * p_height;eval(mm.width = window_innerWidth);eval(mm.height = new_height);}}</script>";
    //        NSString *imageopenStr = [NSString stringWithString:@"<script>function image_open(src, mm){var src1 = 'image2.php?imgsrc='+src;window.open(src1,'image','width=1,height=1,scrollbars=yes,resizable=yes');}</script>"];
    
    m_strContent = [NSString stringWithFormat:@"%@%@%@%@", resizeStr, m_strContent, strAttach, strImage];
    
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
	strContent = [Utils findStringRegex:m_strHtml regex:@"(<!--BeforeDocument).*?(</div><!--AfterDocument)"];
	
	[Utils replaceStringRegex:strContent regex:@"(<!--).*?[(-->)" replace:@""];
	strContent = [strContent stringByReplacingOccurrencesOfString:@"<!--AfterDocument" withString:@""];
	
	NSString *imageString = [Utils findStringRegex:m_strHtml regex:@"(<ul class=\"files).*?(</ul>)"];
	// 첨부파일명이 링크에 없기 때문에 imageString 에서 파일명과 링크를 key, value 로 구성해서 첨부파일 링크 클릭시 파일명을 가져올 수 있도록 한다.
	m_attachItems = [self parseAttach:imageString];

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
	
	m_strEditableContent = [Utils replaceStringHtmlTag:strContent];
	
	NSMutableString *strHeader = [[NSMutableString alloc] init];
	[strHeader appendString:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"];
	[strHeader appendString:@"<html><head>"];
	[strHeader appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	[strHeader appendString:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, target-densitydpi=medium-dpi\">"];
	[strHeader appendString:@"<script>function myapp_clickImg(obj){window.location=\"jscall://\"+encodeURIComponent(obj.src);}</script>"];
	[strHeader appendString:@"</head>"];
	
	NSString *strBottom = @"</body></html>";
	//        String cssStr = "<link href=\"./css/default.css\" rel=\"stylesheet\">";
	NSString *strBody = @"<body>";
	
	[strContent stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	[imageString stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	
	/* 이미지 테크에 width 값과 click 시 javascript 를 호출하도록 수정한다. */
	m_strContent = [[NSString alloc] initWithFormat:@"%@%@%@%@%@",
					strHeader,
					strBody,
					[strContent stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					[imageString stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					strBottom];
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (void)parseIng
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
	m_strTitle = [Utils findStringRegex:m_strHtml regex:@"(?<=<h3 class=\"title_ing\">).*?(?=</h3>)"];
	m_strTitle = [Utils replaceStringHtmlTag:m_strTitle];
	m_strTitle = [Utils replaceStringHtmlTag:m_strTitle];

	// m_strName은 넘어온 값을 그대로 사용함. 본문에는 작성자가 없음.
	
	// m_strDate도 넘어온 값을 그대로 사용함. 본문에는 날짜가 없음.
	
	// m_strHit도 넘오온 값을 그대로 사용함. 본문에는 조회수가 없음.
	
	NSString *strContent;
	strContent = [Utils findStringRegex:m_strHtml regex:@"(<!--BeforeDocument).*?(</div><!--AfterDocument)"];
	
	[Utils replaceStringRegex:strContent regex:@"(<!--).*?[(-->)" replace:@""];
	strContent = [strContent stringByReplacingOccurrencesOfString:@"<!--AfterDocument" withString:@""];
	
	NSString *imageString = [Utils findStringRegex:m_strHtml regex:@"(?<=<ul class=\"files\">).*?(?=</ul>)"];
	// 첨부파일명이 링크에 없기 때문에 imageString 에서 파일명과 링크를 key, value 로 구성해서 첨부파일 링크 클릭시 파일명을 가져올 수 있도록 한다.
	m_attachItems = [self parseAttach:imageString];

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
	
	m_strEditableContent = [Utils replaceStringHtmlTag:strContent];
	
	NSMutableString *strHeader = [[NSMutableString alloc] init];
	[strHeader appendString:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"];
	[strHeader appendString:@"<html><head>"];
	[strHeader appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	[strHeader appendString:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, target-densitydpi=medium-dpi\">"];
	[strHeader appendString:@"<script>function myapp_clickImg(obj){window.location=\"jscall://\"+encodeURIComponent(obj.src);}</script>"];
	[strHeader appendString:@"</head>"];
	
	NSString *strBottom = @"</body></html>";
	//        String cssStr = "<link href=\"./css/default.css\" rel=\"stylesheet\">";
	NSString *strBody = @"<body>";
	
	[strContent stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	[imageString stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	
	/* 이미지 테크에 width 값과 click 시 javascript 를 호출하도록 수정한다. */
	m_strContent = [[NSString alloc] initWithFormat:@"%@%@%@%@%@",
					strHeader,
					strBody,
					[strContent stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					[imageString stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					strBottom];

	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (void)parseTeacher
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
	strContent = [Utils findStringRegex:m_strHtml regex:@"(<!--BeforeDocument).*?(</div><!--AfterDocument)"];
	
	[Utils replaceStringRegex:strContent regex:@"(<!--).*?[(-->)" replace:@""];
	strContent = [strContent stringByReplacingOccurrencesOfString:@"<!--AfterDocument" withString:@""];
	
	NSString *strStatus;
	strStatus = [Utils findStringRegex:m_strHtml regex:@"(<table border=\\\"1\\\" cellspacing=\\\"0\\\" summary=\\\"Extra Form\\\" class=\\\"extraVarsList).*?(</td>)"];
	strContent = [NSString stringWithFormat:@"%@</table>%@", strStatus, strContent];
	
	NSString *imageString = [Utils findStringRegex:m_strHtml regex:@"(?<=<ul class=\"files\">).*?(?=</ul>)"];
	// 첨부파일명이 링크에 없기 때문에 imageString 에서 파일명과 링크를 key, value 로 구성해서 첨부파일 링크 클릭시 파일명을 가져올 수 있도록 한다.
	m_attachItems = [self parseAttach:imageString];

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
	
	m_strEditableContent = [Utils replaceStringHtmlTag:strContent];
	
	NSMutableString *strHeader = [[NSMutableString alloc] init];
	[strHeader appendString:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"];
	[strHeader appendString:@"<html><head>"];
	[strHeader appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	[strHeader appendString:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, target-densitydpi=medium-dpi\">"];
	[strHeader appendString:@"<script>function myapp_clickImg(obj){window.location=\"jscall://\"+encodeURIComponent(obj.src);}</script>"];
	[strHeader appendString:@"</head>"];
	
	NSString *strBottom = @"</body></html>";
	//        String cssStr = "<link href=\"./css/default.css\" rel=\"stylesheet\">";
	NSString *strBody = @"<body>";
	
	[strContent stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	[imageString stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	
	/* 이미지 테크에 width 값과 click 시 javascript 를 호출하도록 수정한다. */
	m_strContent = [[NSString alloc] initWithFormat:@"%@%@%@%@%@",
					strHeader,
					strBody,
					[strContent stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					[imageString stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					strBottom];
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (void)parseEduApp
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
	
	NSString *strCategory = [Utils findStringRegex:m_strHtml regex:@"(?<=class=\\\"category\\\">).*?(?=</a>)"];
	m_strTitle = [NSString stringWithFormat:@"[%@]%@", strCategory, m_strTitle];
	
	m_strName = [Utils findStringRegex:m_strHtml regex:@"(<div class=\"authorArea\">).*?(</div>)"];
	m_strName = [Utils replaceStringRegex:m_strName regex:@"(<span).*?(</span>)" replace:@""];
	m_strName = [Utils replaceStringRegex:m_strName regex:@"(<a href=\\\"h).*?(</a>)" replace:@""];
	m_strName = [Utils replaceStringHtmlTag:m_strName];
	
	m_strDate = [Utils findStringRegex:m_strHtml regex:@"(<span class=\"date\">).*?(</span>)"];
	m_strDate = [Utils replaceStringHtmlTag:m_strDate];
	m_strDate = [Utils replaceStringRegex:m_strDate regex:@"(\\().*?(\\))" replace:@""];
	
	m_strHit = [Utils findStringRegex:m_strHtml regex:@"(?<=<span class=\"num\">).*?(?=</span>)"];
	
	NSString *strContent;
	strContent = [Utils findStringRegex:m_strHtml regex:@"(<!--BeforeDocument).*?(</div><!--AfterDocument)"];
	[Utils replaceStringRegex:strContent regex:@"(<!--).*?[(-->)" replace:@""];
	strContent = [strContent stringByReplacingOccurrencesOfString:@"<!--AfterDocument" withString:@""];
	
	NSString *strStatus;
	strStatus = [Utils findStringRegex:m_strHtml regex:@"(<table border=\\\"1\\\" cellspacing=\\\"0\\\" summary=\\\"Extra Form\\\" class=\\\"extraVarsList).*?(</table>)"];
	
	if ([Utils numberOfMatches:strStatus regex:@"신청기간중"] > 0) {
		NSString *strApply;
		strApply = [NSString stringWithFormat:@"<tr><td>%@수강신청 바로가기</a></td></tr></table>", m_strApplyLink];
		
		strStatus = [Utils replaceStringRegex:strStatus regex:@"</table>" replace:strApply];
	}
	
	strContent = [NSString stringWithFormat:@"%@</table>%@", strStatus, strContent];
	
	NSString *imageString = [Utils findStringRegex:m_strHtml regex:@"(?<=<ul class=\"files\">).*?(?=</ul>)"];
	// 첨부파일명이 링크에 없기 때문에 imageString 에서 파일명과 링크를 key, value 로 구성해서 첨부파일 링크 클릭시 파일명을 가져올 수 있도록 한다.
	m_attachItems = [self parseAttach:imageString];
	
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
	
	m_strEditableContent = [Utils replaceStringHtmlTag:strContent];
	
	NSMutableString *strHeader = [[NSMutableString alloc] init];
	[strHeader appendString:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">"];
	[strHeader appendString:@"<html><head>"];
	[strHeader appendString:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">"];
	[strHeader appendString:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, target-densitydpi=medium-dpi\">"];
	[strHeader appendString:@"<script>function myapp_clickImg(obj){window.location=\"jscall://\"+encodeURIComponent(obj.src);}</script>"];
	[strHeader appendString:@"</head>"];
	
	NSString *strBottom = @"</body></html>";
	//        String cssStr = "<link href=\"./css/default.css\" rel=\"stylesheet\">";
	NSString *strBody = @"<body>";
	
	[strContent stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	[imageString stringByReplacingOccurrencesOfString:@"onload=\"resizeImage2(this)\"" withString:@""];
	
	/* 이미지 테크에 width 값과 click 시 javascript 를 호출하도록 수정한다. */
	m_strContent = [[NSString alloc] initWithFormat:@"%@%@%@%@%@",
					strHeader,
					strBody,
					[strContent stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					[imageString stringByReplacingOccurrencesOfString:@"<img " withString:@"<img onclick=\"myapp_clickImg(this)\" width=300 "],
					strBottom];
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (void)parseEduAppAdmin
{
	m_strTitle = [Utils findStringRegex:m_strHtml regex:@"(<div class=\\\"enroll_content).*?(</h2>)"];
	m_strTitle = [Utils replaceStringHtmlTag:m_strTitle];
	
	m_strName = @"";

	NSString *strContent = [Utils findStringRegex:m_strHtml regex:@"(<!-- // 교육신청 목록 -->).*?(<!-- // 링크 입력폼 -->)"];

	NSString *strStyle = @"<style type=\"text/css\">.listTable { border-collapse:collapse;  }	.listTable td { border: solid 1px #ccc; font-size: 1.0em; padding: 5px }	</style>";
	m_strContent = [NSString stringWithFormat:@"%@%@", strStyle, strContent];
	
	m_strEditableContent = strContent;
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
	return;
}

- (bool)DeleteArticle:(NSString *)strCommId boardId:(NSString *)strBoardId boardNo:(NSString *)strBoardNo
{
	// POST http://cafe.gongdong.or.kr/cafe.php?mode=del&sort=1225&sub_sort=&p1=tuntun&p2=
	// number=977381&passwd=
	
	NSString *url;
	url = [NSString stringWithFormat:@"%@/cafe.php?mode=del&sort=%@&sub_sort=&p1=%@&p2=",
			   CAFE_SERVER, strBoardId, strCommId];
	NSLog(@"url = [%@]", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	
	NSMutableData *body = [NSMutableData data];
	// usetag = n
	[body appendData:[[NSString stringWithFormat:@"number=%@&passwd=", strBoardNo] dataUsingEncoding:NSUTF8StringEncoding]];
	
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

- (bool)DeleteComment:(NSString *)strCommId boardId:(NSString *)strBoardId boardNo:(NSString *)strBoardNo commentNo:(NSString *)strCommentNo deleteLink:(NSString *)strDeleteLink isPNotice:(int)isPNotice Mode:(int)nMode
{
	if (nMode == CAFE_TYPE_NORMAL) {
		if (isPNotice == 0) {
			return [self DeleteCommentNormal:strCommId boardId:strBoardId boardNo:strBoardNo commentNo:strCommentNo];
		} else {
			return [self DeleteCommentPNotice:strDeleteLink];
		}
	} else {
		return [self DeleteCommentPNotice:strDeleteLink];
	}
}

- (bool)DeleteCommentNormal:(NSString *)strCommId boardId:(NSString *)strBoardId boardNo:(NSString *)strBoardNo commentNo:(NSString *)strCommentNo
{
	NSLog(@"DeleteArticleConfirm start");
	NSLog(@"commId=[%@], boardId=[%@], boardNo=[%@], commentID=[%@]", strCommId, strBoardId, strBoardNo, strCommentNo);
	
	// POST http://cafe.gongdong.or.kr/cafe.php?mode=del_reply&sort=1225&sub_sort=&p1=tuntun&p2=
	// number=1588986&passwd=
	
	NSString *s;
	s = @"%@/cafe.php?mode=del_reply&sort=%@&sub_sort=&p1=%@&p2=";
	
	NSString *url = [NSString stringWithFormat:s,
					 CAFE_SERVER, strBoardId, strCommId];
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

- (bool)DeleteCommentPNotice:(NSString *)strDeleteLink
{
	NSLog(@"DeleteCommentPNotice start");
	NSLog(@"deleteLink=[%@]", strDeleteLink);
	
	NSString *url = @"http://www.gongdong.or.kr/bbs/";
    url = [url stringByAppendingString:strDeleteLink];
	NSLog(@"url = [%@]", url);
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"GET"];
	
	[request setValue:@"http://www.gongdong.or.kr" forHTTPHeaderField:@"Origin"];
	
	NSMutableData *body = [NSMutableData data];
	
	[request setHTTPBody:body];
	
	//returningResponse:(NSURLResponse **)response error:(NSError **)error
	NSData *respData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
	
	NSString *str = [[NSString alloc] initWithData:respData
										  encoding:NSUTF8StringEncoding];
	//history.go(-1);
	NSLog(@"returnData = [%@]", str);
	
    if ([Utils numberOfMatches:str regex:@"<title>오류안내 페이지"] > 0) {
        NSString *errmsg;
        errmsg = [Utils findStringRegex:str regex:@"(<p class=\\\"cbg\\\">).*?(</p>)"];
        errmsg = [Utils replaceStringHtmlTag:errmsg];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"글 작성 오류"
                                                        message:errmsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"확인", nil];
        [alert show];
        return false;
    } else {
        NSLog(@"delete comment success");
        return true;
    }
}

@end
