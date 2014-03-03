//
//  AppDelegate.h
//  Alarm Server
//
//  Created by Glen Schrader on 2014-03-01.
//  Copyright (c) 2014 Glen Schrader. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSStatusItem *statusItem;
@property (weak) IBOutlet NSMenu *menu;
@property (nonatomic) NSTask *task;
@property (weak) IBOutlet NSMenuItem *startMenu;
@property (weak) IBOutlet NSMenuItem *stopMenu;
@property (weak) IBOutlet NSMenuItem *stayMenu;
@property (weak) IBOutlet NSMenuItem *awayMenu;

typedef NS_ENUM(NSUInteger, AlarmState) {
    ALARM_READY,
    ALARM_STOPPED,
    ALARM_EXIT,
    ALARM_ENTRY,
    ALARM_ON
};

- (IBAction)show:(id)sender;
- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;
- (IBAction)away:(id)sender;
- (IBAction)stay:(id)sender;

- (IBAction)preferences:(id)sender;

@end
