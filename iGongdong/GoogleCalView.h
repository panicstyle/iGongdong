//
//  GoogleCalView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@import GoogleMobileAds;

@interface GoogleCalView : UIViewController <UIWebViewDelegate>

@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;
@property (strong, nonatomic) NSString *m_strLink;
@end