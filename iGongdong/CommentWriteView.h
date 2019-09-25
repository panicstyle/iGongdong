//
//  CommentWriteView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CommentWriteView : UIViewController <UINavigationControllerDelegate>
@property (nonatomic, weak) IBOutlet UITextView *m_textView;
@property (nonatomic, strong) NSNumber *m_nModify;
@property (nonatomic, strong) NSNumber *m_nMode;
@property (nonatomic, strong) NSNumber *m_isPNotice;
@property (nonatomic, strong) NSString *m_strCommId;
@property (nonatomic, strong) NSString *m_strBoardId;
@property (nonatomic, strong) NSString *m_strBoardNo;
@property (nonatomic, strong) NSString *m_strCommentNo;
@property (nonatomic, strong) NSString *m_strComment;
@property id target;
@property SEL selector;

@end
