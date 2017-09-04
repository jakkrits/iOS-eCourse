//
//  MicroTransactions.m
//  fishdom_ipad
//
//  Created by vasiliym on 21.02.11.
//  Copyright 2011 Vasiliy Makarov All rights reserved.
//

#import "MicroTransactions.h"
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import "NSData+Base64.h"

// выводить пользователю сообщения об ошибках, иначе только в лог
//#define Verbose

BOOL storeIsInited = NO, processing = NO, finished = NO;
UIActivityIndicatorView *activityIndicator = 0;
NSString* deferredPurchasing;
int deferredPurchasingCount = 0;

@interface TransactionObserver : NSObject<SKPaymentTransactionObserver>
{
}
@end

@interface Store : NSObject

@property (retain) NSArray* products;
@property (retain) TransactionObserver* observer;
@property (retain) NSMutableArray* bought;
@property (retain) id delegate;

+(Store*) instance;
@end

@interface ProductsRequestDelegate : NSObject<SKProductsRequestDelegate> {
}
@property (assign) Store* store;
@end

BOOL autoRestore = NO;

//////////////////////////
//
// Transaction Observer

@implementation TransactionObserver

-(void)paymentQueue:(SKPaymentQueue *) __unused queue removedTransactions:(NSArray *) __unused transactions
{
}

-(void)paymentQueue:(SKPaymentQueue*)__unused queue restoreCompletedTransactionsFailedWithError:(NSError*)error
{
#ifdef Verbose
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[alert show];
#else
	NSLog([error localizedDescription]);
	NSLog([error localizedFailureReason]);
#endif
}

-(void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
	for(SKPaymentTransaction *tr in transactions) {
		switch (tr.transactionState) {
			case SKPaymentTransactionStatePurchasing:
				// process started
				NSLog(@"transaction started");
				break;
			case SKPaymentTransactionStatePurchased: {
				NSLog(@"transaction successful");
                NSString *prodId = tr.payment.productIdentifier;
				NSLog(@"%@", prodId);
				int t = [[NSUserDefaults standardUserDefaults] integerForKey:prodId];
				[[NSUserDefaults standardUserDefaults] setInteger:t+1 forKey:prodId];
				// successful
				[[[Store instance] bought] addObject:[NSString stringWithString:prodId]];
				// send data to the server
				//NSString *b64 = [tr.transactionReceipt base64EncodedString];
				// TODO
				[queue finishTransaction:tr];
				processing = NO;
				finished = YES;
				HideStoreActivityIndicator();
                [[NSNotificationCenter defaultCenter] postNotificationName:nOBJECT_PURCHASED object:prodId];
				break;
			}
			case SKPaymentTransactionStateRestored: {
				// restored
                NSString *prodId = tr.originalTransaction.payment.productIdentifier;
				if([[NSUserDefaults standardUserDefaults] integerForKey:prodId] <= 0)
					[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:prodId];
				[[[Store instance] bought] addObject:prodId];
				[queue finishTransaction:tr];
                [[NSNotificationCenter defaultCenter] postNotificationName:nOBJECT_RESTORED object:prodId];
				break;
			} 
			case SKPaymentTransactionStateFailed: {
				// error
				HideStoreActivityIndicator();
				processing = NO;
				finished = YES;
				if(tr.error.code == SKErrorPaymentCancelled) {
					// just break, no error
					NSLog(@"user cancelled transaction");
					break; 
				}
#ifdef Verbose
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[tr.error localizedDescription] message:[tr.error localizedFailureReason] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
				[alert show];
#else
				NSLog([tr.error localizedDescription]);
				NSLog([tr.error localizedFailureReason]);
#endif
				[queue finishTransaction:tr];
				break;
			}
		}
	}
}

-(void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)__unused queue
{
}

@end

//
//////////////////////
//
// Store

@implementation Store
@synthesize products;
@synthesize observer;
@synthesize bought;
@synthesize delegate;

+(Store*)instance
{
    static Store *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(_instance == nil) {
            _instance = [[Store alloc] init];
        }
    });
    return _instance;
}

@end

//
////////////////////////
//
// ProductsRequestDelegate

@implementation ProductsRequestDelegate
@synthesize store;
-(void)request:(SKRequest*)__unused request didFailWithError:(NSError*)error {
	finished = YES;
	processing = NO;
	HideStoreActivityIndicator();
#ifdef Verbose
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason] delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	[alert show];
#else
	NSLog([error localizedDescription]);
	NSLog([error localizedFailureReason]);
#endif
}

-(void)requestDidFinish:(SKRequest *)__unused request {
	// all right
	processing = NO;
	HideStoreActivityIndicator();
	NSLog(@"request did finish");
}

-(void)productsRequest:(SKProductsRequest*) request didReceiveResponse:(SKProductsResponse*)response {
	if([response.invalidProductIdentifiers count] > 0) {
		NSLog(@"There are invalid identifiers:");
		for(NSString *s in response.invalidProductIdentifiers) {
			NSLog(@"%@", s);
		}
	}
	for(SKProduct *pr in response.products) {
		NSLog(@"%@, %@", pr.localizedTitle, pr.price);
	}
	[Store instance].products = [[NSArray alloc] initWithArray:response.products];
	storeIsInited = YES;
	processing = NO;
	if(autoRestore) {
		// восстанавливаем покупки сделанные на более других устройствах
		[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	}
	if(deferredPurchasingCount > 0) {
		// если инициализация вызвана попыткой сделать покупку, то делаем эту покупку
		MakePurchaseById(deferredPurchasing, deferredPurchasingCount);
		deferredPurchasing = nil;
		deferredPurchasingCount = 0;
	}
}

@end

//
//////////////////////////
//
// Public interface

NSArray* lastInitData;

static SKProduct* getProduct(NSString* _id)
{
	for(SKProduct* pr in [Store instance].products) {
		NSString* prid = pr.productIdentifier;
		if([prid isEqualToString:_id]) return pr;
	}
	return nil;
}

void InitStore(NSArray* identifiers, BOOL _autoRestore)
{
	lastInitData = identifiers;
	autoRestore = _autoRestore;
	storeIsInited = NO;
	if(![SKPaymentQueue canMakePayments]) return;
	NSMutableSet * ids = [NSMutableSet setWithCapacity:[identifiers count]];
    [ids addObjectsFromArray:identifiers];
	[Store instance].observer = [TransactionObserver alloc];
	[Store instance].bought = [[NSMutableArray alloc] initWithCapacity:0];
	[[SKPaymentQueue defaultQueue] addTransactionObserver:[Store instance].observer];
	SKProductsRequest * req = [[SKProductsRequest alloc] initWithProductIdentifiers:ids];
	ProductsRequestDelegate *del = [ProductsRequestDelegate alloc];
	[Store instance].delegate = del;
	del.store = [Store instance];
	req.delegate = [Store instance].delegate;
	[req start];
}

static void ReinitStore(NSArray* identifiers)
{
	if(storeIsInited) return;
	processing = YES;
	ShowStoreActivityIndicator();
	NSMutableSet * ids = [NSMutableSet setWithCapacity:[identifiers count]];
    [ids addObjectsFromArray:identifiers];
	SKProductsRequest * req = [[SKProductsRequest alloc] initWithProductIdentifiers:ids];
	req.delegate = [Store instance].delegate;
	[req start];
}

BOOL StoreIsInited()
{
	return storeIsInited;
}

int StoreSize()
{
	return [[Store instance].products count];
}

// передать экземпляр UIActivityIndicatorView
void SetStoreActivityIndicator(UIActivityIndicatorView* act)
{
	activityIndicator = act;
}

void ShowStoreActivityIndicator()
{
	if(activityIndicator != nil && processing) {
		[activityIndicator startAnimating];
	}
}

void HideStoreActivityIndicator()
{
	if(activityIndicator != nil) {
		[activityIndicator stopAnimating];
	}
}

NSString* ProductName(unsigned int i)
{
	assert(i < [[Store instance].products count]);
	SKProduct* pr = [[Store instance].products objectAtIndex:i];
	return pr.localizedTitle;
}

NSString* ProductDesc(unsigned int i)
{
	assert(i < [[Store instance].products count]);
	SKProduct* pr = [[Store instance].products objectAtIndex:i];
	return pr.localizedDescription;
}

NSString* ProductPrice(unsigned int i)
{
	assert(i < [[Store instance].products count]);
	SKProduct* pr = [[Store instance].products objectAtIndex:i];
	NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterCurrencyStyle];
	[nf setLocale:pr.priceLocale];
	NSString *s = [nf stringFromNumber:pr.price];
	return s;
}

NSString* ProductId(unsigned int i)
{
	assert(i < [[Store instance].products count]);
	SKProduct* pr = [[Store instance].products objectAtIndex:i];
	return pr.productIdentifier;
}

NSString* ProductNameById(NSString* _id)
{
	SKProduct* pr = getProduct(_id);
	return pr.localizedTitle;
}

NSString* ProductDescById(NSString* _id)
{
	SKProduct* pr = getProduct(_id);
	return pr.localizedDescription;
}

NSString* ProductPriceById(NSString* _id)
{
	SKProduct* pr = getProduct(_id);
	NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterCurrencyStyle];
	[nf setLocale:pr.priceLocale];
	NSString *s = [nf stringFromNumber:pr.price];
	return s;
}

BOOL CanPurchase()
{
	return [SKPaymentQueue canMakePayments] && StoreIsInited();
}

BOOL MakePurchase(unsigned int i, int quantity)
{
	if(processing) return NO;
	if(![SKPaymentQueue canMakePayments]) {
		return NO;
	}
	if(!StoreIsInited() && [lastInitData count]) { // try reinit store
		ReinitStore(lastInitData);
		deferredPurchasing = ProductId(i);
		deferredPurchasingCount = quantity;
		return NO;
	}
	if(quantity == 1) {
		SKPayment *payment = [SKPayment paymentWithProduct:[[Store instance].products objectAtIndex:i]];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	} else if(quantity > 1) {
		SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:[[Store instance].products objectAtIndex:i]];
		payment.quantity = quantity;
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	} else {
		assert(NO);
	}
	processing = YES;
	ShowStoreActivityIndicator();
	return YES;
}

BOOL MakePurchaseById(NSString* _id, int quantity)
{
	if(processing) return NO;
	if(![SKPaymentQueue canMakePayments]) {
		return NO;
	}
	if(!StoreIsInited() && [lastInitData count]) { // try reinit store
		ReinitStore(lastInitData);
		deferredPurchasing = _id;
		deferredPurchasingCount = quantity;
		return NO;
	}
    SKProduct *prod = nil;
    for(SKProduct *p in [Store instance].products) {
        if([p.productIdentifier isEqualToString:_id]) {
            prod = p;
            break;
        }
    }
    if(prod == nil) {
        NSLog(@"product %@ not found!", _id);
    }
	if(quantity == 1) {
		SKPayment *payment = [SKPayment paymentWithProduct:prod];
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	} else if (quantity > 1) {
		SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:prod];
		payment.quantity = quantity;
		[[SKPaymentQueue defaultQueue] addPayment:payment];
	} else {
		assert(NO);
	}
	processing = YES;
	ShowStoreActivityIndicator();
	return YES;
}

BOOL RestorePurchases()
{
    if(!storeIsInited || processing) return NO;
    // восстанавливаем покупки сделанные на более других устройствах
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
	ShowStoreActivityIndicator();
    return YES;
}

BOOL HavePurchasing()
{
	return [[Store instance].bought count] > 0;
}

NSString* GetPurchasing()
{
	NSString* _id = [[Store instance].bought lastObject];
	[[Store instance].bought removeLastObject];
	return _id;
}

int WasPurchased(NSString* _id)
{
	int n = [[NSUserDefaults standardUserDefaults] integerForKey:_id];
	return n;
}

BOOL StoreTransactionFinished()
{
	BOOL f = finished;
	finished = NO;
	return f;
}

BOOL IsProcessing()
{
	return processing;
}

//
////////////////////////////
