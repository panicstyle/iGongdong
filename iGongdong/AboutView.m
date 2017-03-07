//
//  AboutView.m
//  iGongdong
//
//  Created by dykim on 2016. 3. 3..
//  Copyright © 2016년 dykim. All rights reserved.
//

#import "AboutView.h"

@interface AboutView ()

@end

@implementation AboutView
@synthesize textView;
@synthesize btnDonation;

+ (id) sharedManager
{
	static AboutView * sharedMyManager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedMyManager = [[self alloc] init];
	});
	return sharedMyManager;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	NSString *msgAbout;
	
    // Do any additional setup after loading the view from its nib.
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
//    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
	msgAbout = [NSString stringWithFormat:@"공동육아앱 for iOS\n버전 : %@\n개발자 : 호랑이(과천맨발어린이집 졸업조합원)\n문의메일 : panicstyle@gmail.com\n홈페이지 : http://www.panicstyle.net/?page_id=7\n소스 : https://github.com/panicstyle/iGongdong\n\n광고수익은 공동육아 저소득기금으로 사용됩니다.",  version];
    textView.text = msgAbout;
}

- (IBAction)doDonation:(id)sender {
	NSSet *productIdentifiers = [NSSet setWithObjects:@"com.panicstyle.iGongdong.donation1", nil];
	
	SKProductsRequest *productsRequest = [[SKProductsRequest alloc]
										  initWithProductIdentifiers:productIdentifiers];
	productsRequest.delegate = self;
	[productsRequest start];
}

// 1. 조회가 정상이면 구매 요청을 한다.
- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
	if( [response.products count] > 0 ) {
		[self paymentRequest:[response.products objectAtIndex:0]];
	} else {
		NSLog(@"In-App Purchase Fail");
//		[self callDelegateFail:@"response.products count <= 0"];
	}
}

- (void) paymentRequest:(SKProduct *) product
{
	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
	payment.quantity = 1;
	NSLog(@"SKPaymentQueue");
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

// Sent when the transaction array has changed (additions or state changes).  Client should check state of transactions and finish as appropriate.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	NSLog(@"paymentQueue");
	for (SKPaymentTransaction *transaction in transactions) {
		switch (transaction.transactionState) {
				// Call the appropriate custom method for the transaction state.
			case SKPaymentTransactionStatePurchasing:
				NSLog(@"SKPaymentTransactionStatePurchasing");
//				[self showTransactionAsInProgress:transaction deferred:NO];
				break;
			case SKPaymentTransactionStateDeferred:
				NSLog(@"SKPaymentTransactionStateDeferred");
//				[self showTransactionAsInProgress:transaction deferred:YES];
				break;
			case SKPaymentTransactionStateFailed:
				NSLog(@"SKPaymentTransactionStateFailed");
//				[self failedTransaction:transaction];
				break;
			case SKPaymentTransactionStatePurchased:
				// Load the receipt from the app bundle.
				[self completeTransaction:transaction];
				break;
			case SKPaymentTransactionStateRestored:
				NSLog(@"SKPaymentTransactionStateRestored");
				[self restoreTransaction:transaction];
				break;
			default:
				// For debugging
				NSLog(@"Unexpected transaction state %@", @(transaction.transactionState));
//				[self callDelegateFail:@"transactionState is default"];
				break;
		}
	}
}

- (void) completeTransaction:(SKPaymentTransaction *)transaction{
	[[SKPaymentQueue defaultQueue] finishTransaction:transaction];

	NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
	[[NSBundle mainBundle] appStoreReceiptURL];
	NSData *receipt = [NSData dataWithContentsOfURL:receiptURL];
	if (!receipt) {
		/* No local receipt -- handle the error. */
//		[self callDelegateFail:@"complete. but don't exist receipt"];
	} else {
		//        NSLog(@"SKPaymentTransactionStatePurchased receipt : %@", receipt);
		//        NSString *encReceipt = [receipt base64EncodedStringWithOptions:0];
		//        NSLog(@"SKPaymentTransactionStatePurchased encReceipt : %@", encReceipt);
		
//		[self callDelegateSuccess:receipt];
//		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
	}
}

- (void) restoreTransaction:(SKPaymentTransaction *)transaction {
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
@end
