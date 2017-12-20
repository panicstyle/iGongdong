//
//  WebLinkView.h
//  iGongdong
//
//  Created by dykim on 2016. 7. 24..
//  Copyright © 2016년 dykim. All rights reserved.
//
#import <UIKit/UIKit.h>

@import GoogleMobileAds;

@interface WebLinkView : UIViewController <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *mainView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (strong, nonatomic) NSString *m_strLink;
@property (strong, nonatomic) NSNumber *m_nFileType;

@property (nonatomic, retain) UIImageView *m_imageView;

@end
