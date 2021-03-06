//
//  BoardData.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 16..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "BoardData.h"
#import "env.h"
#import "Utils.h"

@interface BoardData () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
}
@end

@implementation BoardData
@synthesize m_nMode;
@synthesize m_strCommId;
@synthesize m_arrayItems;
@synthesize target;
@synthesize selector;

- (void)fetchItems
{
	
	m_arrayItems = [[NSMutableArray alloc] init];
	
	// m_nMode 가 CENTER 일 경우 커뮤니티가 아닌 공동육아 홈페이지 관련 게시판을 표시한다.
	if ([m_nMode intValue] == CENTER) {
	
		NSArray *ingMain = @[
                             @"B211", @"공지사항", @CAFE_TYPE_NOTICE,
                             @"B221", @"법인일정", @CAFE_TYPE_CAL,
							 @"B231", @"공동육아ing", @CAFE_TYPE_ING,
							 @"B271", @"무엇이든 물어보세요", @CAFE_TYPE_CENTER,
                             @"B281", @"알리고싶어요", @CAFE_TYPE_CENTER,
							 @"B251", @"교사모집/구직", @CAFE_TYPE_CENTER,
							 @"B261", @"조합원모집", @CAFE_TYPE_CENTER,
							 @"B301", @"터전소식", @CAFE_TYPE_CENTER,
							   ];

		NSArray *eduMain = @[
                             @"교사교육", @"교사교육", @CAFE_TYPE_APPLY,
                             @"부모교육", @"부모교육", @CAFE_TYPE_APPLY,
                             @"운영진교육", @"운영진교육", @CAFE_TYPE_APPLY,
                             @"시민교육", @"시민교육", @CAFE_TYPE_APPLY,
							 ];

		
		NSArray *tmp;
		if ([m_strCommId isEqualToString:@"ing"]) {
			tmp = ingMain;
		} else if ([m_strCommId isEqualToString:@"edu"]) {
			tmp = eduMain;
		}
		
		NSMutableDictionary *currItem;
		int i;
		for (i = 0; i < tmp.count; i+=3) {
			currItem= [[NSMutableDictionary alloc] init];
			[currItem setValue:tmp[i] forKey:@"boardId"];
			[currItem setValue:tmp[i + 1] forKey:@"boardName"];
			[currItem setValue:tmp[i + 2] forKey:@"type"];
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNew"];
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isCal"];
			[m_arrayItems addObject:currItem];
		}
		[target performSelector:selector withObject:nil afterDelay:0];
	} else {
		NSString *url = [NSString stringWithFormat:@"%@/cafe.php?code=%@", CAFE_SERVER, m_strCommId];

		m_receiveData = [[NSMutableData alloc] init];
		m_connection = [[NSURLConnection alloc]
				initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	//NSLog(@"didReceiveData");
	if (m_connection) [m_receiveData appendData:data];
	//NSLog(@"didReceiveData receiveData=[%d], data=[%d]", [returnData length], [data length]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	NSString *str = [[NSString alloc] initWithData:m_receiveData
										  encoding:NSUTF8StringEncoding];
	// <ul id="cafe_sub_memu">
	// </ul>
	
	NSMutableDictionary *currItem;
	
	NSError *error = NULL;
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<li id=\"cafe_sub_menu).*?(</li>)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
//		<li id="cafe_sub_menu_board"><a href="cafe.php?p1=menbal&sort=45" >가입 문의</a><IMG SRC="images/new_s.gif" WIDTH="8" HEIGHT="7" ALIGN=ABSMIDDLE hspace=3></li>
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *matchstr = [str substringWithRange:matchRange];
		
		currItem = [[NSMutableDictionary alloc] init];
		
		// type check
		// cafe_sub_menu_board, cafe_sub_menu_link, cafe_sub_menu_title
		if ([matchstr rangeOfString:@"cafe_sub_menu_line"].location != NSNotFound) {
			continue;
		} else if ([matchstr rangeOfString:@"cafe_sub_menu_title"].location != NSNotFound) {
			[currItem setValue:[NSNumber numberWithInt:CAFE_TYPE_TITLE] forKey:@"type"];
		} else if ([matchstr rangeOfString:@"cafe_sub_menu_link"].location != NSNotFound) {
//			[currItem setValue:[NSNumber numberWithInt:CAFE_TYPE_LINK] forKey:@"type"];
			continue;
		} else {
			[currItem setValue:[NSNumber numberWithInt:CAFE_TYPE_NORMAL] forKey:@"type"];
		}
		
		// link
		NSString *link = [Utils findStringRegex:matchstr regex:@"(?<=<a href=\\\").*?(?=\\\")"];
		NSString *boardId = [Utils findStringRegex:link regex:@"(?<=&sort=).*?(?=$)"];
		[currItem setValue:boardId forKey:@"boardId"];
		
		// title에서 < ... > 없애기
		NSString *title = [Utils replaceOnlyHtmlTag:matchstr];
		[currItem setValue:title forKey:@"boardName"];
		
		
		// isNew images/new_s.gif 찾기
		if ([matchstr rangeOfString:@"images/new_s.gif"].location != NSNotFound) {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isNew"];
		} else {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isNew"];
		}
		
		// link가 sort=cal가 포함되어 있으면 캘런더로 표시
		if ([link rangeOfString:@"sort=cal"].location != NSNotFound) {
			[currItem setValue:[NSNumber numberWithInt:1] forKey:@"isCal"];
		} else {
			[currItem setValue:[NSNumber numberWithInt:0] forKey:@"isCal"];
		}
		
		[m_arrayItems addObject:currItem];
	}
	[target performSelector:selector withObject:nil afterDelay:0];
}

@end
