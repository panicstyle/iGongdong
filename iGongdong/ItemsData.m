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
	int m_intMode;
}
@end

@implementation ItemsData

@synthesize m_strCommNo;
@synthesize m_strLink;
@synthesize m_arrayItems;
@synthesize m_nMode;
@synthesize target;
@synthesize selector;

- (void)fetchItems:(int) nPage
{
	m_arrayItems = [[NSMutableArray alloc] init];
	m_isLogin = FALSE;
	m_nPage = nPage;
	m_intMode = [m_nMode intValue];

	[self fetchItems2];
}

- (void)fetchItems2
{
	NSString *url;
	if (m_intMode == CAFE_TYPE_TITLE) {
		url = [NSString stringWithFormat:@"%@/%@&page=%d", CAFE_SERVER, m_strLink, m_nPage];
	} else {
		url = [NSString stringWithFormat:@"%@/index.php?mid=%@&page=%d", WWW_SERVER, m_strLink, m_nPage];
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
	if (m_intMode == CAFE_TYPE_TITLE) {
		if ([Utils numberOfMatches:str regex:@"<div align=\"center\">제목</div>"]) {
			m_nMode = [NSNumber numberWithInt:NormalItems];
			[self getNormaltems:str];
		} else {
			m_nMode = [NSNumber numberWithInt:PictureItems];
			[self getPictureItems:str];
		}
	} else if (m_intMode == CAFE_TYPE_CENTER) {
		[self getCenterItems:str];
	} else if (m_intMode == CAFE_TYPE_ING) {
//		[self getIngItems:str];
	} else if (m_intMode == CAFE_TYPE_TEACHER) {
//		[self getTeacherItems:str];
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
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\")"];
		[currItem setValue:strLink forKey:@"link"];
		
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
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\")(.|\\n)*?(?=\\\")"];
		[currItem setValue:strLink forKey:@"link"];
		
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
		BOOL isPNotice = FALSE;
		BOOL isNotice = FALSE;
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
		strSubject = [Utils replaceStringHtmlTag:strSubject];
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\")"];
		[currItem setValue:strLink forKey:@"link"];
		
		NSString *strComment = [Utils findStringRegex:str2 regex:@"(?<=Replies\\\">\\[).*?(?=\\]</span>)"];
		[currItem setValue:strComment forKey:@"comment"];
		
		// isNew
		[currItem setValue:@"0" forKey:@"isNew"];
		
		if (isNotice == 1) {
			[currItem setValue:@"공지" forKey:@"name"];
			[currItem setValue:@"공지" forKey:@"id"];
		} else {
			[currItem setValue:@"" forKey:@"name"];
			[currItem setValue:@"" forKey:@"id"];
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

@end
