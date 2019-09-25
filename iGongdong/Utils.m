//
//  Utils.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 9..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (int)numberOfMatches:(NSString *)content regex:(NSString *)strRegex
{
	if (content == Nil) {
		return 0;
	}
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strRegex options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	return (int)[regex numberOfMatchesInString:content options:0 range:NSMakeRange(0, [content length])];
}

+ (NSString *)findStringWith:(NSString *)content from:(NSString *)fromString to:(NSString *)toString
{
	
	NSRange find1 = [content rangeOfString:fromString];
	if (find1.location == NSNotFound) {
		NSLog(@"contents start NotFound [%@]", fromString);
		return @"";
	}
	
	NSRange find1_1 = {find1.location, [content length] - find1.location};
	
	NSRange find2 = [content rangeOfString:toString options:0 range:find1_1];
	if (find2.location == NSNotFound) {
		NSLog(@"contents start NotFound [%@]", fromString);
		return @"";
	}
	
	NSRange find3 = {find1.location, find2.location - find1.location + find2.length};
	
	NSString *contentString = [content substringWithRange:find3];
	
	return contentString;
}

+ (NSString *)findStringRegex:(NSString *)content regex:(NSString *)strRegex
{
	if (content == Nil) {
		return @"";
	}
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strRegex options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:content options:0 range:NSMakeRange(0, [content length])];
	
	NSString *strResult;
	if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
		strResult = [content substringWithRange:rangeOfFirstMatch];
	} else {
		strResult = @"";
	}
	
	return strResult;
}

+ (NSString *)findStringRegex:(NSString *)content regex:(NSString *)strRegex index:(int)nIndex
{
	if (content == Nil) {
		return @"";
	}
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strRegex options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSArray *matches = [regex matchesInString:content options:0 range:NSMakeRange(0, [content length])];
	
	if ([matches count] <= nIndex) {
		return @"";
	}
	
	NSTextCheckingResult *match = matches[nIndex];
	NSRange range = [match range];
	
	NSString *strResult;
	if (!NSEqualRanges(range, NSMakeRange(NSNotFound, 0))) {
		strResult = [content substringWithRange:range];
	} else {
		strResult = @"";
	}
	
	return strResult;
}

+ (NSString *)getMatchWithRegex:(NSString *)content regex:(NSString *)strRegex
{
	if (content == Nil) {
		return @"";
	}
	
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strRegex options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:content options:0 range:NSMakeRange(0, [content length])];
	
	NSString *strResult;
	if (!NSEqualRanges(rangeOfFirstMatch, NSMakeRange(NSNotFound, 0))) {
		strResult = [content substringWithRange:rangeOfFirstMatch];
	} else {
		strResult = @"";
	}
	
	return strResult;
	
	
}


+ (NSString *)replaceStringRegex:(NSString *)content regex:(NSString *)strRegex replace:(NSString *)strReplace
{
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:strRegex options:NSRegularExpressionDotMatchesLineSeparators error:&error];
	NSString *strResult = [regex stringByReplacingMatchesInString:content options:0 range:NSMakeRange(0, [content length]) withTemplate:strReplace];
	
	return strResult;
}

+ (NSString *)replaceStringHtmlTag:(NSString *)content
{
	NSString *dest;
	dest = [NSString stringWithString:content];
	dest = [dest stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	dest = [dest stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	dest = [dest stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
	dest = [dest stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
	dest = [dest stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
	dest = [self replaceStringRegex:dest regex:@"(<b>\\[)\\d+(\\]</b>)" replace:@""];
	dest = [self replaceStringRegex:dest regex:@"(<!--).*?(-->)" replace:@""];
	dest = [self replaceStringRegex:dest regex:@"(<style).*?(/style>)" replace:@""];
	dest = [self replaceStringRegex:dest regex:@"(<img).*?(>)" replace:@""];
	dest = [self replaceStringRegex:dest regex:@"(<font).*?(>)" replace:@""];
	dest = [self replaceStringRegex:dest regex:@"(<).*?(>)" replace:@""];
	
	dest = [dest stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
	dest = [dest stringByReplacingOccurrencesOfString:@"&lt;" withString:@""];
	dest = [dest stringByReplacingOccurrencesOfString:@"&gt;" withString:@""];
	dest = [dest stringByReplacingOccurrencesOfString:@"&amp;" withString:@""];
	dest = [dest stringByReplacingOccurrencesOfString:@"&quot;" withString:@""];
	dest = [dest stringByReplacingOccurrencesOfString:@"&apos;" withString:@""];
	
	dest = [dest stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	return dest;
}

+ (NSString *)makeEditableContent:(NSString *)content
{
    NSString *dest;
    dest = [NSString stringWithString:content];
    dest = [dest stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    dest = [dest stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    dest = [dest stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    dest = [dest stringByReplacingOccurrencesOfString:@"<br/>" withString:@"\n"];
    dest = [dest stringByReplacingOccurrencesOfString:@"<br />" withString:@"\n"];
    dest = [dest stringByReplacingOccurrencesOfString:@"</div>" withString:@"\n"];
    dest = [dest stringByReplacingOccurrencesOfString:@"</p>" withString:@"\n"];
    dest = [self replaceStringRegex:dest regex:@"(<b>\\[)\\d+(\\]</b>)" replace:@""];
    dest = [self replaceStringRegex:dest regex:@"(<!--).*?(-->)" replace:@""];
    dest = [self replaceStringRegex:dest regex:@"(<style).*?(/style>)" replace:@""];
    dest = [self replaceStringRegex:dest regex:@"(<img).*?(>)" replace:@""];
    dest = [self replaceStringRegex:dest regex:@"(<font).*?(>)" replace:@""];
    dest = [self replaceStringRegex:dest regex:@"(<).*?(>)" replace:@""];
    
    dest = [dest stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
    dest = [dest stringByReplacingOccurrencesOfString:@"&lt;" withString:@""];
    dest = [dest stringByReplacingOccurrencesOfString:@"&gt;" withString:@""];
    dest = [dest stringByReplacingOccurrencesOfString:@"&amp;" withString:@""];
    dest = [dest stringByReplacingOccurrencesOfString:@"&quot;" withString:@""];
    dest = [dest stringByReplacingOccurrencesOfString:@"&apos;" withString:@""];
    
    dest = [dest stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return dest;
}

+ (NSString *)removeSpan:(NSString *)content
{
	NSString *dest;
	dest = [NSString stringWithString:content];
	dest = [self replaceStringRegex:dest regex:@"(<span).*?(</span>)" replace:@""];
	
	dest = [dest stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
	return dest;
}

+ (NSString *)replaceSpecialString:(NSString *)content
{
	NSString *dest;
	dest = [NSString stringWithString:content];
	dest = [dest stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
	dest = [dest stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
	dest = [dest stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
	dest = [dest stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	dest = [dest stringByReplacingOccurrencesOfString:@"&quot;" withString:@"\""];
	dest = [dest stringByReplacingOccurrencesOfString:@"&apos;" withString:@"'"];
	
	return dest;
}

+ (NSString *)replaceOnlyHtmlTag:(NSString *)content
{
	NSString *dest;
	dest = [self replaceStringRegex:content regex:@"(<).*?(>)" replace:@""];
	return dest;
}

@end
