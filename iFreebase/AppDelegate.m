//
//  AppDelegate.m
//  iFreebase
//
//  Created by 谢雨波 on 14-10-30.
//  Copyright (c) 2014年 SOFA. All rights reserved.
//

#import "AppDelegate.h"

@implementation NSString (JRAdditions)

+ (BOOL)isStringEmpty:(NSString *)string {
    if([string length] == 0) { //string is empty or nil
        return YES;
    }
    
    if(![[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length]) {
        //string is all whitespace
        return YES;
    }
    
    return NO;
}

@end


@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *mainWindow;
@property (strong) NSMutableArray *entityIDs;
@property (strong) NSMutableArray *names;
@property (strong) NSMutableArray *types;
@property (strong) NSMutableArray *properties;
@property (strong) NSMutableArray *objectIDs;
@property (strong) NSMutableArray *objectNames;
@property NSInteger lastSelectedRow;
@property (weak) IBOutlet NSPanel *sshToolsPanel;

- (void)parseResponse:(NSString *)response;

@end

@implementation AppDelegate

@synthesize session;
@synthesize entityIDs;
@synthesize names;
@synthesize types;
@synthesize properties;
@synthesize objectIDs;
@synthesize objectNames;
@synthesize lastSelectedRow;

// In the drawer
@synthesize currentState;
@synthesize hostAddress;
@synthesize userName;
@synthesize password;
@synthesize command;
@synthesize result;

// In the main window
@synthesize typeOfQuery;
@synthesize query;
@synthesize queryResultScrollView;
@synthesize queryResultTableView;
@synthesize queryResultTableHeaderView;
@synthesize noResults;


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    NSInteger numberOfRows;
    switch (typeOfQuery.indexOfSelectedItem) {
        case 0:
            numberOfRows = entityIDs.count;
            break;
        
        case 1:
            numberOfRows = types.count;
            break;
        
        case 2:
            numberOfRows = properties.count;
            break;
            
        default:
            break;
    }
    return numberOfRows;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTextField *textField = [[NSTextField alloc] init];
    switch (typeOfQuery.indexOfSelectedItem) {
        case 0:
            if ([tableColumn.identifier isEqualToString:@"col_1"]) {
                [textField setStringValue:[entityIDs objectAtIndex:row]];
            } else if ([tableColumn.identifier isEqualToString:@"col_2"]) {
                [textField setStringValue:[names objectAtIndex:row]];
            }
            break;
        
        case 1:
            if ([tableColumn.identifier isEqualToString:@"col_1"]) {
                [textField setStringValue:[types objectAtIndex:row]];
            }
            break;
        
        case 2:
            if ([tableColumn.identifier isEqualToString:@"col_1"]) {
                [textField setStringValue:[properties objectAtIndex:row]];
            }
            break;
            
        default:
            break;
    }
    [textField setEditable:NO];
    [textField setSelectable:YES];
    [textField setBordered:NO];
    [textField setBackgroundColor:[NSColor colorWithWhite:0 alpha:0]];
    return textField;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self.mainWindow setMinSize:NSMakeSize(400, 500)];
    
    [currentState setStringValue:@"Connecting..."];
    session = [NMSSHSession connectToHost:hostAddress.stringValue
                             withUsername:userName.stringValue];
    if (session.isConnected) {
        [currentState setStringValue:@"Connected"];
        [session authenticateByPassword:password.stringValue];
        if (session.isAuthorized) {
            [currentState setStringValue:@"Authentication Succeeded"];
        } else {
            [currentState setStringValue:@"Authentication Failed"];
        }
    }
    
    [noResults setHidden:YES];

    
    // Set up the typeOfQuery pop up button
    [typeOfQuery removeAllItems];
    [typeOfQuery addItemsWithTitles:@[@"1. Given a name, return all entities matching the name.",
                                      @"2. Given an entity ID, return all types it belongs to.",
                                      @"3. Given an entity ID, return all properties whose schema/expected_type is one type of the entity.",
                                      @"4. Given an entity ID, return all objects that are co-occurred with this entity in one triple."]];
    [typeOfQuery selectItemAtIndex:0];
    
    // Set up the search field
    [query.cell setPlaceholderString:@"Input a name, and press Enter."];
    
    // Set up the table view
    entityIDs = [[NSMutableArray alloc] init];
    names = [[NSMutableArray alloc] init];
    types = [[NSMutableArray alloc] init];
    properties = [[NSMutableArray alloc] init];
    objectIDs = [[NSMutableArray alloc] init];
    objectNames = [[NSMutableArray alloc] init];
    
    [queryResultTableView setDataSource:self];
    [queryResultTableView setDelegate:self];
    queryResultTableView.usesAlternatingRowBackgroundColors = YES;
    while (queryResultTableView.tableColumns.count > 0) {
        [queryResultTableView removeTableColumn:queryResultTableView.tableColumns.lastObject];
    }
    NSTableColumn * column1 = [[NSTableColumn alloc] initWithIdentifier:@"col_1"];
    NSTableColumn * column2 = [[NSTableColumn alloc] initWithIdentifier:@"col_2"];
    [column1.headerCell setStringValue:@"Entity ID"];
    [column2.headerCell setStringValue:@"Name"];
    [column1 setWidth:100];
    [column2 setWidth:482];
    [queryResultTableView addTableColumn:column1];
    [queryResultTableView addTableColumn:column2];
    [queryResultTableView reloadData];
    lastSelectedRow = queryResultTableView.selectedRow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
    if (flag) {
        [self.mainWindow orderFront:self];
    } else {
        [self.mainWindow makeKeyAndOrderFront:self];
    }
    return YES;
}

- (IBAction)connectSSH:(id)sender {
    [currentState setStringValue:@"Connecting..."];
    session = [NMSSHSession connectToHost:hostAddress.stringValue
                             withUsername:userName.stringValue];
    if (session.isConnected) {
        [currentState setStringValue:@"Connected"];
        [session authenticateByPassword:password.stringValue];
        if (session.isAuthorized) {
            [currentState setStringValue:@"Authentication Succeeded"];
        } else {
            [currentState setStringValue:@"Authentication Failed"];
        }
    }
}

- (IBAction)disconnectSSH:(id)sender {
    if (session == nil) {
        return;
    }
    [session disconnect];
    session = nil;
    [currentState setStringValue:@"Not Connected"];
}

- (IBAction)run:(id)sender {
    if (session == nil) {
        [currentState setStringValue:@"Please Connect First"];
        return;
    }
    NSError *error = nil;
    NSString *response = [session.channel execute:command.stringValue error:&error];
    [result setStringValue:response];
}

- (IBAction)clearResult:(id)sender {
    [result setStringValue:@""];
}


- (IBAction)toggleDrawer:(id)sender {
    [self.sshToolsPanel makeKeyAndOrderFront:nil];
}

- (void)parseResponse:(NSString *)response {
    NSArray *lines;
    NSArray *cols;
    switch (typeOfQuery.indexOfSelectedItem) {
        case 0:
            [entityIDs removeAllObjects];
            [names removeAllObjects];
            lines = [response componentsSeparatedByString:@"\n"];
            for (int i = 1; i < lines.count - 1; i++) {
                cols = [[lines objectAtIndex:i] componentsSeparatedByString:@"\t"];
                [entityIDs addObject:[cols objectAtIndex:0]];
                [names addObject:[cols objectAtIndex:1]];
            }
            if (entityIDs.count == 0) {
                [noResults setHidden:NO];
            } else {
                [noResults setHidden:YES];
            }
            break;
        
        case 1:
            [types removeAllObjects];
            lines = [response componentsSeparatedByString:@"\n"];
            for (int i = 1; i < lines.count - 1; i++) {
                [types addObject:[lines objectAtIndex:i]];
            }
            if (types.count == 0) {
                [noResults setHidden:NO];
            } else {
                [noResults setHidden:YES];
            }
            break;
        
        case 2:
            [properties removeAllObjects];
            lines = [response componentsSeparatedByString:@"\n"];
            for (int i = 1; i < lines.count - 1; i++) {
                [properties addObject:[lines objectAtIndex:i]];
            }
            if (properties.count == 0) {
                [noResults setHidden:NO];
            } else {
                [noResults setHidden:YES];
            }
            break;
            
        default:
            break;
    }
}

- (IBAction)sendQuery:(id)sender {
    if ([NSString isStringEmpty:query.stringValue]) {
        return;
    }
    if (session == nil) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"No Connection"];
        [alert setInformativeText:@"Use the SSH Tools to connect to the database."];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    } else {
        NSString *sqlCommand;
        switch (typeOfQuery.indexOfSelectedItem) {
            case 0:
                sqlCommand = [NSString stringWithFormat:@"mysql -u fb -D freebase -e \"select id, name from idnamecount where match (name) against ('+%@' in boolean mode) order by count desc limit 20;\"", query.stringValue];
                break;
            
            case 1:
                sqlCommand = [NSString stringWithFormat:@"mysql -u fb -D freebase -e \"select type from idtype where id = '%@';\"", query.stringValue];
                break;
            
            case 2:
                sqlCommand = [NSString stringWithFormat:@"mysql -u fb -D freebase -e \"select property from propertyschema, idtype where idtype.id = '%@' and propertyschema.the_schema = idtype.type union select property from propertyexpectedtype, idtype where idtype.id = '%@' and propertyexpectedtype.expected = idtype.type;\"", query.stringValue, query.stringValue];
                
            default:
                break;
        }
        NSError *error = nil;
        NSString *response = [session.channel execute:sqlCommand error:&error];
        [self parseResponse:response];
        [queryResultTableView reloadData];
    }
}

- (IBAction)chooseQueryType:(id)sender {
    switch (typeOfQuery.indexOfSelectedItem) {
        case 0:
            [query.cell setPlaceholderString:@"Input a name, and press Enter."];
            [[[queryResultTableView tableColumnWithIdentifier:@"col_1"] headerCell] setStringValue:@"Entity ID"];
            [[[queryResultTableView tableColumnWithIdentifier:@"col_2"] headerCell] setStringValue:@"Name"];
            [[queryResultTableView tableColumnWithIdentifier:@"col_1"] setWidth:100];
            [[queryResultTableView tableColumnWithIdentifier:@"col_2"] setWidth:482];
            [queryResultTableView reloadData];
            [noResults setHidden:YES];
            break;
        
        case 1:
            [query.cell setPlaceholderString:@"Input an entity ID, and press Enter."];
            [[[queryResultTableView tableColumnWithIdentifier:@"col_1"] headerCell] setStringValue:@"Type"];
            [[[queryResultTableView tableColumnWithIdentifier:@"col_2"] headerCell] setStringValue:@""];
            [[queryResultTableView tableColumnWithIdentifier:@"col_1"] setWidth:450];
            [[queryResultTableView tableColumnWithIdentifier:@"col_2"] setWidth:132];
            [queryResultTableView reloadData];
            [noResults setHidden:YES];
            break;
        
        case 2:
            [query.cell setPlaceholderString:@"Input an entity ID, and press Enter."];
            [[[queryResultTableView tableColumnWithIdentifier:@"col_1"] headerCell] setStringValue:@"Property"];
            [[[queryResultTableView tableColumnWithIdentifier:@"col_2"] headerCell] setStringValue:@""];
            [[queryResultTableView tableColumnWithIdentifier:@"col_1"] setWidth:450];
            [[queryResultTableView tableColumnWithIdentifier:@"col_2"] setWidth:132];
            [queryResultTableView reloadData];
            [noResults setHidden:YES];
            break;
            
        default:
            break;
    }
}

- (IBAction)clearTableResult:(id)sender {
    [entityIDs removeAllObjects];
    [names removeAllObjects];
    [types removeAllObjects];
    [properties removeAllObjects];
    [objectIDs removeAllObjects];
    [objectNames removeAllObjects];
    [queryResultTableView reloadData];
    [noResults setHidden:YES];
}

- (IBAction)selectRow:(id)sender {
    NSInteger selectedRow = queryResultTableView.selectedRow;
    if (lastSelectedRow != -1 && lastSelectedRow != selectedRow) {
        for (int i = 0; i < queryResultTableView.numberOfColumns; i++) {
            NSTextField *textField = [queryResultTableView viewAtColumn:i row:lastSelectedRow makeIfNecessary:NO];
            [textField setTextColor:[NSColor controlTextColor]];
        }
    }
    if (selectedRow != -1) {
        for (int i = 0; i < queryResultTableView.numberOfColumns; i++) {
            NSTextField *textField = [queryResultTableView viewAtColumn:i row:selectedRow makeIfNecessary:NO];
            [textField setTextColor:[NSColor alternateSelectedControlTextColor]];
        }
        lastSelectedRow = selectedRow;
    }
}
@end
