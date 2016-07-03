//
//  ArticleView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@import GoogleMobileAds;

@interface ArticleView : UIViewController <UIWebViewDelegate, UITableViewDelegate, UITableViewDataSource, UITabBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tbView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *buttonArticleDelete;
@property (strong, nonatomic) NSNumber *m_isPNotice;
@property (strong, nonatomic) NSString *m_strTitle;
@property (strong, nonatomic) NSString *m_strDate;
@property (strong, nonatomic) NSString *m_strName;
@property (strong, nonatomic) NSString *m_strLink;
@property id target;
@property SEL selector;
@end
