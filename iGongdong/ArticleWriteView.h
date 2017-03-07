//
//  ArticleWriteView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "env.h"

@interface ArticleWriteView : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, weak) IBOutlet UITextField *viewTitle;
@property (nonatomic, weak) IBOutlet UITextView *viewContent;
@property (nonatomic, weak) IBOutlet UIImageView *viewImage0;
@property (nonatomic, weak) IBOutlet UIImageView *viewImage1;
@property (nonatomic, weak) IBOutlet UIImageView *viewImage2;
@property (nonatomic, weak) IBOutlet UIImageView *viewImage3;
@property (nonatomic, weak) IBOutlet UIImageView *viewImage4;

@property (nonatomic, strong) NSNumber *m_nModify;
@property (nonatomic, strong) NSNumber *m_nMode;
@property (nonatomic, strong) NSString *m_strCommId;
@property (nonatomic, strong) NSString *m_strBoardId;
@property (nonatomic, strong) NSString *m_strBoardNo;
@property (nonatomic, strong) NSString *m_strTitle;
@property (nonatomic, strong) NSString *m_strContent;
@property id target;
@property SEL selector;
@end
