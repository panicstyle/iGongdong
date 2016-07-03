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
@property (nonatomic, strong) id target;
@property SEL selector;

@end
