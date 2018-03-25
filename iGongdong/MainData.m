//
//  MainData.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 16..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "MainData.h"
#import "env.h"
#import "Utils.h"

@interface MainData () {
	NSMutableData *m_receiveData;
	NSURLConnection *m_connection;
}
@end

@implementation MainData
@synthesize m_arrayItems;
@synthesize m_arrayMain;
@synthesize target;
@synthesize selector;

- (void)fetchItems
{
	m_arrayMain = [[NSMutableArray alloc] init];
    int i;
    NSMutableDictionary *currItem;
/*
	NSArray *arrayMain = @[
						   @"edu", @"교육사업",
						   @"ing", @"소통과참여",
					  ];

	for (i = 0; i < arrayMain.count; i+=2) {
		currItem= [[NSMutableDictionary alloc] init];
		[currItem setValue:arrayMain[i] forKey:@"code"];
		[currItem setValue:arrayMain[i + 1] forKey:@"title"];
		[m_arrayMain addObject:currItem];
	}
*/
	m_arrayItems = [[NSMutableArray alloc] init];

#ifdef TEST_MODE
    NSArray *arrayComm = @[
                           @"urinori", @"우리노리",
                           ];
    for (i = 0; i < arrayComm.count; i+=2) {
        currItem= [[NSMutableDictionary alloc] init];
        [currItem setValue:arrayComm[i] forKey:@"code"];
        [currItem setValue:arrayComm[i + 1] forKey:@"title"];
        [m_arrayItems addObject:currItem];
    }
#endif
    
	NSString *url = [NSString stringWithFormat:@"%@/", WWW_SERVER];
	m_receiveData = [[NSMutableData alloc] init];
	m_connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]] delegate:self];
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
	
	// <select name="community
	// </select>
	NSLog(@"str = %@", str);
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(<select name=\"select_community).*?(</select>)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:str options:0 range:NSMakeRange(0, [str length])];
	NSString *selectStr;
	if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
		selectStr = [str substringWithRange:rangeOfFirstMatch];
	} else {
		selectStr = @"";
	}
	
	regex = [NSRegularExpression regularExpressionWithPattern:@"(<option value=).*?(</option>)" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	//    NSMutableArray *titleArray = [[NSMutableArray alloc] init];
	NSArray *matches = [regex matchesInString:selectStr options:0 range:NSMakeRange(0, [selectStr length])];
	
	NSMutableDictionary *currItem;
	
	for (NSTextCheckingResult *match in matches) {
		NSRange matchRange = [match range];
		NSString *matchstr = [selectStr substringWithRange:matchRange];
		
		currItem = [[NSMutableDictionary alloc] init];
		
		// code
		regex = [NSRegularExpression regularExpressionWithPattern:@"(?<=value=\\\").*?(?=\\\")" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		rangeOfFirstMatch = [regex rangeOfFirstMatchInString:matchstr options:0 range:NSMakeRange(0, [matchstr length])];
		NSString *code;
		if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
			code = [matchstr substringWithRange:rangeOfFirstMatch];
		} else {
			code = @"";
		}
        
        if ([code isEqualToString:@""]) continue;
		
		// title
		regex = [NSRegularExpression regularExpressionWithPattern:@"<.*?>" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
		NSString *title = [regex stringByReplacingMatchesInString:matchstr options:0 range:NSMakeRange(0, [matchstr length]) withTemplate:@""];
		title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		
		[currItem setValue:title forKey:@"title"];
		[currItem setValue:code forKey:@"code"];
		// code is menbal
		
		[m_arrayItems addObject:currItem];
	}
	[target performSelector:selector withObject:nil afterDelay:0];
}

@end
