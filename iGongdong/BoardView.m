//
//  ViewController.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "BoardView.h"
#import "env.h"
#import "ItemsView.h"
#import "RecentView.h"
#import "GoogleCalView.h"
#import "BoardData.h"

@interface BoardView ()
{
    NSMutableArray *m_arrayItems;
	BoardData *m_boardData;
}
@end

@implementation BoardView
@synthesize m_strCommId;
@synthesize m_nMode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Replace this ad unit ID with your own ad unit ID.
    self.bannerView.adUnitID = kSampleAdUnitID;
    self.bannerView.rootViewController = self;
    
    GADRequest *request = [GADRequest request];
    // Requests test ads on devices you specify. Your test device ID is printed to the console when
    // an ad request is made. GADBannerView automatically returns test ads when running on a
    // simulator.
    request.testDevices = @[
                            @"2077ef9a63d2b398840261c8221a0c9a"  // Eric's iPod Touch
                            ];
    [self.bannerView loadRequest:request];

	m_arrayItems = [[NSMutableArray alloc] init];

	m_boardData = [[BoardData alloc] init];
	m_boardData.m_strCommId = m_strCommId;
	m_boardData.m_nMode = m_nMode;
	m_boardData.target = self;
	m_boardData.selector = @selector(didFetchItems);
    [m_boardData fetchItems];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSMutableDictionary *item = [m_arrayItems objectAtIndex:[indexPath row]];
	NSNumber *nType = [item valueForKey:@"type"];
	if ([nType intValue] == CAFE_TYPE_TITLE) {
		return 25.0f;
	} else {
		return 44.0f;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [m_arrayItems count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifierBoard = @"Board";
	static NSString *CellIdentifierCalendar = @"Calendar";
	static NSString *CellIdentifierTitle = @"Title";
	
	NSMutableDictionary *item = [m_arrayItems objectAtIndex:[indexPath row]];
	UITableViewCell *cell;
	
	if ([[item valueForKey:@"type"] intValue] == CAFE_TYPE_TITLE) {
		cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierTitle];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierTitle];
		}
		cell.textLabel.text = [item valueForKey:@"title"];
	} else {
		int isCal = [[item valueForKey:@"isCal"] intValue];
		if (isCal == 0) {
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierBoard];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierBoard];
			}
			cell.textLabel.text = [item valueForKey:@"title"];
			if ([[item valueForKey:@"isNew"] intValue] == 0) {
				[cell.imageView setImage:[UIImage imageNamed:@"circle-blank"]];
			} else {
				[cell.imageView setImage:[UIImage imageNamed:@"circle"]];
			}
		} else {
			cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifierCalendar];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifierCalendar];
			}
			cell.textLabel.text = [item valueForKey:@"title"];
			if ([[item valueForKey:@"isNew"] intValue] == 0) {
				[cell.imageView setImage:[UIImage imageNamed:@"circle-blank"]];
			} else {
				[cell.imageView setImage:[UIImage imageNamed:@"circle"]];
			}
		}
	}
	return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	if ([[segue identifier] isEqualToString:@"Items"]) {
		ItemsView *view = [segue destinationViewController];
		NSIndexPath *currentIndexPath = [self.tbView indexPathForSelectedRow];
		long row = currentIndexPath.row;
		NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
		view.m_strCommId = m_strCommId;
		view.m_strBoardId = [item valueForKey:@"boardId"];
//		view.m_strLink = [item valueForKey:@"link"];
		view.m_nMode = [item valueForKey:@"type"];
	} else if ([[segue identifier] isEqualToString:@"Calendar"]) {
		GoogleCalView *view = [segue destinationViewController];
		NSIndexPath *currentIndexPath = [self.tbView indexPathForSelectedRow];
		long row = currentIndexPath.row;
		NSMutableDictionary *item = [m_arrayItems objectAtIndex:row];
		view.m_strCommId = m_strCommId;
		view.m_strBoardId = [item valueForKey:@"boardId"];
//		view.m_strLink = [item valueForKey:@"link"];
	}
}

#pragma mark - Board Data Function

- (void)didFetchItems
{
	m_arrayItems = [NSMutableArray arrayWithArray:m_boardData.m_arrayItems];
	[self.tbView reloadData];
}

@end

