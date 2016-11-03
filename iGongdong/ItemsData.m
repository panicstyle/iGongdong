//
//  ItemsData.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 16..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "ItemsData.h"
#import "env.h"
#import "LoginToService.h"
#import "Utils.h"

@interface ItemsData () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
	BOOL m_isConn;
	BOOL m_isLogin;
	int m_nPage;
	LoginToService *m_login;
}
@end

@implementation ItemsData

@synthesize m_strCommId;
@synthesize m_strBoardId;
//@synthesize m_strLink;
@synthesize m_arrayItems;
@synthesize m_nMode;
@synthesize m_nItemMode;
@synthesize target;
@synthesize selector;

- (void)fetchItems:(int) nPage
{
	m_arrayItems = [[NSMutableArray alloc] init];
	m_isLogin = FALSE;
	m_nPage = nPage;

	[self fetchItems2];
}

- (void)fetchItems2
{
	// http://cafe.gongdong.or.kr/cafe.php?sort=35&sub_sort=&keyfield=&key_bs=&p1=menbal&p2=&p3=&page=1&startpage=1
	NSString *url;
	if ([m_nMode intValue] == CAFE_TYPE_NORMAL) {
		url = [NSString stringWithFormat:@"%@/cafe.php?sort=%@&sub_sort=&keyfield=&key_bs=&p1=%@&p2=&p3=&page=%d", CAFE_SERVER, m_strBoardId, m_strCommId, m_nPage];
	} else if ([m_nMode intValue] == CAFE_TYPE_EDU_APP_ADMIN) {
		url = [NSString stringWithFormat:@"%@/index.php?mid=edu_app&module=admin&act=dispEnrollCourse&page=%d", WWW_SERVER, m_nPage];
	} else {
		url = [NSString stringWithFormat:@"%@/index.php?mid=%@&page=%d", WWW_SERVER, m_strBoardId, m_nPage];
	}
	
	m_receiveData = [[NSMutableData alloc] init];
	m_connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[m_receiveData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *str = [[NSString alloc] initWithData:m_receiveData
										  encoding:NSUTF8StringEncoding];
	
	/* <script type="text/javascript">
	 window.alert("로그인 하세요");
	 history.go(-1);
	 </script> */
	
	if ([Utils numberOfMatches:str regex:@"history.go\\(-1\\)"] > 0) {
		if (m_isLogin == FALSE) {
			NSLog(@"retry login");
			m_login = [[LoginToService alloc] init];
			BOOL result = [m_login LoginToService];
			if (result) {
				NSLog(@"login ok");
				m_isLogin = TRUE;
				[self fetchItems2];
				return;
			} else {
				[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_LOGIN_FAIL] afterDelay:0];
				return;
			}
		} else {
			[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_AUTH_FAIL] afterDelay:0];
			return;
		}
		return;
	}
	
	// <div id="board-content">
	// <form action="/cafe.php" method=get name=frmEdit >
	switch ([m_nMode intValue]) {
		case CAFE_TYPE_NORMAL:
			if ([Utils numberOfMatches:str regex:@"<div align=\"center\">제목</div>"]) {
				m_nItemMode = [NSNumber numberWithInt:NormalItems];
				[self getNormaltems:str];
			} else {
				m_nItemMode = [NSNumber numberWithInt:PictureItems];
				[self getPictureItems:str];
			}
			break;
		case CAFE_TYPE_CENTER:
		case CAFE_TYPE_NOTICE:
		case CAFE_TYPE_TEACHER:
			[self getCenterItems:str];
			break;
		case CAFE_TYPE_ING:
			[self getIngItems:str];
			break;
		case CAFE_TYPE_EDU_APP:
			[self getEduAppItems:str];
			break;
		case CAFE_TYPE_EDU_APP_ADMIN:
			[self getEduAppAdminItems:str];
			break;
	}
}

- (void)getNormaltems:(NSString *)str
{
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(id=\\\"board_list_line\\\").*?(<td bgcolor=\"#f5f5f5\" colspan=\"7\" height=1></td>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
	NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
	NSMutableDictionary *currItem;
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *str2 = [str substringWithRange:matchRange];
		BOOL isPNotice = FALSE;
		BOOL isNotice = FALSE;
		currItem = [[NSMutableDictionary alloc] init];
		
		// find [공지]
		if ([Utils numberOfMatches:str2 regex:@"\\[법인공지\\]"] > 0) {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isPNotice"];
			NSLog(@"isPNotice");
			isPNotice = TRUE;
		} else {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
		}
		
		// find [공지]
		if ([Utils numberOfMatches:str2 regex:@"\\[공지\\]"] > 0) {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isNotice"];
			NSLog(@"isNotice");
			isNotice = TRUE;
		} else {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
		}
		
		// subject
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<div align=\\\"left).*?(</div>)"];
		strSubject = [Utils replaceStringHtmlTag:strSubject];
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		// <a href="/cafe.php?sort=45&sub_sort=&page=&startpage=&keyfield=&key_bs=&p1=menbal&p2=&p3=&number=1163433&mode=view">
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\")"];
		NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=&number=).*?(?=&)"];
		[currItem setValue:boardNo forKey:@"boardNo"];
		
		NSString *strComment = [Utils findStringRegex:str2 regex:@"(?<=<font face=\\\"Tahoma\\\"><b>\\[).*?(?=\\]</b></font>)"];
		[currItem setValue:strComment forKey:@"comment"];
		
		// isNew
		if ([Utils numberOfMatches:str2 regex:@"img src=images/new_s\\.gif"]) {
			[currItem setValue:@"1" forKey:@"isNew"];
			NSLog(@"isNew");
		} else {
			[currItem setValue:@"0" forKey:@"isNew"];
		}
		
		if (isPNotice == 1) {
			[currItem setValue:@"법인공지" forKey:@"name"];
			[currItem setValue:@"법인공지" forKey:@"id"];
		} else if (isNotice == 1) {
			[currItem setValue:@"공지" forKey:@"name"];
			[currItem setValue:@"공지" forKey:@"id"];
		} else {
			// name
			NSString *strName = [Utils findStringRegex:str2 regex:@"(<!-- 사용자 이름 표시 부분-->).*?(</div>)"];
			strName = [Utils replaceStringHtmlTag:strName];
			[currItem setValue:strName forKey:@"name"];
			
			// id
			NSString *strID = [Utils findStringRegex:str2 regex:@"(?<=javascript:ui\\(').*?(?=')"];
			[currItem setValue:strID forKey:@"id"];
		}
		
		// date
		NSString *strDate = [Utils findStringRegex:str2 regex:@"(<div align=\\\"center\\\"><span style=\\\"font-size:8pt;\\\"><font).*?(</div>)"];
		strDate = [Utils replaceStringHtmlTag:strDate];
		[currItem setValue:strDate forKey:@"date"];
		
		// Hit
		NSString *strHit = [Utils findStringRegex:str2 regex:@"(<div align=\\\"right\\\"><span style=\\\"font-size:8pt;\\\"><font face=\\\"Tahoma\\\">).*?(&nbsp;)"];
		strHit = [Utils replaceStringHtmlTag:strHit];
		[currItem setValue:strHit forKey:@"hit"];
		
		// isReItem
		if ([Utils numberOfMatches:str2 regex:@"images/reply\\.gif"]) {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isRe"];
		} else {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
		}
		
		[m_arrayItems addObject:currItem];
	}
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

- (void)getPictureItems:(NSString *)str
{
	NSArray *arrayItems = [str componentsSeparatedByString:@"<td width=\"25%\" valign=top>"];
	
	NSMutableDictionary *currItem;
	
	for (int i = 1; i < [arrayItems count]; i++) {
		NSString *str2 = [arrayItems objectAtIndex:i];
		currItem = [[NSMutableDictionary alloc] init];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
		
		// subject
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<span style=\\\"font-size:9pt;\\\">)(.|\\n)*?(</span>)"];
		strSubject = [Utils replaceStringHtmlTag:strSubject];
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		// <a href="/cafe.php?sort=37&sub_sort=&page=&startpage=&keyfield=&key_bs=&p1=menbal&p2=&p3=&number=1285671&mode=view">
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\")(.|\\n)*?(?=\\\")"];
		NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=&number=).*?(?=&)"];
		[currItem setValue:boardNo forKey:@"boardNo"];
		
		// 댓글 갯수
		NSString *strComment = [Utils findStringRegex:str2 regex:@"(?<=<b>\\[)(.|\\n)*?(?=\\]</b>)"];
		[currItem setValue:strComment forKey:@"comment"];
		
		// 이름
		NSString *strName = [Utils findStringRegex:str2 regex:@"(?<=</span></a> \\[)(.|\\n)*?(?=\\]<span)"];
		if ([strName isEqualToString:@""]) {
			strName = [Utils findStringRegex:str2 regex:@"(?<=</span>\\[)(.|\\n)*?(?=\\]<span)"];
		}
		[currItem setValue:strName forKey:@"name"];
		
		// Hit
		NSString *strHit = [Utils findStringRegex:str2 regex:@"(?<=<font face=\"Tahoma\"><b>\\[)(.|\\n)*?(?=\\]</b>)"];
		strHit = [Utils replaceStringHtmlTag:strHit];
		[currItem setValue:strHit forKey:@"hit"];
		
		// piclink
		NSString *strPicLink = [Utils findStringRegex:str2 regex:@"(?<=background=\\\")(.|\\n)*?(?=\\\")"];
		[currItem setValue:strPicLink forKey:@"piclink"];
		
		// isNew
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNew"];
		
		// isReItem
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
		
		[m_arrayItems addObject:currItem];
	}
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

- (void)getCenterItems:(NSString *)str
{
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<tr class=).*?(</tr>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
	NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
	NSMutableDictionary *currItem;
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *str2 = [str substringWithRange:matchRange];
		BOOL isNotice = FALSE;
		NSString *strStatus = @"";
		currItem = [[NSMutableDictionary alloc] init];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
		// find [공지]
		if ([Utils numberOfMatches:str2 regex:@"<td class=\\\"notice"] > 0) {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isNotice"];
			NSLog(@"isNotice");
			isNotice = TRUE;
		} else {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
		}
		
		// subject
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<td class=\\\"title).*?(</a>)"];
		if ([m_nMode intValue] == CAFE_TYPE_TEACHER) {
			if ([Utils numberOfMatches:strSubject regex:@"teacher_icon01.gif"] > 0) {
				strStatus = @"[모집중]";
			} else {
				strStatus = @"[완료]";
			}
		}
		if (isNotice) {
			strSubject = [Utils replaceStringRegex:strSubject regex:@"(<strong).*?(/strong>)" replace:@""];
		}
		strSubject = [Utils replaceStringHtmlTag:strSubject];
		if ([m_nMode intValue] == CAFE_TYPE_TEACHER) {
			strSubject = [NSString stringWithFormat:@"%@ %@", strStatus, strSubject];
		}
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\")"];
		// <a href="http://www.gongdong.or.kr/index.php?mid=ing&amp;page=2&amp;document_srl=326671">
		NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=document_srl=).*?(?=$)"];
		[currItem setValue:boardNo forKey:@"boardNo"];
		
		NSString *strComment = [Utils findStringRegex:str2 regex:@"(?<=Replies\\\">\\[).*?(?=\\]</span>)"];
		[currItem setValue:strComment forKey:@"comment"];
		
		// isNew
		[currItem setValue:@"0" forKey:@"isNew"];
		
		if ([m_nMode intValue] == CAFE_TYPE_NOTICE) {
			if (isNotice == 1) {
				[currItem setValue:@"공지" forKey:@"name"];
				[currItem setValue:@"공지" forKey:@"id"];
			} else {
				[currItem setValue:@"" forKey:@"name"];
				[currItem setValue:@"" forKey:@"id"];
			}
		} else {
			// name
			NSString *strName = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"author\\\">).*?(?=</td>)"];
			strName = [Utils replaceStringHtmlTag:strName];
			[currItem setValue:strName forKey:@"name"];
			
		}

		// date
		NSString *strDate = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"date\\\">).*?(?=</td>)"];
		//		strDate = [Utils replaceStringHtmlTag:strDate];
		[currItem setValue:strDate forKey:@"date"];
		
		// Hit
		NSString *strHit = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"reading\\\">).*?(?=</td>)"];
//		strHit = [Utils replaceStringHtmlTag:strHit];
		[currItem setValue:strHit forKey:@"hit"];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
		
		[m_arrayItems addObject:currItem];
	}
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

- (void)getIngItems:(NSString *)str
{
	NSArray *arrayItems = [str componentsSeparatedByString:@"<li style="];
	
	NSMutableDictionary *currItem;
	
	for (int i = 1; i < [arrayItems count]; i++) {
		NSString *str2 = [arrayItems objectAtIndex:i];
		currItem = [[NSMutableDictionary alloc] init];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
		
		// subject
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<div class=\\\"title).*?(</a>)"];
		strSubject = [Utils replaceStringHtmlTag:strSubject];
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\")"];
		NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=document_srl=).*?(?=$)"];
		[currItem setValue:boardNo forKey:@"boardNo"];

		// Comment 가 없음
		[currItem setValue:@"" forKey:@"comment"];
		
		// isNew
		[currItem setValue:@"0" forKey:@"isNew"];
		
		// name
		NSString *strName = [Utils findStringRegex:str2 regex:@"(<li class=\\\"author).*?(</a>)"];
		strName = [Utils replaceStringHtmlTag:strName];
		[currItem setValue:strName forKey:@"name"];
		
		// date
		NSString *strDate = [Utils findStringRegex:str2 regex:@"(?<=<li class=\\\"date\\\">).*?(?=</li>)"];
		//		strDate = [Utils replaceStringHtmlTag:strDate];
		[currItem setValue:strDate forKey:@"date"];
		
		// Hit
		NSString *strHit = [Utils findStringRegex:str2 regex:@"(?<=<li class=\\\"reading\\\">조회 수 ).*?(?=</li>)"];
		//		strHit = [Utils replaceStringHtmlTag:strHit];
		[currItem setValue:strHit forKey:@"hit"];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
		
		[m_arrayItems addObject:currItem];
	}
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

- (void)getEduAppItems:(NSString *)str
{
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<tr class=).*?(</tr>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
	NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
	NSMutableDictionary *currItem;
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *str2 = [str substringWithRange:matchRange];
		BOOL isNotice = FALSE;
		NSString *strStatus = @"";
		currItem = [[NSMutableDictionary alloc] init];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
		
		// subject
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(?<=class=\\\"title\\\">).*?(?=</a>)"];
		strSubject = [Utils replaceSpecialString:strSubject];
		if ([Utils numberOfMatches:str2 regex:@"edu_app_01.gif"] > 0) {
			strStatus = @"[모집중]";
		} else {
			strStatus = @"[완료]";
		}
		strSubject = [NSString stringWithFormat:@"%@ %@", strStatus, strSubject];
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\" class=\\\"title)"];
		NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=document_srl=).*?(?=$)"];
		[currItem setValue:boardNo forKey:@"boardNo"];
		
		// find apply link
		NSString *strApplyLink = [Utils findStringRegex:str2 regex:@"(<a  target=\\\"_blank\\\" href=\\\"/xe).*?(\\\">)"];
		[currItem setValue:strApplyLink forKey:@"applyLink"];
		
		[currItem setValue:@"" forKey:@"comment"];
		
		// isNew
		[currItem setValue:@"0" forKey:@"isNew"];
		
		// name
		NSString *strName = [Utils findStringRegex:str2 regex:@"(?<=<span class=\\\"category\\\">).*?(?=</span>)"];
//		strName = [Utils replaceStringHtmlTag:strName];
		[currItem setValue:strName forKey:@"name"];
		
		// date
		NSString *strDate = [Utils findStringRegex:str2 regex:@"(?<=일시 : ).*?(?= &nbsp;)"];
		//		strDate = [Utils replaceStringHtmlTag:strDate];
		[currItem setValue:strDate forKey:@"date"];
		
		[currItem setValue:@"" forKey:@"hit"];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
		
		[m_arrayItems addObject:currItem];
	}
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

- (void)getEduAppAdminItems:(NSString *)str
{
	NSString *str0 = [Utils findStringRegex:str regex:@"(<!-- // 교육신청 목록 -->).*?(<!-- // 페이지 네비게이션 -->)"];
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<tr>).*?(</tr>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
	NSArray *matches = [regex matchesInString:str0 options:0 range:NSMakeRange(0, [str0 length])];
	NSMutableDictionary *currItem;
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *str2 = [str0 substringWithRange:matchRange];
		
		str2 = [Utils replaceStringRegex:str2 regex:@"(<!--).*?(-->)" replace:@""];
		
		BOOL isNotice = FALSE;
		NSString *strStatus = @"";
		currItem = [[NSMutableDictionary alloc] init];
		
		if ([Utils numberOfMatches:str2 regex:@"<th"] > 0) {
			continue;
		}
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
		
		// subject
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<a href=).*?(</a>)"];
		strSubject = [Utils replaceSpecialString:strSubject];
		strSubject = [Utils replaceStringHtmlTag:strSubject];
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		// <a href="http://www.gongdong.or.kr/index.php?mid=edu_app&amp;module=admin&amp;course_no=212&amp;act=dispEnrollByCourse">
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\">)"];
		NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=course_no=).*?(?=$)"];
		if ([boardNo isEqualToString:@""]) {
			boardNo = [Utils findStringRegex:strLink regex:@"(?<=course_no=).*?(?=&)"];
		}
		[currItem setValue:boardNo forKey:@"boardNo"];
		
		[currItem setValue:@"" forKey:@"comment"];
		
		// isNew
		[currItem setValue:@"0" forKey:@"isNew"];
		
		// name
		NSString *strName = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"no\\\">).*?(?=</td>)"];
		//		strName = [Utils replaceStringHtmlTag:strName];
		[currItem setValue:strName forKey:@"name"];
		
		// date
		[currItem setValue:@"" forKey:@"date"];
		
		[currItem setValue:@"" forKey:@"hit"];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
		
		[m_arrayItems addObject:currItem];
	}
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

@end
