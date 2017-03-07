//
//  AboutView.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import "env.h"

@interface AboutView : UIViewController <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *btnDonation;

+ (id) sharedManager;

@end
