//
//  ItemsData.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 16..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ItemsData : NSObject
@property (nonatomic, strong) NSString *m_strCommNo;
@property (nonatomic, strong) NSString *m_strLink;
@property (strong, nonatomic) NSMutableArray *m_arrayItems;
@property (strong, nonatomic) NSNumber *m_nMode;
@property id target;
@property SEL selector;

- (void)fetchItems:(int) nPage;

@end
