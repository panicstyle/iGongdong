//
//  BoardData.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 16..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BoardData : NSObject
@property (nonatomic, strong) NSString *m_strCommId;
@property (nonatomic, strong) NSNumber *m_nMode;		// 1 : 커뮤니티, 2 : 사무국게시판
@property (strong, nonatomic) NSMutableArray *m_arrayItems;
@property id target;
@property SEL selector;

- (void)fetchItems;
@end
