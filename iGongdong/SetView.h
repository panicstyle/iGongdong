//
//  SetViewController.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SetView : UIViewController
@property (nonatomic, weak) IBOutlet UITextField *idField;
@property (nonatomic, weak) IBOutlet UITextField *pwdField;
@property (nonatomic, weak) IBOutlet UISwitch *switchPush;
@property (nonatomic, weak) IBOutlet UISwitch *switchNotice;
@property (nonatomic, weak) IBOutlet UILabel *labelId;
@property (nonatomic, weak) IBOutlet UILabel *labelPwd;
@property (nonatomic, weak) IBOutlet UILabel *labelNoticeSet;
@property (nonatomic, weak) IBOutlet UILabel *labelNotice;
@property (nonatomic, weak) IBOutlet UILabel *labelCommunity;
@property (nonatomic, strong) id target;
@property SEL selector;

@end
