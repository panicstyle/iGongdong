//
//  ArticleData.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 13..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ArticleData : NSObject
@property (strong, nonatomic) NSString *m_strHtml;
@property (strong, nonatomic) NSString *m_strTitle;
@property (strong, nonatomic) NSString *m_strName;
@property (strong, nonatomic) NSString *m_strDate;
@property (strong, nonatomic) NSString *m_strHit;
@property (strong, nonatomic) NSString *m_strContent;
@property (strong, nonatomic) NSString *m_strEditableContent;
@property (strong, nonatomic) NSNumber *m_isPNotice;
@property (strong, nonatomic) NSString *m_strLink;
@property (strong, nonatomic) NSNumber *m_nMode;
@property (strong, nonatomic) NSMutableArray *m_arrayItems;
@property id target;
@property SEL selector;

- (void)fetchItems;
- (bool)DeleteArticle:(NSString *)strCommNo boardNo:(NSString *)strBoardNo articleNo:(NSString *)strArticleNo;
- (bool)DeleteComment:(NSString *)strCommNo boardNo:(NSString *)strBoardNo articleNo:(NSString *)strArticleNo commentNo:(NSString *)strCommentNo isPNotice:(int)m_isPNotice;

@end
