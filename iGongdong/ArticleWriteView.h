//
//  ArticleWriteView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "env.h"

@interface ArticleWriteView : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tbView;
@property (nonatomic, strong) NSNumber *m_nMode;
@property (nonatomic, strong) NSString *m_strCommNo;
@property (nonatomic, strong) NSString *m_strBoardNo;
@property (nonatomic, strong) NSString *m_strArticleNo;
@property (nonatomic, strong) NSString *m_strTitle;
@property (nonatomic, strong) NSString *m_strContent;
@property id target;
@property SEL selector;
@end
