//
//  Utils.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 9..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (int)numberOfMatches:(NSString *)content regex:(NSString *)strRegex;
+ (NSString *)findStringWith:(NSString *)content from:(NSString *)fromString to:(NSString *)toString;
+ (NSString *)findStringRegex:(NSString *)content regex:(NSString *)strRegex;
+ (NSString *)findStringRegex:(NSString *)content regex:(NSString *)strRegex index:(int)nIndex;
+ (NSString *)replaceStringRegex:(NSString *)content regex:(NSString *)strRegex replace:(NSString *)strReplace;
+ (NSString *)removeSpan:(NSString *)content;
+ (NSString *)replaceStringHtmlTag:(NSString *)content;
+ (NSString *)replaceSpecialString:(NSString *)content;
+ (NSString *)replaceOnlyHtmlTag:(NSString *)content;

@end
