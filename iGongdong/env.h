//
//  env.h
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#ifndef iMoojigae_env_h
#define iMoojigae_env_h

#import <UIKit/UIKit.h>

//#define TEST_MODE

#ifdef DEBUG
#define NSLog( s, ... ) NSLog(@"%s(%d) %@", __FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__])
#else
#define NSLog( s, ... )
#endif

#define CAFE_SERVER	@"http://cafe.gongdong.or.kr"
#define WWW_SERVER @"http://www.gongdong.or.kr"
#define kSampleAdUnitID @"ca-app-pub-9032980304073628/5080394398"
//#define AdPubID @"a1513842aba33a7"

#define CommentWrite	1
#define CommentModify	2
#define CommentReply	3

#define ArticleWrite	1
#define ArticleModify	2

#define NormalItems		1
#define PictureItems	2

#define RESULT_OK		0
#define RESULT_AUTH_FAIL	1
#define RESULT_LOGIN_FAIL	2

#define CAFE_TYPE_NORMAL	0
#define CAFE_TYPE_LINK		2
#define CAFE_TYPE_TITLE		1
#define CAFE_TYPE_CENTER	3
#define CAFE_TYPE_ING		4
#define CAFE_TYPE_TEACHER	5

#define COMMUNITY		1
#define CENTER			2

#define BOARD_NORMAL	1
#define BOARD_CENTER	2
#define BOARD_ING		3
#define BOARD_TEACHER	4

#define CAFE_TYPE_CENTER_STR	@"3"
#define CAFE_TYPE_ING_STR		@"4"
#define CAFE_TYPE_TEACHER_STR	@"5"

#endif
