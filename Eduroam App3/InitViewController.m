/* InitViewContorller.m
 * Created by: Ashley Browning
 * Created on: 19/03/2011
 * Version: v1.00 (19/03/2011)
 *
 * This View Controller will display the first time message to the user, start a 
 * check for whether the database exists in the documents folder
 *
 */




//
//  InitViewController.m
//  Eduroam App3
//
//  Created by Ashley Browning on 19/03/2011.
//  Copyright 2011 The JNT Association. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//      * Redistributions of source code must retain the above copyright
//        notice, this list of conditions and the following disclaimer.
//      * Redistributions in binary form must reproduce the above copyright
//        notice, this list of conditions and the following disclaimer in the
//        documentation and/or other materials provided with the distribution.
//      * Neither the name of the The JNT Association, TERENA, The University of 
//        Southampton nor the names of its contributors may be used to endorse or
//        promote products derived from this software without specific prior
//        written permission.
// 
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE JNT ASSOCIATION BE LIABLE FOR ANY
//  DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "InitViewController.h"
#import "eduroamCompanionAppDelegate.h"
#import "DatabaseManager.h"

#import <CommonCrypto/CommonDigest.h>
#import "LoadOverlay.h"


@interface InitViewController () {
    
    LoadOverlay* loadOverlay;
    DatabaseManager* dbManager;
    
    NSString* startKey;
    
    UIAlertView* dbUpdateAlert;
    BOOL waitingForPermission;
    BOOL waitingForUpdate;
    BOOL forcedDBUpdate;
    int databaseSize;
    NSThread* updateThread;
    NSAutoreleasePool *pool;
    BOOL finished;
    
    int rowCount;
    int processCount;
}

- (NSString*) documentsPath;
- (NSString*) readFromFile:(NSString*)filePath;
- (void) writeToFile:(NSString*)text withFileName:(NSString*)filePath;
- (void) startUpdate;
- (NSString*) sha1Digest:(NSString*)input;
- (NSString*) rot13String:(NSString*)input;
- (void)databaseVersionCheck:(NSMutableDictionary*)dictionary;
- (void)getNewDatabase;
- (void) startDynamicUpdate;
- (void)finishStage:(int)stage;
- (void)doDynamicUpdating:(NSMutableDictionary*)dictionary;
- (void)continueToMainApp;
- (void)displayDownloadMessage;
- (void)inThreadInitialisation;
- (void)updateText;
- (void)displayProgressBar;



@end



@implementation InitViewController

@synthesize appdelegate;
@synthesize dbURL;
@synthesize jsonDBcheck;
@synthesize statusLabel;
@synthesize progressBar;

//------------------------------------------------------------
// Is not called due to ApplicaitonDelegate doing other things
//------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        
    }
    return self;
}


//------------------------------------------------------------
// Initialise variables and check database
//------------------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    ///////////////
    //VARIABLE INIT
    ///////////////
    dbManager = [DatabaseManager sharedDatabaseManager];
    jsonDBcheck = [NetworkManager getJSONObject:@"https://eduroam-app-api.dev.ja.net/v1.0/live/database.php" withDelegate:self];
    [jsonDBcheck retain];
    startKey = @""; // Device/Build API Key
    self.dbURL = nil;
    databaseSize = 0;
    waitingForPermission = NO;
    waitingForUpdate = YES;
    forcedDBUpdate = NO;
    finished = NO;
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background1.png"]];
    
    //See if a plist exists in the directory folder
    NSString* userPList = [[self documentsPath] stringByAppendingPathComponent:@"user.plist"];
    
    //If the PList cannot be found, then this is a first time load
    if (![[NSFileManager defaultManager] fileExistsAtPath:userPList]){
        waitingForPermission = YES;
        
        
        
        //Display a first time message about tagging
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"Permission To Tag" 

                                                        message:@"To improve the accuracy of the database powering this application, you can choose to 'tag' your current location.\nThis information will be used to better map eduroam-enabled sites, improving the app for all users.\nIf you consent to this feature being enabled, please click \"allow\" below." 
                                                       delegate:self 
                                              cancelButtonTitle:@"Allow" 
                                              otherButtonTitles:@"Disallow",nil];
        
        [error show];
        [error release];
        
        
    }
    
    //[NSThread detachNewThreadSelector:@selector(inThreadInitialisation) toTarget:self withObject:nil];
    updateThread = [[NSThread alloc] initWithTarget:self selector:@selector(inThreadInitialisation) object:nil];
    [updateThread start];
    //[self inThreadInitialisation];

}   

- (void)inThreadInitialisation {
    
    pool = [[NSAutoreleasePool alloc] init]; 

    

    NSLog(@"In here!");
    
    

    
    
    
    
    
    [self startUpdate];
    
    while(!finished) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    [pool release];
	
    
	//[NSThread exit];
    
}


//- (void)viewWillAppear:(BOOL)animated{
//    [super viewWillAppear:animated];
//
//
//}

//------------------------------------
// Check the database 
//------------------------------------
- (void)startUpdate{
    
    //Update the status label
    self.statusLabel.text = @"Checking Database Version";
    
    NSLog(@"Starting update");
    
    //Check that it hasn't been done already today
    NSString* query = @"SELECT strftime(\"%s\", lastUpdate), baseversion FROM Info";
    NSDictionary* data = [dbManager selectQuery:query andColumnTypes:@"ii"];
    if([[data objectForKey:@"error"] intValue] != 0){
        NSLog(@"Error occured checking date of last update");
        [self finishStage:2];
        return;
    }
    
    data = [data objectForKey:[NSNumber numberWithInt:0]];
    

    NSDate* lastUpdate = [NSDate dateWithTimeIntervalSince1970:[[data objectForKey:[NSNumber numberWithInt:0]] doubleValue]]; 
    
    NSUInteger desiredComponents = NSEraCalendarUnit|NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit;
    NSDateComponents *myCalendarDate = [[NSCalendar currentCalendar] components:desiredComponents fromDate:lastUpdate];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:desiredComponents fromDate:[NSDate date]];
    
    //Check if an update was attempted today already
    //Does not work, init screen sticks, probably trying to load a new thing without getting rid of the old one
    if ([myCalendarDate isEqual:today]) {
        //No need to update
        NSLog(@"Already updated today");
        [self finishStage:3];
        return;
    }
    
    //Need to update, so check the database version first
    int version = [[data objectForKey:[NSNumber numberWithInt:1]] intValue];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[self rot13String:startKey] forKey:@"key"];
    [parameters setObject:[NSString stringWithFormat:@"%d", version] forKey:@"version"];
    
    int outcome = [jsonDBcheck getJSON:@"dbversion" withParameters:parameters];
    switch (outcome) {
        case 0:
            //Success
            break;
        case 1:
            //There is no internet connection so start the main app
            [self finishStage:4];
            return;
            break;
        default:
            [self finishStage:5];
            break;
    }
    
    //Check the database version
    
    //check the site and subsite concurrently if possible
    
    
}

#pragma mark - Dynamic Update
//---------------------------------------------
// Update the site and subsite data from server
//---------------------------------------------
- (void) startDynamicUpdate{
    
    //Get the oldest date in the tables
    NSString* query = @"SELECT strftime(\"%s\", lastUpdate) FROM Site ORDER BY lastUpdate ASC LIMIT 1";
    NSDictionary* data = [dbManager selectQuery:query andColumnTypes:@"i"];
    if([[data objectForKey:@"error"] intValue] != 0){
        NSLog(@"Error occured checking date of last update");
        [self finishStage:12];
        return;
    }
    
    data = [data objectForKey:[NSNumber numberWithInt:0]];
    int siteLastUpdate = [[data objectForKey:[NSNumber numberWithInt:0]] intValue];
    
    query = @"SELECT strftime(\"%s\", lastUpdate) FROM SubSites ORDER BY lastUpdate ASC LIMIT 1";
    data = [dbManager selectQuery:query andColumnTypes:@"i"];
    if([[data objectForKey:@"error"] intValue] != 0){
        NSLog(@"Error occured checking date of last update");
        [self finishStage:13];
        return;
    }
    
    data = [data objectForKey:[NSNumber numberWithInt:0]];
    int subsiteLastUpdate = [[data objectForKey:[NSNumber numberWithInt:0]] intValue];
    
    int date;
    if (siteLastUpdate < subsiteLastUpdate){
        date = siteLastUpdate;
    } else {
        date = subsiteLastUpdate;
    }
    
    //NSLog(@"Date being submitted:%d", date);
    
    //submit to server
    jsonDBcheck.urlstring = @"https://eduroam-app-api.dev.ja.net/v1.0/live/siteUpdate.php";
    jsonDBcheck.returnDict = YES;
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[self rot13String:startKey] forKey:@"key"];
    [parameters setObject:[NSString stringWithFormat:@"%d", date] forKey:@"date"];
    [parameters setObject:[NSString stringWithFormat:@"%d", 500] forKey:@"size"];       //Maximum number of updates that can be returned is 500. This is to prevent it taking a long time to update

    
    int outcome = [jsonDBcheck getJSON:@"sites" withParameters:parameters];
    switch (outcome) {
        case 0:
            //Success
            NSLog(@"Successfully sent");
            break;
        case 1:
            [self finishStage:14];
            return;
            break;
        default:
            break;
    }
    
}

//----------------------------------
// conduct the dynamic updating here
//----------------------------------
-(void)doDynamicUpdating:(NSMutableDictionary*)dictionary{
    //NSLog(@"data:%@", dictionary);
    
    self.statusLabel.text = @"Dynamically Updating - Please Wait";
    
    //check for success
    int rcode = [[[dictionary objectForKey:@"rcode"] objectForKey:@"code"] intValue];
    
    if(rcode == 50){
        NSLog(@"Too many records, attempt to get DB file");
        forcedDBUpdate = YES;
        [self finishStage:24];
        return;
    }
    
    if(rcode != 0){
        NSLog(@"Error getting the json");
        [self finishStage:15];
        return;
    }
    
    //See how many operations there are, then consider downloading the sqlite file
    rowCount = [[[dictionary objectForKey:@"site"] objectForKey:@"insert"] count];
    rowCount = rowCount + [[[dictionary objectForKey:@"site"] objectForKey:@"delete"] count];
    rowCount = rowCount + [[[dictionary objectForKey:@"site"] objectForKey:@"update"] count];
    rowCount = rowCount + [[[dictionary objectForKey:@"subsite"] objectForKey:@"delete"] count];
    rowCount = rowCount + [[[dictionary objectForKey:@"subsite"] objectForKey:@"update"] count];
    rowCount = rowCount + [[[dictionary objectForKey:@"subsite"] objectForKey:@"insert"] count];
    //NSLog(@"size of update: %d", number);
    
    //NSLog(@"Start of dynamic update: %@", [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000]);
//    
//    if (number > 500){
//        NSLog(@"Too many operations, get a new database");
//        forcedDBUpdate = YES;
//        [self finishStage:23];
//        return;
//    }
    
    //Get the date
    int date = [[dictionary objectForKey:@"date"] intValue];
    processCount = 0;
    [self performSelectorOnMainThread:@selector(displayProgressBar) withObject:nil waitUntilDone:NO];
    //go through each thing and conduct the operations
    //Site insert
    NSString* query = @"INSERT INTO Site (id, name, lastUpdate) VALUES (?, ?, datetime(?, 'unixepoch'))";
    NSMutableArray* parameters = [NSMutableArray array];
    //NSEnumerator* e = [[[dictionary objectForKey:@"site"] objectForKey:@"insert"] keyEnumerator];
    NSDictionary* data = [[dictionary objectForKey:@"site"] objectForKey:@"insert"];
    NSEnumerator* e = [data keyEnumerator];
    id _id;
    [self performSelectorOnMainThread:@selector(updateText) withObject:nil waitUntilDone:NO];
    while ((_id = [e nextObject])) {
        [parameters removeAllObjects];
        [parameters addObject:_id];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"name"]];
        [parameters addObject:[NSNumber numberWithInt:date]];
        
        int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"isi"];
        processCount++;
        [self performSelectorOnMainThread:@selector(updateText) withObject:nil waitUntilDone:NO];
        if (outcome != 0) {
            NSLog(@"Site Insert failed");
            continue;
        }
    }
    
    
    //Site Update
    query = @"UPDATE Site SET name=?, lastUpdate=datetime(?, 'unixepoch') WHERE id = ?";
    data = [[dictionary objectForKey:@"site"] objectForKey:@"update"];
    e = [data keyEnumerator];
    while ((_id = [e nextObject])) {
        [parameters removeAllObjects];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"name"]];
        [parameters addObject:[NSNumber numberWithInt:date]];
        [parameters addObject:_id];
        
        int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"sii"];
        processCount++;
        [self performSelectorOnMainThread:@selector(updateText) withObject:nil waitUntilDone:NO];
        if (outcome != 0) {
            NSLog(@"Site Update failed:%d", outcome);
            continue;
        }

    }

    
    //Site Delete
    query = @"DELETE FROM Site WHERE id = ?";
    NSArray* arraydata = [[dictionary objectForKey:@"site"] objectForKey:@"delete"];
    e = [arraydata objectEnumerator];
    while ((_id = [e nextObject])) {
        [parameters removeAllObjects];
        [parameters addObject:_id];
        
        //int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"sii"];
        int outcome = [dbManager deleteQuery:query withParameters:parameters ofTypes:@"i"];
        processCount++;
        [self performSelectorOnMainThread:@selector(updateText) withObject:nil waitUntilDone:NO];
        if (outcome != 0) {
            NSLog(@"Site delete failed:%d", outcome);
            continue;
        }

    }

    
    //Subsite Insert
    query = @"INSERT INTO SubSites (id, site, name, address, lat, lng, altitude, ssid, encryption, accesspoints, lastUpdate) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, datetime(?, 'unixepoch'))";
    data = [[dictionary objectForKey:@"subsite"] objectForKey:@"insert"];
    e = [data keyEnumerator];
    while ((_id = [e nextObject])) {
        [parameters removeAllObjects];
        [parameters addObject:_id];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"site"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"name"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"address"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"lat"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"lng"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"altitude"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"ssid"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"encryption"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"accesspoints"]];
        [parameters addObject:[NSNumber numberWithInt:date]];
        
        
        int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"iissdddssii"];
        processCount++;
        [self performSelectorOnMainThread:@selector(updateText) withObject:nil waitUntilDone:NO];
        if (outcome != 0) {
            NSLog(@"subSite insert failed:%d", outcome);
            continue;
        }

    }

    //Subsite update
    query = @"UPDATE SubSites SET site=?, name=?, address=?, lat=?, lng=?, altitude=?, ssid=?, encryption=?, accesspoints=?, lastUpdate=datetime(?, 'unixepoch') WHERE id=?";
    data = [[dictionary objectForKey:@"subsite"] objectForKey:@"update"];
    e = [data keyEnumerator];
    while ((_id = [e nextObject])) {
        [parameters removeAllObjects];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"site"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"name"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"address"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"lat"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"lng"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"altitude"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"ssid"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"encryption"]];
        [parameters addObject:[[data objectForKey:_id] objectForKey:@"accesspoints"]];
        [parameters addObject:[NSNumber numberWithInt:date]];
        [parameters addObject:_id];

        
        int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"issdddssiii"];
        //NSLog(@"subsite update outcome:%d", outcome);
        processCount++;
        [self performSelectorOnMainThread:@selector(updateText) withObject:nil waitUntilDone:NO];
        if (outcome != 0) {
            NSLog(@"subSite update failed:%d", outcome);
            continue;
        }

    }

    //subsite delete
    
    //delete the accesspoints related to it
    NSString* apquery = @"DELETE FROM APs WHERE subsite = ?";
    query = @"DELETE FROM SubSites WHERE id = ?";
    arraydata = [[dictionary objectForKey:@"subsite"] objectForKey:@"delete"];
    e = [arraydata objectEnumerator];
    while ((_id = [e nextObject])) {
        [parameters removeAllObjects];
        [parameters addObject:_id];
        
        //int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"sii"];
        int outcome = [dbManager deleteQuery:query withParameters:parameters ofTypes:@"i"];
        if (outcome != 0) {
            NSLog(@"subSite delete failed:%d", outcome);
            continue;
        }
        
        outcome = [dbManager deleteQuery:apquery withParameters:parameters ofTypes:@"i"];
        processCount++;
        [self performSelectorOnMainThread:@selector(updateText) withObject:nil waitUntilDone:NO];
        if (outcome != 0) {
            NSLog(@"subSite ap delete failed:%d", outcome);
            continue;
        }
    }
    

    
    //update all the fields in the database to the current time
    query = @"UPDATE Site SET lastUpdate = datetime(?, 'unixepoch')";
    [parameters removeAllObjects];
    [parameters addObject:[NSNumber numberWithInt:date]];
    int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"i"];
    NSLog(@"mass site update outcome:%d", outcome);
    
    query = @"UPDATE SubSites SET lastUpdate = datetime(?, 'unixepoch')";
    outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"i"];
    NSLog(@"mass subsite update outcome:%d", outcome);

    NSLog(@"End of dynamic update: %@", [NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970] * 1000]);

    //Done dynamic updating,
    [self finishStage:16];
    
}


-(void)displayProgressBar{
    self.progressBar.hidden = NO;
}


-(void)updateText{
    
    
    self.progressBar.progress = ((float)processCount/(float)rowCount);
    self.statusLabel.text = [NSString stringWithFormat:@"Dynamic Update - %d/%d", processCount, rowCount];
}

#pragma mark - Database Version Checks

//---------------------------------------------------------------
// Got data from server, check if new database download is needed
//---------------------------------------------------------------
- (void)databaseVersionCheck:(NSMutableDictionary*)dictionary{
    
    databaseSize = [[dictionary objectForKey:@"size"] intValue] / 1000;
    //Store the path in the global variable for later
    self.dbURL = [dictionary objectForKey:@"path"];
    
    //If a zero, then everything is up to date
    if ([[[dictionary objectForKey:@"rcode"] objectForKey:@"code"] intValue] == 0) {
        [self finishStage:6];
        return;
    } 
    
    
    
    if ([[[dictionary objectForKey:@"rcode"] objectForKey:@"code"] intValue] == 1) {
        

        [self displayDownloadMessage];
        

    }
}

//Display a message to the user whether they would like to update
- (void)displayDownloadMessage{
    NSString* message = [NSString stringWithFormat:@"An update of size %dKB is available. Would you like to download it now?", databaseSize];
    
    UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"Database Update" 
                                                    message:message  
                                                   delegate:self 
                                          cancelButtonTitle:@"Yes" 
                                          otherButtonTitles:@"No",nil];
    
    [error show];
    [error release];
}

// Get a new database file from the server
- (void)getNewDatabase{
    
    NSLog(@"in database: %@", dbURL);
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[self rot13String:startKey] forKey:@"key"];
    jsonDBcheck.returnDict = NO;
    jsonDBcheck.urlstring = @"https://eduroam-app-api.dev.ja.net/v1.0/live/getdb.php";
    int outcome = [jsonDBcheck getJSON:@"downloaddb" withParameters:parameters];
    switch (outcome) {
        case 0:
            //Success
            NSLog(@"Successfully sent");
            break;
        case 1:
            [self finishStage:9];
            return;
            break;
        default:
            break;
    }
    
    
}

#pragma mark - JSON Delegate Methods

// Got JSON data back from the server
- (void)receiveJSONDictionary:(NSMutableDictionary*)dictionary withID:(NSString*)identifier{
    //NSLog(@"received data: %@:%@", identifier, dictionary);
    
    //Got data back from the database version check
    if ([identifier isEqualToString:@"dbversion"]){
        [self databaseVersionCheck:dictionary];
    }
    
    if ([identifier isEqualToString:@"sites"]){
        [self doDynamicUpdating:dictionary];
    }
}

// Problem with contacting the server
- (void)receiveConnectionError:(NSString*)identifier{
    NSLog(@"connection error for %@", identifier);
    
    if ([identifier isEqualToString:@"dbversion"]){
        [self finishStage:17];
    }
    
    if ([identifier isEqualToString:@"sites"]){
        [self finishStage:18];
    }
    
    if ([identifier isEqualToString:@"downloaddb"]){
        [self finishStage:19];
    }
}

// Problem with the message received back
- (void)receiveJSONError:(NSString*)identifier{
    NSLog(@"json error for %@", identifier);
    
    if ([identifier isEqualToString:@"dbversion"]){
        [self finishStage:20];
    }
    
    if ([identifier isEqualToString:@"sites"]){
        [self finishStage:21];
    }
}

//Get raw data
- (void)receiveData:(NSMutableData*)data withID:(NSString*)identifier{
    
    //If it is database that has just been downloaded, copy across
    if ([identifier isEqualToString:@"downloaddb"]){
        //NSLog(@"got the downloaddb data!");
        
        int outcome = [dbManager overwriteDatabase:data];
        NSLog(@"Outcome of overwrite op: %d", outcome);
        if (outcome == 0){
            [self finishStage:10];
        } else {
            [self finishStage:11];
        }
    }
}


// Save the data to the file
- (void)saveData:(NSData*)data{
    
    
}

//When a stage has finished, send a code to this bit to determine whats next
- (void)finishStage:(int)stage{
    
    switch (stage) {
        case 0:
            //
            break;
        case 1:
            //
            break;
        case 2:
            //Error checking the date of the last update
            //Proceed to main app
            waitingForUpdate = NO;
            self.statusLabel.text = @"Error Updating";
            [self continueToMainApp];
            break;
        case 3:
            //An update has already taken place today, continue to main app
            waitingForUpdate = NO;
            self.statusLabel.text = @"All Up To Date";
            [self continueToMainApp];
            break;
        case 4:
            //There is no internet from database version check
            //proceed to main app
            self.statusLabel.text = @"Error: No Internet Connection";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 5:
            //something bad happened with the databsae version check
            //contine to main app
            self.statusLabel.text = @"Error Updating";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 6:
            //just checked the database, move onto dynamic updating
            self.statusLabel.text = @"Checking For Dynamic Updates";
            [self startDynamicUpdate];
            break;
        case 7:
            //User has given permission to get a new database
            [self getNewDatabase];
            break;
        case 8:
            //User has NOT given permission to get a new database
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 9:
            //No internet connection to download the new database
            self.statusLabel.text = @"Error: No Internet Connection";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 10:
            //Just successfully downloaded a new database, start dynamic
            if (forcedDBUpdate) {
                waitingForUpdate = NO;
                self.statusLabel.text = @"Successfully Updated";
                [self continueToMainApp];
            } else {
                self.statusLabel.text = @"Checking For Dynamic Updates";
                [self startDynamicUpdate];
            }
            break;
        case 11:
            //Failed to update the database, continue to main app
            self.statusLabel.text = @"Error Updating Database";
            waitingForUpdate = NO;
            [self continueToMainApp];
        case 12:
            //Failed to get the lastupdate date of the sites table
            self.statusLabel.text = @"Error Updating";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 13:
            //FAiled to get the lastupdate date of the subsite table
            self.statusLabel.text = @"Error Updating";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 14:
            //No internet connectivity to get the dynamic update
            self.statusLabel.text = @"Error: No Internet Connection";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 15:
            //Error getting dynamic JSON,
            self.statusLabel.text = @"Error With Server";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 16:
            //Done dynamic updating, so move on to main app
            self.statusLabel.text = @"Successfully Updated";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 17:
            //connection error for checking the database version
            self.statusLabel.text = @"Error: Connection Problems";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 18:
            //connection error for getting the dynamic update
            self.statusLabel.text = @"Error: Connection Problems";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 19:
            //connection error for getting the database file
            self.statusLabel.text = @"Error: Connection Problems";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 20:
            //JSON error getting the database version information
            self.statusLabel.text = @"Error With Server";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 21:
            //JSON error getting the dynamic site update
            self.statusLabel.text = @"Error With Server";
            waitingForUpdate = NO;
            [self continueToMainApp];
            break;
        case 22:
            //Reponse received from user, moving onto main application
            waitingForPermission = NO;
            [self continueToMainApp];
            break;
        case 23:
            self.statusLabel.text = @"Obtaining New Database";
            [self displayDownloadMessage];
            break;
        case 24:
            //Too many records for a dynamic update
            self.statusLabel.text = @"Obtaining New Database";
            [self displayDownloadMessage];            
            break;
        default:
            break;
    }
    
    
}

//--------------------------------------------------------------------------------
// This view is done, load the main application if not waiting for user permission
//--------------------------------------------------------------------------------
- (void)continueToMainApp{
    NSLog(@"Attempting to move to new view");
    if(!waitingForPermission && !waitingForUpdate){
        if(appdelegate != nil){
            finished = YES;
            [appdelegate performSelectorOnMainThread:@selector(initDone) withObject:nil waitUntilDone:NO];
            //[pool release];
            [updateThread cancel];
            if([[NSThread currentThread] isCancelled]){
                [NSThread exit];
            }
        }
    }
}

//--------------------------
//Deal with alert view input
//--------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    //If database update
    if ([alertView.title isEqualToString: @"Database Update"]){
        switch (buttonIndex) {
            case 0:
                [self finishStage:7];
                break;
            case 1:
                [self finishStage:8];
                break;
            default:
                break;
        }
    }
    
    if ([alertView.title isEqualToString:@"Permission To Tag"]){
        switch (buttonIndex) {
            case 0:{
                NSLog(@"Allow");
                waitingForPermission = NO;
                //Set the value in the preferences
                NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:[NSNumber numberWithInt:1] forKey:@"permission"];
            }
                break;
            case 1:{
                NSLog(@"Disallow");
                //Set the value in the preferences
                NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:[NSNumber numberWithInt:0] forKey:@"permission"];
                

                waitingForPermission = NO;
            }
                break;
            default:
                break;
        }
        
        NSString* userPList = [[self documentsPath] stringByAppendingPathComponent:@"user.plist"];

        NSMutableDictionary* userDetails = [NSMutableDictionary dictionary];
        
        NSString* udid = [[UIDevice currentDevice] uniqueIdentifier];
        NSString* salt = [NSString stringWithFormat:@"%d", arc4random()];
        NSString* hashSeed = [udid stringByAppendingString:salt];
        NSString* hashID = [self sha1Digest:hashSeed];
        
        [userDetails setObject:salt forKey:@"salt"];
        [userDetails setObject:hashID forKey:@"hashID"];
        [userDetails setObject:@"No" forKey:@"confirmedID"];
        
        [userDetails writeToFile:userPList atomically:YES];
        
        [self finishStage:22];
    }

}

//Deal with the user's decision to give permission to tag or not
- (void)setUserPermission:(BOOL)permissionGiven{
    
    
    
    //When done, go to the finished method
    [self finishStage:22];
}

//----------------------------------------------------------
//Input a string, run thrugh SHA-1 cryptohash, output result
//----------------------------------------------------------
- (NSString*) sha1Digest:(NSString*)input{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
}

//-------------------------------------------
// Run rot13 on the keyseed
//-------------------------------------------
-(NSString *) rot13String:(NSString*)input{
	const char *_string = [input cStringUsingEncoding:NSASCIIStringEncoding];
	int stringLength = [input length];
	char newString[stringLength+1];
	
	int x;
	for( x=0; x<stringLength; x++ )
	{
		unsigned int aCharacter = _string[x];
		
		if( 0x40 < aCharacter && aCharacter < 0x5B ) // A - Z
			newString[x] = (((aCharacter - 0x41) + 0x0D) % 0x1A) + 0x41;
		else if( 0x60 < aCharacter && aCharacter < 0x7B ) // a-z
			newString[x] = (((aCharacter - 0x61) + 0x0D) % 0x1A) + 0x61;
		else  // Not an alpha character
			newString[x] = aCharacter;
	}
	
	newString[x] = '\0';
	
	NSString *rotString = [NSString stringWithCString:newString encoding:NSASCIIStringEncoding];
	return( rotString );
}



#pragma mark - File I/O
//-------------------------------------
// Get the path to the documents folder
//-------------------------------------
- (NSString*) documentsPath{
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsDir = [paths objectAtIndex:0];
    
    return documentsDir;
}

//------------------------------
// Read the contents of the file
//------------------------------
- (NSString*) readFromFile:(NSString*)filePath{
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        NSArray* array = [[NSArray alloc] initWithContentsOfFile: filePath];
        NSString* data = [[[NSString alloc] initWithFormat:@"%@", [array objectAtIndex:0]] autorelease];
        [array release];
        return data;
    } else {
        return nil;
    }
}

//----------------------------------
// Write to a specific file
//----------------------------------
- (void) writeToFile:(NSString*)text withFileName:(NSString*)filePath{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    [array addObject:text];
    [array writeToFile:filePath atomically:YES];
    [array release];
}






#pragma mark - Database





#pragma mark - Actions

- (IBAction)confirm:(id)sender{
    NSLog(@"Confriming");
    [self continueToMainApp];
}





#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.

*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}





#pragma mark - Destruction & Housekeeping
- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}
@end
