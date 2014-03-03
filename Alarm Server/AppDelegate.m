//
//  AppDelegate.m
//  Alarm Server
//
//  Created by Glen Schrader on 2014-03-01.
//  Copyright (c) 2014 Glen Schrader. All rights reserved.
//

#import <objc/NSObject.h>
#import "AppDelegate.h"
#import "AFNetworking.h"

@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.menu;
    self.statusItem.highlightMode = YES;

    [self.menu setAutoenablesItems:NO];
    
    [self start:nil];

    [NSTimer scheduledTimerWithTimeInterval: 2.0
                                     target: self
                                   selector:@selector(onTick:)
                                   userInfo: nil repeats:YES];
}

-(void)onTick:(NSTimer *)timer {
    if ([self.task isRunning]) {
        [self determineState];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification;
{
    [self.task terminate];
}

- (void)setState:(AlarmState) state
{
    NSImage *img = [NSImage imageNamed:@"Icon"];

    [img lockFocus];
    
    NSColor* color = [NSColor grayColor];
    switch (state) {
        case ALARM_STOPPED:
            color = [NSColor grayColor];
            [self.startMenu setEnabled:YES];
            [self.stopMenu setEnabled:NO];
            [self.awayMenu setEnabled:NO];
            [self.stayMenu setEnabled:NO];
            break;
            
        case ALARM_ON:
            color = [NSColor redColor];
            [self.awayMenu setEnabled:NO];
            [self.stayMenu setEnabled:NO];
            break;
            
        case ALARM_READY:
            color = [NSColor greenColor];
            [self.startMenu setEnabled:NO];
            [self.stopMenu setEnabled:YES];
            [self.awayMenu setEnabled:YES];
            [self.stayMenu setEnabled:YES];
            break;
            
        case ALARM_ENTRY:
        case ALARM_EXIT:
            color = [NSColor yellowColor];
            [self.awayMenu setEnabled:NO];
            [self.stayMenu setEnabled:NO];
            break;
            
        default:
            break;
    }
    
    NSBezierPath* ovalPath = [NSBezierPath bezierPathWithOvalInRect: NSMakeRect(0, 0, 6, 6)];
    [color setFill];
    [ovalPath fill];
    
    [img unlockFocus];
    
    self.statusItem.image = img;
}


- (void)stop:(id)sender {
    if ([self.task isRunning]) {
        [self.task terminate];
        [self setState:ALARM_STOPPED];
    }
}

- (void)start:(id)sender {
    if (![self.task isRunning]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        if ([defaults stringForKey:@"repos"] != nil) {
            NSString *repos = [defaults objectForKey:@"repos"];
            NSLog(@"starting at: %@", repos);
            
            self.task = [[NSTask alloc] init];
            
            self.task.launchPath = @"/usr/bin/python";
            
            self.task.arguments = @[[NSString stringWithFormat:@"%@/alarmserver.py", repos]];
            self.task.currentDirectoryPath = repos;
            
            [self.task launch];

            [self.startMenu setEnabled:NO];
            [self.stopMenu setEnabled:YES];
        } else {
            [self preferences:nil];
        }
    }
}

- (void)show:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://localhost:8111/"]];
}

- (void)preferences:(id)sender {
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setPrompt:@"Select"];
    [openPanel setTitle: @"Select AlarmServer git repository"];
    
    if ([openPanel runModal] == NSOKButton)
    {
        if ([self.task isRunning]) {
            [self.task terminate];
        }
        
        NSURL *theURL = [[openPanel URLs] objectAtIndex:0];
        NSLog(@"%@", theURL);
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:theURL.path forKey:@"repos"];
        [NSUserDefaults resetStandardUserDefaults];

        [self start:nil];
    }
}

- (void)determineState {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager.securityPolicy setAllowInvalidCertificates:TRUE];
    [manager GET:@"https://localhost:8111/api" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"JSON: %@", responseObject);
        
//        NSString *status = [responseObject valueForKeyPath:@"partition.1.status"];
//        NSLog(@"status: %@", status);

        AlarmState state = ALARM_STOPPED;

        if ([[responseObject valueForKeyPath:@"partition.1.status.ready"] boolValue]) {
            state = ALARM_READY;
        }
        
        if ([[responseObject valueForKeyPath:@"partition.1.status.exit_delay"] boolValue]) {
            state = ALARM_EXIT;
        }
        
        if ([[responseObject valueForKeyPath:@"partition.1.status.entry_delay"] boolValue]) {
            state = ALARM_ENTRY;
        }
        
        if ([[responseObject valueForKeyPath:@"partition.1.status.armed"] boolValue]) {
            state = ALARM_ON;
        }
        
        [self setState:state];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        [self setState:ALARM_STOPPED];
    }];
}

- (void)stay:(id)sender {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager.securityPolicy setAllowInvalidCertificates:TRUE];
    [manager GET:@"https://localhost:8111/api/alarm/stayarm" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: %@", error);
         }
     ];
}

- (void)away:(id)sender {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    [manager.securityPolicy setAllowInvalidCertificates:TRUE];
    [manager GET:@"https://localhost:8111/api/alarm/arm" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
    }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Error: %@", error);
         }
     ];
}


@end
