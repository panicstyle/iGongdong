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
#import "NSString+HTML.h"

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
	NSString *url;
	if ([m_nMode intValue] == CAFE_TYPE_NORMAL) {
		url = [NSString stringWithFormat:@"%@/cafe.php?sort=%@&sub_sort=&keyfield=&key_bs=&p1=%@&p2=&p3=&page=%d", CAFE_SERVER, m_strBoardId, m_strCommId, m_nPage];
	} else if ([m_nMode intValue] == CAFE_TYPE_APPLY) {
        // Create NSData object
        NSString *escaped = [m_strBoardId stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url = [NSString stringWithFormat:@"%@/bbs/board.php?bo_table=B691&sca=%@&page=%d", WWW_SERVER, escaped, m_nPage];
	} else {
		url = [NSString stringWithFormat:@"%@/bbs/board.php?bo_table=%@&page=%d", WWW_SERVER, m_strBoardId, m_nPage];
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
	
    if ([Utils numberOfMatches:str regex:@"window.alert(\\\"권한이 없습니다"] > 0 || [Utils numberOfMatches:str regex:@"window.alert(\\\"로그인 하세요"] > 0) {
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
    }

	// <div id="board-content">
	// <form action="/cafe.php" method=get name=frmEdit >
	switch ([m_nMode intValue]) {
		case CAFE_TYPE_NORMAL:
			if ([Utils numberOfMatches:str regex:@"<tr  id=\"board_list_title"]) {
				m_nItemMode = [NSNumber numberWithInt:NormalItems];
				[self getNormaltems:str];
			} else {
				m_nItemMode = [NSNumber numberWithInt:PictureItems];
				[self getPictureItems:str];
			}
			break;
        case CAFE_TYPE_NOTICE:
            [self getPNoticeItems:str];
            break;
        case CAFE_TYPE_CENTER:
        case CAFE_TYPE_APPLY:
			[self getCenterItems:str];
			break;
        case CAFE_TYPE_ING:
            [self getIngItems:str];
            break;
	}
}

- (void)getNormaltems:(NSString *)str
{
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(id=\\\"board_list_line\\\").*?(</tr>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
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
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<td class=\"subject).*?(</a>)"];
		strSubject = [Utils replaceStringHtmlTag:strSubject];
        strSubject = [strSubject stringByConvertingHTMLToPlainText];
		[currItem setValue:strSubject forKey:@"subject"];
		
		// find link
		// <a href="/cafe.php?sort=45&sub_sort=&page=&startpage=&keyfield=&key_bs=&p1=menbal&p2=&p3=&number=1163433&mode=view">
		NSString *strLink = [Utils findStringRegex:str2 regex:@"(?<=<a href=\\\").*?(?=\\\")"];
        NSString *commId = @"";
        NSString *boardId = @"";
        NSString *boardNo = @"";
		if (isPNotice) {
            boardId = [Utils findStringRegex:strLink regex:@"(?<=bo_table=).*?(?=&)"];
            boardNo = [Utils findStringRegex:strLink regex:@"(?<=&wr_id=).*?(?=$)"];
        } else {
            commId = [Utils findStringRegex:strLink regex:@"(?<=p1=).*?(?=&)"];
            boardId = [Utils findStringRegex:strLink regex:@"(?<=sort=).*?(?=&)"];
            boardNo = [Utils findStringRegex:strLink regex:@"(?<=&number=).*?(?=&)"];
        }
        [currItem setValue:commId forKey:@"commId"];
        [currItem setValue:boardId forKey:@"boardId"];
        [currItem setValue:boardNo forKey:@"boardNo"];

        strSubject = [Utils findStringRegex:str2 regex:@"(<td class=\"subject).*?(</td>)"];
        strSubject = [Utils findStringRegex:strSubject regex:@"(</a>).*?(</td>)"];
		NSString *strComment = [Utils findStringRegex:strSubject regex:@"(?<=\\[).*?(?=\\])"];
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
		NSString *strDate = [Utils findStringRegex:str2 regex:@"(<td class=\"date).*?(</td>)"];
		strDate = [Utils replaceStringHtmlTag:strDate];
		[currItem setValue:strDate forKey:@"date"];
		
		// Hit
		NSString *strHit = [Utils findStringRegex:str2 regex:@"(<td class=\"hit).*?(</td>)"];
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
        strSubject = [strSubject stringByConvertingHTMLToPlainText];
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

/*
 getPNoticeItems : 법인공지
 */
- (void)getPNoticeItems:(NSString *)str
{
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<tr class=).*?(</tr>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
	NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
	NSMutableDictionary *currItem;
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *str2 = [str substringWithRange:matchRange];
		BOOL isNotice = FALSE;
		currItem = [[NSMutableDictionary alloc] init];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
		// find [공지]
		if ([Utils numberOfMatches:str2 regex:@"<tr class=\\\"bo_notice"] > 0) {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isNotice"];
			NSLog(@"isNotice");
			isNotice = TRUE;
		} else {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
		}
		
        // comment 삭제
        str2 = [Utils replaceStringRegex:str2 regex:@"(<!--).*?(-->)" replace:@""];
        
		// subject
		NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<td class=\\\"td_subject).*?(</a>)"];

        // find link
        NSString *strLink = [Utils findStringRegex:strSubject regex:@"(?<=<a href=\\\").*?(?=\\\")"];
        // <a href="http://www.gongdong.or.kr/index.php?mid=ing&amp;page=2&amp;document_srl=326671">
        NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=wr_id=).*?(?=&)"];
        [currItem setValue:boardNo forKey:@"boardNo"];

        NSString *strComment = [Utils findStringRegex:strSubject regex:@"(?<=<span class=\\\"cnt_cmt\\\">).*?(?=</span>)"];
        [currItem setValue:strComment forKey:@"comment"];
        
        strSubject = [Utils replaceStringRegex:strSubject regex:@"(<span class=\\\"sound).*?(</span>)" replace:@""];
		strSubject = [Utils replaceStringHtmlTag:strSubject];
        strSubject = [strSubject stringByConvertingHTMLToPlainText];
		[currItem setValue:strSubject forKey:@"subject"];
		
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
		NSString *strDate = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_date\\\">).*?(?=</td>)"];
		//		strDate = [Utils replaceStringHtmlTag:strDate];
		[currItem setValue:strDate forKey:@"date"];
		
		// Hit
		NSString *strHit = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_num\\\">).*?(?=</td>)"];
//		strHit = [Utils replaceStringHtmlTag:strHit];
		[currItem setValue:strHit forKey:@"hit"];
		
		[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
		
		[m_arrayItems addObject:currItem];
	}
	
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

/*
 getCenterItems : 소통&참여 게시판
 */
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
        if ([Utils numberOfMatches:str2 regex:@"<tr class=\\\"bo_notice"] > 0) {
            [currItem setValue:[NSNumber numberWithInt:1] forKey:@"isNotice"];
            NSLog(@"isNotice");
            isNotice = TRUE;
        } else {
            [currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
        }
        
        // comment 삭제
        str2 = [Utils replaceStringRegex:str2 regex:@"(<!--).*?(-->)" replace:@""];
        if ([m_nMode intValue] == CAFE_TYPE_APPLY) {
            str2 = [Utils replaceStringRegex:str2 regex:@"(<a href=).*?(class=\\\"bo_cate_link\\\">.*?</a>)" replace:@""];
        }
        
        // subject
        NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<td class=\\\"td_subject).*?(</a>)"];
        
        // find link
        NSString *strLink = [Utils findStringRegex:strSubject regex:@"(?<=<a href=\\\").*?(?=\\\")"];
        // <a href="http://www.gongdong.or.kr/index.php?mid=ing&amp;page=2&amp;document_srl=326671">
        NSString *boardNo = [Utils findStringRegex:strLink regex:@"(?<=wr_id=).*?(?=&)"];
        [currItem setValue:boardNo forKey:@"boardNo"];
        
        NSString *strComment = [Utils findStringRegex:strSubject regex:@"(?<=<span class=\\\"cnt_cmt\\\">).*?(?=</span>)"];
        [currItem setValue:strComment forKey:@"comment"];
        
        if ([m_nMode intValue] == CAFE_TYPE_APPLY) {
            if ([Utils numberOfMatches:str2 regex:@"<div class=\\\"edu_con\\\">"] > 0) {
                strStatus = @"[접수중]";
            } else {
                strStatus = @"[신청마감]";
            }
        } else {
            if ([Utils numberOfMatches:str2 regex:@"recruitment2.png"] > 0 || [Utils numberOfMatches:str2 regex:@"recruitment.gif"] > 0) {
                strStatus = @"[모집중]";
            } else if ([Utils numberOfMatches:str2 regex:@"rcrit_end.gif"] > 0) {
                strStatus = @"[완료]";
            } else {
                strStatus = @"";
            }
        }
        
        strSubject = [Utils replaceStringRegex:strSubject regex:@"(<span class=\\\"sound).*?(개</span>)" replace:@""];
        strSubject = [Utils replaceStringHtmlTag:strSubject];
        if ([m_nMode intValue] == CAFE_TYPE_APPLY) {
            strSubject = [NSString stringWithFormat:@"%@ %@", strStatus, strSubject];
        }
        if ([strStatus length] > 0) {
            strSubject = [NSString stringWithFormat:@"%@ %@", strStatus, strSubject];
        }
        strSubject = [strSubject stringByConvertingHTMLToPlainText];
        [currItem setValue:strSubject forKey:@"subject"];
        
        // isNew
        [currItem setValue:@"0" forKey:@"isNew"];
        
        if ([m_nMode intValue] == CAFE_TYPE_APPLY) {
            // name
            NSString *strName = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_name sv_use\\\">).*?(?=</td>)"];
            strName = [Utils replaceStringHtmlTag:strName];
            [currItem setValue:strName forKey:@"name"];
            
            // date
            NSString *strDate = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_name \\\">).*?(?=</td>)"];
            //        strDate = [Utils replaceStringHtmlTag:strDate];
            [currItem setValue:strDate forKey:@"date"];
            
            // Hit
            NSString *strHit = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_num\\\">).*?(?=</td>)"];
            //        strHit = [Utils replaceStringHtmlTag:strHit];
            [currItem setValue:strHit forKey:@"hit"];
        } else {
            // name
            NSString *strName = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_name sv_use\\\">).*?(?=</td>)"];
            strName = [Utils replaceStringHtmlTag:strName];
            [currItem setValue:strName forKey:@"name"];
            
            // date
            NSString *strDate = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_date\\\">).*?(?=</td>)"];
            //        strDate = [Utils replaceStringHtmlTag:strDate];
            [currItem setValue:strDate forKey:@"date"];
            
            // Hit
            NSString *strHit = [Utils findStringRegex:str2 regex:@"(?<=<td class=\\\"td_num\\\">).*?(?=</td>)"];
            //        strHit = [Utils replaceStringHtmlTag:strHit];
            [currItem setValue:strHit forKey:@"hit"];
        }
            
        [currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
        
        [m_arrayItems addObject:currItem];
    }
    
    [target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

- (void)getIngItems:(NSString *)str
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<ul class=\\\"gall_con).*?(</ul>)" options:NSRegularExpressionDotMatchesLineSeparators|NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
    NSMutableDictionary *currItem;
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSString *str2 = [str substringWithRange:matchRange];
        currItem = [[NSMutableDictionary alloc] init];
        
        [currItem setValue:[NSNumber numberWithInt:0] forKey:@"isPNotice"];
        [currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNotice"];
        
        // piclink
        NSString *strPicLink = [Utils findStringRegex:str2 regex:@"(?<=<img src=\\\")(.|\\n)*?(?=\\\")"];
        [currItem setValue:strPicLink forKey:@"piclink"];

        // subject
        NSString *strSubject = [Utils findStringRegex:str2 regex:@"(<li class=\\\"gall_text_href).*?(</a>)"];
        
        // find link
        NSString *boardNo = [Utils findStringRegex:strSubject regex:@"(?<=wr_id=).*?(?=[&|\\\"])"];
        [currItem setValue:boardNo forKey:@"boardNo"];
        
        NSString *strComment = [Utils findStringRegex:strSubject regex:@"(?<=<span class=\\\"cnt_cmt\\\">).*?(?=</span>)"];
        [currItem setValue:strComment forKey:@"comment"];
        
        strSubject = [Utils replaceStringRegex:strSubject regex:@"(<span class=\\\"sound).*?(</span>)" replace:@""];
        strSubject = [Utils replaceStringHtmlTag:strSubject];
        strSubject = [strSubject stringByConvertingHTMLToPlainText];
        [currItem setValue:strSubject forKey:@"subject"];
        
        // isNew
        [currItem setValue:@"0" forKey:@"isNew"];
        
        [currItem setValue:@"" forKey:@"name"];
        [currItem setValue:@"" forKey:@"id"];
        
        [currItem setValue:@"" forKey:@"date"];
        
        [currItem setValue:@"" forKey:@"hit"];
        
        [currItem setValue:[NSNumber numberWithInt:0] forKey:@"isRe"];
        
        [m_arrayItems addObject:currItem];
    }

	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

@end
