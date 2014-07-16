//
//  ViewController.m
//  MobileConnectivity
//
//  Created by Michael Crump on 7/15/14.
//  Copyright (c) 2014 Michael Crump. All rights reserved.
//

#import "ViewController.h"
#import <TelerikUI/TelerikUI.h>
#import "VideoGame.h"

@interface ViewController ()<TKDataSyncDelegate>

@property (nonatomic, strong) TKDataSyncContext* theContext;

@property (nonatomic, strong) NSArray* products;

@property (nonatomic, strong) NSString* accessToken;

@property (nonatomic, strong) NSString* apiKey;
@end
 
@implementation ViewController

/*!
 Lazy load access token
 */
-(NSString*) accessToken{
    if (_accessToken) {
        return _accessToken;
    }
    
    [self obtainAccessTokenForApiKey:self.apiKey];
    return _accessToken;
}

-(void)obtainAccessTokenForApiKey:(NSString*) apiKey
{
    //Use appropriate username & password here
    NSDictionary* userInfo= @{  @"username": @"mbcrump", @"password": @"mike8888", @"grant_type": @"password"};
    NSError *error;
    NSData* body  = [NSJSONSerialization dataWithJSONObject:userInfo
                                                    options:NSJSONWritingPrettyPrinted
                                                      error:&error];
    
    NSString* strUrl = [NSString stringWithFormat:@"http://api.everlive.com/v1/%@/oauth/token", apiKey];
    NSURL* url = [NSURL URLWithString:strUrl];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                    
                                                       timeoutInterval:30];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:body];
    
    NSURLResponse* response = nil;
    NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (!data){
        _accessToken = @"";
        return;
    }
    
    NSDictionary *res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    // show all values , just for debug purposes
    for(id key in res){
        id value = [res objectForKey:key];
        
        NSString *strKey = (NSString *)key;
        NSString *strValue = (NSString *)value;
        NSLog(@"key: %@ \nvalue: %@", strKey, strValue);
    }
    
    // extract access token value only
    NSDictionary* resDict = [res objectForKey:@"Result"];
    NSString *token = [resDict objectForKey:@"access_token"];
    NSLog(@"Access token: %@", token);
    
    _accessToken = token;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //1: Create Everlive client instance
    self.apiKey = @"4VuHzPclrrzPu5XI"; //put here the ApiKey of the application that you use for backend
    
    TKEverliveClient* everliveClient = [TKEverliveClient clientWithApiKey:self.apiKey
                                                              accessToken:self.accessToken //see property getter
                                                           serviceVersion:@1];
    
    //2: init the policy
    TKDataSyncReachabilityOptions options = TKSyncIn3GNetwork | TKSyncInWIFINetwork;
    TKDataSyncPolicy* thePolicy = [[TKDataSyncPolicy alloc] initForSyncOnDemandWithReachabilityOptions:options
                                                                                conflictResolutionType:TKPreferLocalInstance
                                                                                           syncTimeout:100.0];

    
    
    _theContext = [[TKDataSyncContext alloc] initWithLocalStoreName:@"localGameDb" cloudService:everliveClient  syncPolicy:thePolicy];
    
    [_theContext setDelegate:self];
    
    [_theContext registerClass:[VideoGame class] withPrimaryKeyField:@"gameId" asAutoincremental:NO];
    
}

-(VideoGame*) generateNewProduct
{
    VideoGame* videogame = [[VideoGame alloc] init];
    int rnd = arc4random() % 1000;
    videogame.gameId = [[NSString alloc] initWithFormat:@"#%i", rnd ];
    videogame.gameTitle = [[NSString alloc] initWithFormat:@"Halo #%i", rnd ];
    
    return videogame;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)addTheItem:(id)sender {
    VideoGame* pd = [self generateNewProduct];
    
    [_theContext insertObject:pd];
    
    NSError* error = nil;
    //in case of insertion of many objects, call saveChanges at the very end
    if (![_theContext saveChanges:&error]) {
        NSAssert(FALSE, @"Error during persisting of new games:%@", error.description);
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Item Saved"
                                                        message:@"SUCCESSFULLY "
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];

    }
}

- (IBAction)viewTheItems:(id)sender {
    

    [_theContext syncChangesAsync:dispatch_get_main_queue()
                completionHandler: ^(BOOL result, NSError *error) {
                    if (!result) {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Data synchronization"
                                                                        message:@"FAILED "
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }
                    else{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Data synchronization"
                                                                        message:@"SUCCEEDED "
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                        [alert show];
                    }
                    _products = [NSMutableArray arrayWithArray:[self.theContext getAllObjectsOfType:VideoGame.class failedWithError:&error]];
            
                }];
    /*
    if (self.theContext)
    {
        NSError* error = nil;
        _products = [self.theContext getAllObjectsOfType:VideoGame.class failedWithError:&error];
        if (!_products){
            NSAssert(FALSE, @"Error during persisting of new product:%@", error.description);
        }
    }
    //VideoGame* theVG = _products[1];
    
    NSString* str = nil;
    for (id obj in _products) {
        VideoGame* theVG = obj;
        str = [NSString stringWithFormat:@"Id: %@ | Title: %@", theVG.gameId, theVG.gameTitle];
        str = [str stringByAppendingString:str];
    }
    
    //NSString* str = [NSString stringWithFormat:@"Id: %@ | Title: %@", theVG.gameId, theVG.gameTitle];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game Added"
                                                    message:str
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
*/

}

#pragma TKDataSyncDelegate

- (BOOL)dataSyncContextIsReadyForSyncExecution
{
    NSLog(@"\n --> dataSyncContextIsReadyForSyncExecution: called.");
    return YES;
}

- (BOOL)dataSyncFailedForTableWithName:(NSString*) name
                             withError:(NSError**) error
{
    NSLog(@"\n --> dataSyncFailedForTableWithName:name:error called");
    return YES; //let's try again to synchronize this table
}

- (id) resolveConflictOfObjectsWithType:(Class) type
                           remoteObject:(id) remote
                             localOject:(id) local
{
    NSLog(@"\n --> resolveConflictOfObjectsWithType:type:remote:local called.");
    return local;
}

- (BOOL)beforeSynchOfTableWithName:(NSString*) tableName
{
    NSLog(@"\n --> beforeSynchOfTableWithName: called.");
    return YES;
}

- (BOOL)afterSynchOfTableWithName:(NSString*) tableName
                    doneWithError:(NSError**) error
{
    NSLog(@"\n --> afterSynchOfTableWithName: called.");
    return YES;
}

#pragma Helpers
@end
