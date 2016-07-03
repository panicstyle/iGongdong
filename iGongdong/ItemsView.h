//
//  ItmesView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@import GoogleMobileAds;

@interface ItemsView : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tbView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (strong, nonatomic) NSString *m_strCommNo;
@property (strong, nonatomic) NSString *m_strLink;
@end
