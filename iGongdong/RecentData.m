//
//  RecentData.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 16..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "RecentData.h"
#import "env.h"
#import "LoginToService.h"

@interface RecentData () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
	BOOL m_isConn;
	BOOL m_isLogin;
	LoginToService *m_login;
}
@end

@implementation RecentData

@synthesize m_strCommNo;
@synthesize m_arrayItems;
@synthesize target;
@synthesize selector;

- (void)fetchItems
{
	m_arrayItems = [[NSMutableArray alloc] init];

	NSString *url;
	
	if ([m_strCommNo isEqualToString:@"maul"]) {
		url = @"http://www.moojigae.or.kr/Mboard-recent.do?part=index&rid=50&pid=mvTopic,mvTopic10Year,mvTopicGoBackHome,mvEduBasicRight,mvGongi,mvGongDong,mvGongDongFacility,mvGongDongEvent,mvGongDongLocalcommunity,mvDonghowhe,mvDonghowheMoojiageFC,mvPoomASee,mvPoomASeeWantBiz,mvPoomASeeBized,mvEduLove,mvEduVillageSchool,mvEduDream,mvEduSpring,mvEduSpring,mvMarketBoard,mvHorizonIntroduction,mvHorizonLivingStory,mvSecretariatAddress,mvSecretariatOldData,mvMinutes,mvEduResearch,mvBuilding,mvBuildingComm,mvDonationGongi,mvDonationQnA,toHomePageAdmin,mvUpgrade";
	} else if ([m_strCommNo isEqualToString:@"school1"]) {
		url = @"http://www.moojigae.or.kr/Mboard-recent.do?part=index&rid=50&pid=mjGongi,mjFreeBoard,mjTeacher,mjTeachingData,mjJunior,mjParent,mjParentMinutes,mjAmaDiary,mjSchoolFood,mjPhoto,mjData";
	} else {
		url = @"http://www.moojigae.or.kr/Mboard-recent.do?part=index&rid=50&pid=msGongi,msFreeBoard,msOverRainbow,msFreeComment,msTeacher,msSenior,msStudent,ms5Class,msStudentAssociation,msParent,msRepresentative,msMinutes,msPhoto,msData";
	}
	

	NSLog(@"fetchItems");
	m_receiveData = [[NSMutableData alloc] init];
	
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
	[request setURL:[NSURL URLWithString:url]];
	[request setHTTPMethod:@"POST"];
	//        [request addValue:@"http://121.134.211.159/board-list.do" forHTTPHeaderField:@"Referer"];
	[request addValue:@"gzip,deflate,sxdch" forHTTPHeaderField:@"Accept-Encoding"];
	[request addValue:@"ko,en-US;q=0.8,en;q=0.6" forHTTPHeaderField:@"Accept-Language"];
	[request addValue:@"windows-949,utf-8;q=0.7,*;q=0.3" forHTTPHeaderField:@"Accept-Charset"];
	
	NSData *body = [[NSData alloc] initWithData:[@"" dataUsingEncoding:0x80000000 + kCFStringEncodingEUC_KR]];
	
	[request setHTTPBody:body];
	
	m_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	NSLog(@"fetchItems 2");
	m_isConn = TRUE;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	NSLog(@"didReceiveData");
	if (m_isConn) {
		[m_receiveData appendData:data];
		NSLog(@"didReceiveData receiveData=[%lu], data=[%lu]", (unsigned long)[m_receiveData length], (unsigned long)[data length]);
	} else {
		NSLog(@"connect finish");
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	m_isConn = FALSE;
	NSLog(@"ListView receiveData Size = [%lu]", (unsigned long)[m_receiveData length]);
	
	if ([m_receiveData length] < 1800) {
		[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_AUTH_FAIL] afterDelay:0];
	}
	
	NSString *str = [[NSString alloc] initWithData:m_receiveData
										  encoding:0x80000000 + kCFStringEncodingEUC_KR];
	
	// The NSRegularExpression class is currently only available in the Foundation framework of iOS 4
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=<td width=\\\"2\\\").*?(?=<th height=\\\"1\\\")" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSArray *matches = [regex matchesInString:str options:0 range:NSMakeRange(0, [str length])];
	
	NSMutableDictionary *currItem;
	
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *str2 = [str substringWithRange:matchRange];
		NSLog(@"str2=[%@]", str2);
		
		currItem = [[NSMutableDictionary alloc] init];
		// Link
		regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=setMainBody\\(\\'contextTableMainBody\\',\\').*?(?=\\')" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str2 options:0 range:NSMakeRange(0, [str2 length])];
		NSString *link;
		if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
			link = [str2 substringWithRange:rangeOfFirstMatch];
			NSLog(@"link=[%@]", link);
		} else {
			NSLog(@"link line not found");
			link = @"";
		}
		[currItem setValue:[NSString stringWithString:link] forKey:@"link"];
		
		// Subject
		regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=target=_self class=\\\"list\\\">).*?(?=</a>)" options:0 error:&error];
		rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str2 options:0 range:NSMakeRange(0, [str2 length])];
		NSString *subject;
		if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
			subject = [str2 substringWithRange:rangeOfFirstMatch];
			NSLog(@"subject=[%@]", subject);
		} else {
			NSLog(@"subject line not found");
			subject = @"";
		}
		subject = [subject stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
		subject = [subject stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
		subject = [subject stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
		subject = [subject stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
		subject = [subject stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
		[currItem setValue:[NSString stringWithString:subject] forKey:@"subject"];
		
		// writer
		regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=color:royalblue>).*?(?=</font>)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str2 options:0 range:NSMakeRange(0, [str2 length])];
		NSString *writer;
		if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
			writer = [str2 substringWithRange:rangeOfFirstMatch];
			NSLog(@"writer=[%@]", writer);
		} else {
			NSLog(@"writer line not found");
			writer = @"";
		}
		if ([writer length] > 2) {
			writer = [writer substringWithRange:NSMakeRange(1, [writer length] - 2)];
		}
		
		[currItem setValue:[NSString stringWithString:writer] forKey:@"writer"];
		
		// Date
		// The NSRegularExpression class is currently only available in the Foundation framework of iOS 4
		regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=<span class=\\\"board-inlet\\\">).*?(?=</span>)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str2 options:0 range:NSMakeRange(0, [str2 length])];
		NSString *date;
		if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
			date = [str2 substringWithRange:rangeOfFirstMatch];
			NSLog(@"date=[%@]", date);
		} else {
			NSLog(@"date line not found");
			date = @"";
		}
		[currItem setValue:[NSString stringWithString:date] forKey:@"date"];
		
		// Comment
		// The NSRegularExpression class is currently only available in the Foundation framework of iOS 4
		regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=<span class=\\\"board-comment\\\">\\().*?(?=\\)</s)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str2 options:0 range:NSMakeRange(0, [str2 length])];
		NSString *comment;
		if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
			comment = [str2 substringWithRange:rangeOfFirstMatch];
			NSLog(@"comment=[%@]", comment);
		} else {
			NSLog(@"comment line not found");
			comment = @"";
		}
		[currItem setValue:[NSString stringWithString:comment] forKey:@"comment"];
		
		// isNew
		// The NSRegularExpression class is currently only available in the Foundation framework of iOS 4
		regex = [NSRegularExpression regularExpressionWithPattern:@"icon6.GIF" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		NSUInteger numberOfMatches = [regex numberOfMatchesInString:str2 options:0 range:NSMakeRange(0, [str2 length])];
		NSString *isNew;
		if (numberOfMatches > 0) {
			isNew = @"1";
			NSLog(@"isNew");
		} else {
			isNew = @"0";
		}
		[currItem setValue:[NSString stringWithString:isNew] forKey:@"isNew"];
		
		[currItem setValue:[NSNumber numberWithFloat:77.0f] forKey:@"height"];

		
		[m_arrayItems addObject:currItem];
	}
	[target performSelector:selector withObject:[NSNumber numberWithInt:RESULT_OK] afterDelay:0];
}

@end
