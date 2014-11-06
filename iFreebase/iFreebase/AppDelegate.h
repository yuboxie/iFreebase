//
//  AppDelegate.h
//  iFreebase
//
//  Created by 谢雨波 on 14-10-30.
//  Copyright (c) 2014年 SOFA. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <NMSSH/NMSSH.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@property (strong) NMSSHSession *session;

// In the drawer
@property (weak) IBOutlet NSTextField *hostAddress;
@property (weak) IBOutlet NSTextField *userName;
@property (weak) IBOutlet NSSecureTextField *password;
@property (weak) IBOutlet NSTextField *command;
@property (weak) IBOutlet NSTextField *result;
@property (weak) IBOutlet NSTextField *currentState;

// In the main window
@property (weak) IBOutlet NSPopUpButton *typeOfQuery;
@property (weak) IBOutlet NSSearchField *query;
@property (weak) IBOutlet NSScrollView *queryResultScrollView;
@property (weak) IBOutlet NSTableView *queryResultTableView;
@property (weak) IBOutlet NSTableHeaderView *queryResultTableHeaderView;
@property (weak) IBOutlet NSTextField *noResults;


// In the drawer
- (IBAction)connectSSH:(id)sender;
- (IBAction)disconnectSSH:(id)sender;
- (IBAction)run:(id)sender;
- (IBAction)clearResult:(id)sender;

// In the main window
- (IBAction)toggleDrawer:(id)sender;
- (IBAction)sendQuery:(id)sender;
- (IBAction)chooseQueryType:(id)sender;
- (IBAction)clearTableResult:(id)sender;
- (IBAction)selectRow:(id)sender;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (NSView *)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex;

@end
