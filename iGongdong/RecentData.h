//
//  RecentData.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 16..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecentData : NSObject
@property (nonatomic, strong) NSString *m_strCommNo;
@property (strong, nonatomic) NSMutableArray *m_arrayItems;
@property id target;
@property SEL selector;

- (void)fetchItems;

@end
