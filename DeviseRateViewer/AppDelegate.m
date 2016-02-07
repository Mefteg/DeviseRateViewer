//
//  AppDelegate.m
//  DeviseRateViewer
//
//  Created by Tom Gimenez on 2/6/16.
//  Copyright © 2016 LadybugRiders. All rights reserved.
//

#import "AppDelegate.h"

static NSString* URL = @"https://api.fixer.io/latest";

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

@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) NSURLSession *urlSession;

@property (strong, nonatomic) NSDictionary *symbols;
@property (strong, nonatomic) NSMutableDictionary *preferences;

@property (strong, nonatomic) NSTimer *timerRequestDeviceRate;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setTitle:@"-"];
    [self.statusItem setAction:@selector(itemClicked:)];
    
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
    NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
    
    // if the file is reachable
    if (fileHandle != nil) {
        // read data from file
        NSData* data = [fileHandle readDataToEndOfFile];
        
        // parse to json
        self.symbols = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        if (error != nil) {
            NSLog(@"Error parsing JSON symbols.");
        }
    }
}

- (void)readPreferences {
    NSURL* url = [[NSBundle mainBundle] URLForResource:RSC_PREFERENCES withExtension:EXT_JSON];
    NSError *error = nil;
    NSFileHandle* fileHandle = [NSFileHandle fileHandleForReadingFromURL:url error:&error];
    
    // if the file is reachable
    if (fileHandle != nil) {
        // read data from file
        NSData* data = [fileHandle readDataToEndOfFile];
        
        // parse to json
        self.preferences = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        if (error != nil) {
            NSLog(@"Error parsing JSON preferences.");
        }
    }
}

- (void)writePreferences {
    NSURL* url = [[NSBundle mainBundle] URLForResource:RSC_PREFERENCES withExtension:EXT_JSON];
    NSError *error = nil;
    NSFileHandle* fileHandle = [NSFileHandle fileHandleForWritingToURL:url error:&error];
    
    // if the file is reachable
    if (fileHandle != nil) {
        // convert json to data
        NSData* data = [NSJSONSerialization dataWithJSONObject:self.preferences options:kNilOptions error:&error];
        
        if (error == nil) {
            // write data to file
            [fileHandle writeData:data];
        }
        else {
            NSLog(@"Error parsing JSON preferences.");
        }
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

// UI
//

- (void)itemClicked:(id)sender {
    [self requestDeviseRate];
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
        
        [self.statusItem setTitle:[NSString stringWithFormat:@"%0.2f%@", rate, [self.symbols valueForKey:currencyCode]]];
    }
    else {
        NSLog(@"Error parsing JSON.");
        [self.statusItem setTitle:@"X"];
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
