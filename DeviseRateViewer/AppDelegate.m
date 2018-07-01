//
//  AppDelegate.m
//  DeviseRateViewer
//
//  Created by Tom Gimenez on 2/6/16.
//  Copyright © 2016 LadybugRiders. All rights reserved.
//

#import "AppDelegate.h"

static NSString* URL = @"https://exchangeratesapi.io/api/latest";

static NSString* KEY_BASE       = @"base";
static NSString* KEY_SYMBOLS    = @"symbols";
static NSString* KEY_RATES      = @"rates";
static NSString* KEY_FROM       = @"from";
static NSString* KEY_TO         = @"to";

static NSString* DEFAULT_FROM   = @"CAD";
static NSString* DEFAULT_TO     = @"EUR";

static NSString* RSC_SYMBOLS        = @"symbols";
static NSString* RSC_PREFERENCES    = @"preferences";
static NSString* EXT_JSON           = @"json";

static NSTimeInterval INTERVAL_REQUEST_DEVISE_RATE = 6 * 60 * 60; // in seconds

@interface AppDelegate ()

// UI
@property (strong, nonatomic) NSStatusItem *rateItem;
@property (strong) IBOutlet NSMenu *rateMenu;

@property (strong) IBOutlet NSMenu *fromMenu;
@property (strong) IBOutlet NSMenu *toMenu;

// HTTP REQUEST
@property (strong, nonatomic) NSURLSession *urlSession;

// DATA
@property (strong, nonatomic) NSDictionary *symbols;
@property (strong, nonatomic) NSMutableDictionary *preferences;

// TIMER
@property (strong, nonatomic) NSTimer *timerRequestDeviceRate;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // init main menu item
    self.rateItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.rateItem setTitle:@"-"];
    [self.rateItem setHighlightMode:YES];
    [self.rateItem setAction:@selector(rateItemClicked:)];
    
    // set the menu
    self.rateItem.menu = self.rateMenu;
    
    self.urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate: self delegateQueue: [NSOperationQueue mainQueue]];
    
    // set default preferences
    [self setDefaultPreferences];
    
    // read currencies symbols
    [self readSymbols];
    
    // read stored preferences
    [self readPreferences];
    
    // launch the request
    [self requestDeviseRate];
    
    // launch the timer
    self.timerRequestDeviceRate = [NSTimer scheduledTimerWithTimeInterval:INTERVAL_REQUEST_DEVISE_RATE target:self selector:@selector(requestDeviseRateWithTimer:) userInfo:nil repeats:true];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    
    [self writePreferences];
}

- (void)setDefaultPreferences {
    self.preferences = [[NSMutableDictionary alloc] init];
    [self.preferences setObject:DEFAULT_FROM forKey:KEY_FROM];
    [self.preferences setObject:DEFAULT_TO forKey:KEY_TO];
}

- (void)readSymbols {
    NSURL* url = [[NSBundle mainBundle] URLForResource:RSC_SYMBOLS withExtension:EXT_JSON];
    NSError *error = nil;
    
    // read data
    NSString* input = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    if (error == nil) {
        // convert string to data
        NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
        // parse to json
        NSMutableDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if (error == nil) {
            self.symbols = json;
        }
        else {
            NSLog(@"Error parsing JSON preferences.");
        }
    }
    else {
        NSLog(@"Error writing preferences");
    }
}

- (void)readPreferences {
    NSURL* url = [[NSBundle mainBundle] URLForResource:RSC_PREFERENCES withExtension:EXT_JSON];
    NSError *error = nil;
    
    // read data
    NSString* input = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    
    if (error == nil) {
        // convert string to data
        NSData* data = [input dataUsingEncoding:NSUTF8StringEncoding];
        // parse to json
        NSMutableDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        
        if (error == nil) {
            self.preferences = json;
        }
        else {
            NSLog(@"Error parsing JSON preferences.");
        }
    }
    else {
        NSLog(@"Error writing preferences");
    }
}

- (void)writePreferences {
    NSURL* url = [[NSBundle mainBundle] URLForResource:RSC_PREFERENCES withExtension:EXT_JSON];
    NSError *error = nil;
    
    NSData* data = [NSJSONSerialization dataWithJSONObject:self.preferences options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error == nil) {
        // convert data to string
        NSString* output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        // write string to file
        [output writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (error != nil) {
            NSLog(@"Error writing preferences");
        }
    }
    else {
        NSLog(@"Error parsing JSON preferences.");
    }
}

- (void)requestDeviseRate {
    NSString* urlStr = [NSString stringWithFormat:@"%@?%@=%@&%@=%@", URL, KEY_BASE, [self.preferences valueForKey:KEY_FROM], KEY_SYMBOLS, [self.preferences valueForKey:KEY_TO]];
    NSURL *url = [NSURL URLWithString:urlStr];
    
    
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithURL: url];
    
    [dataTask resume];
}

- (void)requestDeviseRateWithTimer:(NSTimer*)timer {
    [self requestDeviseRate];
}

-(void)updateFromAndToListWithRates:(NSDictionary*)rates {
    [self.fromMenu removeAllItems];
    [self.toMenu removeAllItems];
    
    NSArray *keys = [self.symbols allKeys];
    NSArray *sortedKeys = [keys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    for (id key in sortedKeys) {
        NSString* keyStr = [NSString stringWithFormat:@"%@", key];
        
        NSMenuItem* fromItem = [self.fromMenu addItemWithTitle:keyStr action:@selector(fromItemClicked:) keyEquivalent:keyStr];
        if (keyStr == [self.preferences valueForKey:KEY_FROM]) {
            [fromItem setState:NSOnState];
        }
        
        NSMenuItem* toItem = [self.toMenu addItemWithTitle:keyStr action:@selector(toItemClicked:) keyEquivalent:keyStr];
        if (keyStr == [self.preferences valueForKey:KEY_TO]) {
            [toItem setState:NSOnState];
        }
    }
}

// UI
//

- (void)rateItemClicked:(id)sender {
    [self requestDeviseRate];
}

- (void)fromItemClicked:(id)sender {
    NSString* keyEquiv = [sender keyEquivalent];
    [self.preferences setObject:keyEquiv forKey:KEY_FROM];
    
    [self requestDeviseRate];
}

- (void)toItemClicked:(id)sender {
    NSString* keyEquiv = [sender keyEquivalent];
    [self.preferences setObject:keyEquiv forKey:KEY_TO];
    
    [self requestDeviseRate];
}

- (IBAction)updateItemClicked:(id)sender {
    [self requestDeviseRate];
}

- (IBAction)closeItemClicked:(id)sender {
    [[NSApplication sharedApplication] terminate:self];
}

// NSURLSessionDelegate
//

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    
    NSError *error = nil;
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    
    if (error == nil) {
        NSDictionary *rates = [jsonArray valueForKey:KEY_RATES];
        
        NSString* currencyCode = [self.preferences valueForKey:KEY_TO];
        float rate = [[NSString stringWithFormat:@"%@",[rates valueForKey:currencyCode]] floatValue];
        
        [self.rateItem setTitle:[NSString stringWithFormat:@"%0.2f%@", rate, [self.symbols valueForKey:currencyCode]]];
        
        [self updateFromAndToListWithRates:rates];
    }
    else {
        NSLog(@"Error parsing JSON.");
        [self.rateItem setTitle:@"X"];
    }
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (error != nil) {
        NSLog(@"%@", error);
    }
}

@end
