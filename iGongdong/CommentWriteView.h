//
//  CommentWriteView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentWriteView : UIViewController
@property (nonatomic, weak) IBOutlet UITextView *m_textView;
@property (nonatomic, strong) NSNumber *m_nModify;
@property (nonatomic, strong) NSNumber *m_nMode;
@property (nonatomic, strong) NSNumber *m_isPNotice;
@property (nonatomic, strong) NSString *m_strCommNo;
@property (nonatomic, strong) NSString *m_strBoardNo;
@property (nonatomic, strong) NSString *m_strArticleNo;
@property (nonatomic, strong) NSString *m_strCommentNo;
@property (nonatomic, strong) NSString *m_strComment;
@property id target;
@property SEL selector;

- (CommentWriteView *) initWithBoard:(NSString *)strBoardNo Article:(NSString *)strArticleNo Comment:(NSString *)strCommentNo;
- (void)setDelegate:(id)aTarget selector:(SEL)aSelector;

@end
