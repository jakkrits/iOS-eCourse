//
//  MicroTransactions.h
//  fishdom_ipad
//
//  Created by vasiliym on 21.02.11.
//  Copyright 2011 Vasiliy Makarov All rights reserved.
//

#define nOBJECT_PURCHASED @"nOBJECT_PURCHASED"
#define nOBJECT_RESTORED @"nOBJECT_RESTORED"

// Инициализация магазина,
// autoRestore - надо ли обращаться в iTunes за списком уже совершённых покупок (требует ввода пароля)
void InitStore(NSArray* identifiers, BOOL autoRestore);

// Магазин инициализировался 
BOOL StoreIsInited(void);

// кол-во предметов в магазине
int StoreSize(void);

// передать экземпляр UIActivityIndicatorView
void SetStoreActivityIndicator(UIActivityIndicatorView* act);
// скрыть индикатор если он виден

void HideStoreActivityIndicator(void);
void ShowStoreActivityIndicator(void);

// информация по предметам
NSString* ProductName(unsigned int i);
NSString* ProductDesc(unsigned int i);
NSString* ProductPrice(unsigned int i);
NSString* ProductId(unsigned int i);
NSString* ProductNameById(NSString* _id);
NSString* ProductDescById(NSString* _id);
NSString* ProductPriceById(NSString* _id);

// возвращает false если пользователь запретил покупки
BOOL CanPurchase(void);

// возвращает true если покупка была успешно поставлена в очередь на оплату
BOOL MakePurchase(unsigned int i, int quantity);
BOOL MakePurchaseById(NSString* _id, int quantity);
BOOL RestorePurchases(void);

// есть купленные покупки
BOOL HavePurchasing(void);

// вернуть идентификатор купленной покупки
NSString* GetPurchasing(void);

// возвращает true после завершения транзакции, успешном или не успешном.
// Только один раз!
BOOL StoreTransactionFinished(void);

// была ли выполнена покупка с таким идентификатором (сколько раз)
int WasPurchased(NSString* _id);

// обрабатывается ли какая-то транзакция сейчас
BOOL IsProcessing(void);
