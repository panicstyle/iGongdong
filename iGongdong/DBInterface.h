//
//  DBInterface.h
//  iMoojigae
//
//  Created by dykim on 2018. 6. 3..
//  Copyright © 2018년 dykim. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DBInterface : NSObject
-(int)searchWithCommId:(NSString *)commId BoardId:(NSString *)boardId BoardNo:(NSString *)boardNo;
-(void)insertWithCommId:(NSString *)commId BoardId:(NSString *)boardId BoardNo:(NSString *)boardNo;
-(void)delete;
@end
