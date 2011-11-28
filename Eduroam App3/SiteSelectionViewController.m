//
//  SiteSelectionViewController.m
//  Eduroam App3
//
//  Created by Ashley Browning on 18/03/2011.
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

#import "SiteSelectionViewController.h"
#import "SiteDetailsViewController.h"
#import "SiteAnnotation.h"
#import "APAnnotations.h"
#import "DatabaseManager.h"

#import "sqlite3.h"
#import "LocationManager.h"
#import "YouAreHereAnnotation.h"



@implementation SiteSelectionViewController

@synthesize mapView;
@synthesize secondView;
@synthesize firstView;
@synthesize tableView;
@synthesize searchBarTable;
@synthesize searchBarMap;
@synthesize eduroamDarkBlue;
@synthesize updating;
@synthesize previousUpdateRegion;
@synthesize jsonUpdateAP;
@synthesize jsonSearch;
@synthesize nearestSites;

//CONSTANTS
double EARTH_RADIUS = 6371;

//These zoom constants should be used for the longitude only
double SITE_ZOOM_MAX = 4.0;
double AP_ZOOM_MAX = 0.06;
double AP_UPDATE_ZOOM_MAX = 0.075;
CLLocationDistance AP_RANGE = 20;
int NUMBER_OF_NEAREST_SITES = 10;


SiteDetailsViewController* siteView;
DatabaseManager* dbManager;
LocationManager* locationManager;
NetworkManager* networkManager;
YouAreHereAnnotation* currentLocation = nil;
NetworkJSON* json;

UIImage* siteMarker;
UIImage* apMarker;
double latSearchSpan = 10;
double lngSearchSpan = 10;
NSMutableArray* searchResults;

//RUNTIME STATES
BOOL TABLE_NO_LOCATION_ALERT = NO;  //Describes whether the alert view for the table view has appeared when there is no location data available

#pragma mark - Initialisation

//-------------------------------------------------------------------
// This will initialise the view using the basic initialisation stuff
//-------------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    //None of this is called because of the way the view is set up
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}


//----------------------------------------------------------
// Set up map
//----------------------------------------------------------
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    //NSLog(@"Loading the main view");
    /////////////////////////
    //VARIABLE INITIALISATION
    /////////////////////////
    dbManager = [DatabaseManager sharedDatabaseManager];
    locationManager = [LocationManager sharedLocationManager];
    locationManager.manager.delegate = self;
    [locationManager.manager startUpdatingLocation];
    tableView.delegate = self;
    updating = NO;
    self.jsonUpdateAP = [NetworkManager getJSONObject:@"https://eduroam-app-api.dev.ja.net/v1.0/live/apUpdate.php" withDelegate:self];
    self.jsonSearch = [NetworkManager getJSONObject:@"https://maps.googleapis.com/maps/api/geocode/json" withDelegate:self];
    startKey = @"hVKPZAghhSfZJfFybmiqJEDAoUrPMqGRPxGMKKSFRbBPgCnDEhZnCPmnLJjKTqTh";
    self.eduroamDarkBlue = [UIColor colorWithRed:51.0/255.0 green:105.0/255.0 blue:135.0/255.0 alpha:1.0];
    rating = 0.1;
    apView = nil;
    
    
    //networkManager = [NetworkManager sharedNetworkManager];
//    json = [NetworkManager getJSONObject:@"https://eduroam-app-api.dev.ja.net" withDelegate:self];
//    [json getJSON];
    
    /////////////////////
    //UI INITIALISATION//
    /////////////////////
    
    [self setTitle:@"eduroam Sites"];
    self.navigationController.title = @"Sites";
    
    [self.navigationItem.backBarButtonItem release];
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                     style: UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];
    
    //configure the navigation controller
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    NSString* imagePath2 = [[NSString alloc] initWithFormat:@"%@/gps.png", [[NSBundle mainBundle] resourcePath]];
    UIImage* tempImage2 = [[UIImage alloc] initWithContentsOfFile:imagePath2];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:tempImage2
                                                                              style:UIBarButtonItemStyleBordered 
                                                                             target:self 
                                                                             action:@selector(locateButtonClicked)];

    NSString* imagePath = [[NSString alloc] initWithFormat:@"%@/table.png", [[NSBundle mainBundle] resourcePath]];
    UIImage* tempImage = [[UIImage alloc] initWithContentsOfFile:imagePath];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:tempImage
                                                                              style:UIBarButtonItemStyleBordered 
                                                                             target:self 
                                                                             action:@selector(toggleButtonClicked)];
    
    [imagePath release];
    [tempImage release];
    [imagePath2 release];
    [tempImage2 release];
    

    self.searchDisplayController.searchBar.barStyle = UIBarStyleBlack;
    
    //UIColor* redColour = [UIColor colorWithRed:179.0/255.0 green:0.0 blue:1.0/255.0 alpha:1.0];
    tableView.separatorColor = self.eduroamDarkBlue;
        
    ////////////////////
    //MAP INITIALISATION
    ////////////////////
    
    //Set the mapView delegate to self, just to be safe
    mapView.delegate = self;
    
    //Describes the view region of the map
    MKCoordinateRegion region;
    
    //Describe the lat/lng for the centre of the view
    CLLocationCoordinate2D location;
//    location.latitude = 50.9361536;
//    location.longitude = -1.3958504;
    location.latitude = 51.080;
    location.longitude = -1.459;
    region.center = location;
  
    //This desribes the distance between the top/bottom and left/right of the view
    MKCoordinateSpan span;
    span.latitudeDelta = 0.2;
    span.longitudeDelta = 0.2;
    region.span = span;
    
    //Set the region of the view
    [mapView setRegion:region animated:TRUE];
    

    
    
  
    
    /////////////////////
    //DATA INITIALISATION
    /////////////////////
	siteMarker = [[UIImage alloc] initWithContentsOfFile:[[[NSString alloc] initWithFormat:@"%@/sitemarker4.png", [[NSBundle mainBundle] resourcePath]] autorelease]];
    apMarker = [[UIImage alloc] initWithContentsOfFile:[[[NSString alloc] initWithFormat:@"%@/apmarker4.png", [[NSBundle mainBundle] resourcePath]] autorelease]];
    [self updateAnnotations];

    
    
    
    ///////////////////////
    //SEARCH INITIALISATION
    ///////////////////////
    //searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    searchResults = [[NSMutableArray alloc] init];
    
    
    //Set the visible view
    [secondView setHidden:YES];
    [firstView setHidden:NO];
}


- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //Get the settings
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    rating = [[defaults objectForKey:@"rating"] doubleValue];
    NSLog(@"Rating: %f", rating);
    [self updateAnnotations];

}

#pragma mark - Update APs

//---------------------------------------------------
// Given a region, determin if an update is necessary
//---------------------------------------------------
- (void) startAPUpdate:(MKCoordinateRegion)region{
    //NSLog(@"In start apupdate");
    
    //If there is an update currently in progress, return and do one later
    if (updating) {
        return;
    }
    


    
    //check current zoom level
    if (region.span.longitudeDelta > AP_UPDATE_ZOOM_MAX){
        //Too zoomed out, ignore
        updating = NO;
        return;
    }
    
    
    //check if region is nil
    if (previousUpdateRegion.span.longitudeDelta == 0.0) {
        //add this region passed in as the previous update
        previousUpdateRegion.center = region.center;
        previousUpdateRegion.span.latitudeDelta = region.span.latitudeDelta * 3;
        previousUpdateRegion.span.longitudeDelta = region.span.longitudeDelta * 3;
        
        [self sendForAPUpdate];
        updating = NO;
        return;
    }
    
    //check against previous update region, if too similar, don't bother updating
    //See if the sides of the current region are outside of the previous one
    
    if (region.center.longitude + region.span.longitudeDelta > previousUpdateRegion.center.longitude + previousUpdateRegion.span.longitudeDelta) {
    } else if(region.center.longitude - region.span.longitudeDelta < previousUpdateRegion.center.longitude - previousUpdateRegion.span.longitudeDelta){
    } else if(region.center.latitude + region.span.latitudeDelta > previousUpdateRegion.center.latitude + previousUpdateRegion.span.latitudeDelta){
    } else if(region.center.latitude - region.span.latitudeDelta < previousUpdateRegion.center.latitude - previousUpdateRegion.span.latitudeDelta){
    } else {
        //No need for an update
        updating = NO;
        return;
    }
    
    //NSLog(@"Previous region: (%f, %f) - (%f, %f)", previousUpdateRegion.center.latitude, previousUpdateRegion.center.longitude, previousUpdateRegion.span.latitudeDelta, previousUpdateRegion.span.longitudeDelta);
    
    //Update the previous update region
    previousUpdateRegion.center = region.center;
    previousUpdateRegion.span.latitudeDelta = region.span.latitudeDelta * 3;
    previousUpdateRegion.span.longitudeDelta = region.span.longitudeDelta * 3;
    
    //NSLog(@"new region: (%f, %f) - (%f, %f)", previousUpdateRegion.center.latitude, previousUpdateRegion.center.longitude, previousUpdateRegion.span.latitudeDelta, previousUpdateRegion.span.longitudeDelta);
    [self sendForAPUpdate];

}

//-------------------------
// Submit an AP update
//-------------------------
- (void) sendForAPUpdate{
    //NSLog(@"In AP updating");
    
    //Get the oldest date in the database for the access points (if any exist)
    NSString* query = @"SELECT strftime(\"%s\", lastUpdate) FROM APs WHERE lat > ? AND lng > ? AND lat < ? AND lng < ? ORDER BY lastUpdate ASC LIMIT 1";
    
    NSMutableArray* parameters = [NSMutableArray array];
    [parameters addObject:[NSNumber numberWithDouble:(previousUpdateRegion.center.latitude - previousUpdateRegion.span.latitudeDelta)]];
    [parameters addObject:[NSNumber numberWithDouble:(previousUpdateRegion.center.longitude - previousUpdateRegion.span.longitudeDelta)]];
    [parameters addObject:[NSNumber numberWithDouble:(previousUpdateRegion.center.latitude + previousUpdateRegion.span.latitudeDelta)]];
    [parameters addObject:[NSNumber numberWithDouble:(previousUpdateRegion.center.longitude + previousUpdateRegion.span.longitudeDelta)]];
    
    NSDictionary* data = [dbManager selectQuery:query withParameters:parameters ofTypes:@"dddd" andColumnTypes:@"i"];
//    NSLog(@"parameters: %@", parameters);
//    NSLog(@"db data: %@", data);
    
    //NSLog(@"Data:%@", data);
    if ([[data objectForKey:@"error"] intValue] != 0){
        //Error occurred, abort
        return;
    }
    
    int date = 0;
    
    //If no results have been returned, means there are currently no access points and therefore set date to 0
    if ([[data objectForKey:@"size"] intValue] == 0) {
        date = 0; 
    } else if ([[data objectForKey:@"size"] intValue] == 1){
        date = [[[data objectForKey:[NSNumber numberWithInt:0]] objectForKey:[NSNumber numberWithInt:0]] intValue];
    }
    
    //NSLog(@"Date being submitted: %d", date);
    
    NSMutableDictionary* getParameters = [NSMutableDictionary dictionary];
    [getParameters setObject:[NSString stringWithFormat:@"%f",(previousUpdateRegion.center.latitude - previousUpdateRegion.span.latitudeDelta)] forKey:@"swlat"];
    [getParameters setObject:[NSString stringWithFormat:@"%f",(previousUpdateRegion.center.longitude - previousUpdateRegion.span.longitudeDelta)] forKey:@"swlng"];    
    [getParameters setObject:[NSString stringWithFormat:@"%f",(previousUpdateRegion.center.latitude + previousUpdateRegion.span.latitudeDelta)] forKey:@"nelat"];
    [getParameters setObject:[NSString stringWithFormat:@"%f",(previousUpdateRegion.center.longitude + previousUpdateRegion.span.longitudeDelta)] forKey:@"nelng"]; 
    [getParameters setObject:[self rot13String:startKey] forKey:@"key"];
    [getParameters setObject:[NSString stringWithFormat:@"%d", date] forKey:@"date"];
    
    //NSLog(@"Get Parameters Array: %@", getParameters);
    
    //Unleash the JSON!
    int outcome = [jsonUpdateAP getJSON:@"apUpdate" withParameters:getParameters];
    switch (outcome) {
        case 0:
            //Success
            break;
        case 1:
            //There is no internet connection so start the main app
            return;
            break;
        default:
            break;
    }
    
    
}

//----------------------------------------
// Have recieved a response, deal with it!
//----------------------------------------
- (void) applyAPUpdate:(NSDictionary*)data{
    //NSLog(@"data: %@", data);
    
    //Check the success of the server query
    int rcode = [[[data objectForKey:@"rcode"] objectForKey:@"code"] intValue];
    
    if(rcode != 0){
        NSLog(@"Error getting the json");
        return;
    }
    
    //Get the number of updates
    int number = [[data objectForKey:@"insert"] count];
    number = number + [[data objectForKey:@"update"] count];
    number = number + [[data objectForKey:@"delete"] count];
    
    //NSLog(@"number: %d", number);
    
    
    int date = [[data objectForKey:@"date"] intValue];
    
    if (number != 0){
        //INSERT the APs
        NSString* query = @"INSERT INTO APs (id, lat, lng, subsite, rating, lastUpdate) VALUES (?, ?, ?, ?, ?, datetime(?, 'unixepoch'))";
        NSMutableArray* parameters = [NSMutableArray array];
        NSDictionary* subdata = [data objectForKey:@"insert"];
        NSEnumerator* e = [subdata keyEnumerator];
        id _id;
        while ((_id = [e nextObject])) {
            [parameters removeAllObjects];
            [parameters addObject:_id];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"lat"]];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"lng"]];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"subsite"]];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"rating"]];
            [parameters addObject:[NSNumber numberWithInt:date]];
            
            int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"iddidi"];
            if (outcome != 0) {
                NSLog(@"AP Insert failed for outcome:%d id: %@", outcome, _id);
                continue;
            }
        }
        
        
        //UPDATE the APs
        query = @"UPDATE APs SET lat=?, lng=?, subsite=?, rating=?, lastUpdate=datetime(?, 'unixepoch') WHERE id=?";
        subdata = [data objectForKey:@"update"];
        e = [subdata keyEnumerator];
        while ((_id = [e nextObject])) {
            [parameters removeAllObjects];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"lat"]];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"lng"]];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"subsite"]];
            [parameters addObject:[[subdata objectForKey:_id] objectForKey:@"rating"]];
            [parameters addObject:[NSNumber numberWithInt:date]];
            [parameters addObject:_id];
            
            int outcome = [dbManager insertQuery:query withParameters:parameters ofTypes:@"ddidii"];
            if (outcome != 0) {
                NSLog(@"AP Insert failed");
                continue;
            }
        }
        
        
        //DELETE APs
        query = @"DELETE FROM APs WHERE id=?";
        NSArray* arraySubData = [data objectForKey:@"delete"];
        e = [arraySubData objectEnumerator];
        while ((_id = [e nextObject])) {
            [parameters removeAllObjects];
            [parameters addObject:_id];
            
            int outcome = [dbManager deleteQuery:query withParameters:parameters ofTypes:@"i"];
            if (outcome != 0) {
                NSLog(@"AP delete failed:%d", outcome);
                continue;
            }
        }
        [self mapRefresh];
    }
    
    
    //Update the lastUpdated date for all the access points within range
    NSString* query = @"UPDATE APs SET lastUpdate=datetime(?, 'unixepoch') WHERE lat > ? AND lng > ? AND lat < ? AND lng < ?";
    NSMutableArray* parameters = [NSMutableArray array];
    [parameters removeAllObjects];
    [parameters addObject:[NSNumber numberWithInt:date]];
    [parameters addObject:[data objectForKey:@"swlat"]];
    [parameters addObject:[data objectForKey:@"swlng"]];
    [parameters addObject:[data objectForKey:@"nelat"]];
    [parameters addObject:[data objectForKey:@"nelng"]];

    int outcome = [dbManager deleteQuery:query withParameters:parameters ofTypes:@"idddd"];
    if (outcome != 0) {
        NSLog(@"AP group update failed:%d", outcome);
    }

    
    
    updating = NO;
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

#pragma mark - JSON Responses

//--------------------------------------
// Got a Dictionary back from the server
//--------------------------------------
- (void)receiveJSONDictionary:(NSMutableDictionary*)dictionary withID:(NSString*)identifier{
    
    //If the response is to an apUpdate request
    if ([identifier isEqualToString:@"apUpdate"]) {
        [self applyAPUpdate:dictionary];
    }
    
    if ([identifier isEqualToString:@"search"]) {
        [self dealWithSearchResults:dictionary];
    }
    
}

//--------------------------------------
// Error with the connection, so no JSON
//--------------------------------------
- (void)receiveConnectionError:(NSString*)identifier{
    
    if ([identifier isEqualToString:@"apUpdate"]) {
        NSLog(@"Connection error occurred while updating the APs");
        updating = NO;
    }
    
    if ([identifier isEqualToString:@"search"]) {
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"Search Error" 
                                                        message:@"There has been a problem with your search. Please try again" 
                                                       delegate:self 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
        [error show];
        [error release];
    }
}

//------------------------------------------------
// Error in server's response, a non-JSON response
//------------------------------------------------
- (void)receiveJSONError:(NSString*)identifier{
    
    if ([identifier isEqualToString:@"apUpdate"]) {
        NSLog(@"JSON Error occurred while updating the APs");
        updating = NO;
    }
    
    if ([identifier isEqualToString:@"search"]) {
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"Search Error" 
                                                        message:@"There has been a problem with your search. Please try again" 
                                                       delegate:self 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles: nil];
        [error show];
        [error release];
    }
}


#pragma mark - Map
//-----------------------------------------------------------------
// Refresh the annotations on the map, used after a database update
//-----------------------------------------------------------------
- (void)mapRefresh{
    //remove and update, simple as
    [mapView removeAnnotations:[mapView annotations]];
    [mapView removeOverlays:[mapView overlays]];
    [mapView addAnnotation:currentLocation];
    [self updateAnnotations];
}

//-----------------------------------------------
// Create annotations and add them to the mapView
//-----------------------------------------------
- (NSMutableDictionary*) getSiteAnnotations {
    
    //If too zoomed out, return rmpty array
    if (SITE_ZOOM_MAX < mapView.region.span.longitudeDelta) {
        return [NSMutableDictionary dictionary];
    }
    
    //Get the annotations already in the mapview
    sqlite3* db = [dbManager getDB];
    sqlite3_stmt* stmt;
    double latmin = mapView.region.center.latitude - mapView.region.span.latitudeDelta;
    double latmax = mapView.region.center.latitude + mapView.region.span.latitudeDelta;
    double lngmin = mapView.region.center.longitude - mapView.region.span.longitudeDelta;
    double lngmax = mapView.region.center.longitude + mapView.region.span.longitudeDelta;
    
    //////////////
    //SQLite STUFF
    //////////////
    

    NSString* query = @"SELECT SubSites.id, SubSites.name, SubSites.site, SubSites.lat, SubSites.lng, Site.name FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id WHERE lat >= ? AND lat <= ? AND lng >= ? AND lng <= ?";
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);
    if( outcome == SQLITE_OK){
        sqlite3_bind_double(stmt, 1, latmin);
        sqlite3_bind_double(stmt, 2, latmax);
        sqlite3_bind_double(stmt, 3, lngmin);
        sqlite3_bind_double(stmt, 4, lngmax);
    } else {
        //unable to prepare the statement
        //There was an error
    }

    
    //Execute the statement
    
    //Array of annotations to add to the database
    NSMutableDictionary* annotationsToAdd = [NSMutableDictionary dictionary];

    //Loop through the results of the query and add new annotations to the mapview
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int _id = sqlite3_column_int(stmt, 0);
        
        char* charname = (char*) sqlite3_column_text(stmt, 1);
        NSString* subname = [NSString stringWithUTF8String:charname];
        
        int siteID = sqlite3_column_int(stmt, 2);
        
        double lat = sqlite3_column_double(stmt, 3);
        
        double lng = sqlite3_column_double(stmt, 4);
        
        char* charname2 = (char*) sqlite3_column_text(stmt, 5);
        NSString* name = [NSString stringWithUTF8String:charname2];
        
        
        CLLocationCoordinate2D coord;
        //Add the coordinates and make a siteannotation
        coord.latitude = lat;
        coord.longitude = lng;
        
        SiteAnnotation* a = [[SiteAnnotation alloc] initWithCoordinate:coord withTitle:name andSubTitle:subname andID:_id andSiteID:siteID];
        [annotationsToAdd setObject:a forKey:[NSNumber numberWithInt:_id]];
        [a release];
    }
    return annotationsToAdd;
    
}


//---------------------------------------------------------------
// Get APs from database, creates annotations and circle overlays
//---------------------------------------------------------------
- (NSMutableDictionary*) getAPAnnotations{
    
    
    //Create one dictionary for the annotations of the APs and other for the ranges
    //These aer the n combined together in one dictionary that is returned
    //Each annotation holds a reference to the range, and the range dictionary holds each
    //range value via an annotation key. This is because the id for the AP can only be stored
    //in the annotation.
    NSMutableDictionary* output = [NSMutableDictionary dictionary];
    NSMutableDictionary* annotations = [NSMutableDictionary dictionary];
    NSMutableDictionary* range = [NSMutableDictionary dictionary];
  
    //If too zoomed out, then return empty array
    if (AP_ZOOM_MAX < mapView.region.span.longitudeDelta) {
        [output setObject:annotations forKey:@"annotations"];
        [output setObject:range forKey:@"range"];
        return output;
    }
    
    //Get the annotations already in the mapview
    sqlite3* db = [dbManager getDB];
    sqlite3_stmt* stmt;
    double latmin = mapView.region.center.latitude - mapView.region.span.latitudeDelta;
    double latmax = mapView.region.center.latitude + mapView.region.span.latitudeDelta;
    double lngmin = mapView.region.center.longitude - mapView.region.span.longitudeDelta;
    double lngmax = mapView.region.center.longitude + mapView.region.span.longitudeDelta;
    
    //////////////
    //SQLite STUFF
    //////////////
    //    NSString * query = @"SELECT SubSites.id, SubSites.name, SubSites.site, SubSites.lat, SubSites.lng, Site.name FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id WHERE lat >= ? AND lat <= ? AND lng >= ? AND lng <= ?";

    //NSString* query = @"SELECT id, lat, lng, subsite FROM APs WHERE lat >= ? AND lat <= ? AND lng >= ? AND lng <= ? AND rating >= ?";
    NSString* query = @"SELECT APs.id, APs.lat, APs.lng, APs.subsite, SubSites.name, Site.name FROM APs, SubSites, Site WHERE APs.subsite=SubSites.id AND SubSites.site=Site.id AND APs.lat >= ? AND APs.lat <= ? AND APs.lng >= ? AND APs.lng <= ? AND APs.rating >= ?";
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);
    if( outcome == SQLITE_OK){
        sqlite3_bind_double(stmt, 1, latmin);
        sqlite3_bind_double(stmt, 2, latmax);
        sqlite3_bind_double(stmt, 3, lngmin);
        sqlite3_bind_double(stmt, 4, lngmax);
        sqlite3_bind_double(stmt, 5, rating);
    } else {
        //unable to prepare the statement
        //There was an error
    }
    
    
    //Execute the statement
    
    //Array of annotations to add to the database
    //Loop through the results of the query and add new annotations to the mapview
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        int _id = sqlite3_column_int(stmt, 0);
        
        double lat = sqlite3_column_double(stmt, 1);
        
        double lng = sqlite3_column_double(stmt, 2);
        
        int subsite = sqlite3_column_int(stmt, 3);
        
        char* field = (char*) sqlite3_column_text(stmt, 4);
        NSString* subSiteName = [NSString stringWithUTF8String:field];
        
        char* field2 = (char*) sqlite3_column_text(stmt, 5);
        NSString* siteName = [NSString stringWithUTF8String:field2];
        
        CLLocationCoordinate2D coord;
        //Add the coordinates and make a siteannotation
        coord.latitude = lat;
        coord.longitude = lng;
        
        MKCircle* circle = [MKCircle circleWithCenterCoordinate:coord radius:AP_RANGE];
        
        //APAnnotations* a = [[APAnnotations alloc] initWithCoordinate:coord withTitle:[NSString stringWithFormat:@"Site: %d", site] andID:_id];
        APAnnotations* a = [[APAnnotations alloc] initWithCoordinate:coord withTitle:siteName andSubTitle:subSiteName andID:_id andRange:circle andSiteID:subsite];
        [annotations setObject:a forKey:[NSNumber numberWithInt:_id]];
        [range setObject:circle forKey:[NSNumber numberWithInt:_id]];
        [a release];
        
    }

    [output setObject:annotations forKey:@"annotations"];
    [output setObject:range forKey:@"range"];
    return output;

    
}

//----------------------------------------------------------------------
// update the annotations of the mapview
//----------------------------------------------------------------------
-(void) updateAnnotations{


    
    //Get the arrays of the markers 
    NSMutableDictionary* apInput = [self getAPAnnotations];
    
    NSMutableDictionary* apAnnotations = [apInput objectForKey:@"annotations"];
    NSMutableDictionary* apRange = [apInput objectForKey:@"range"];
    NSMutableDictionary* siteAnnotations = [self getSiteAnnotations];
    
    //Find which annotations are already in the map view
    NSEnumerator* e = [[mapView annotations] objectEnumerator];
    Annotation* a;
    while ((a = [e nextObject])) {
        //If it is a Site Annotation
        if(a.type == 1){
            if([siteAnnotations objectForKey:[NSNumber numberWithInt:a._id]] == nil){
                //Not found in current annotations, remove from mapview
                [mapView removeAnnotation:a];
            } else {
                //already in mapview, remove from siteAnnotation
                [siteAnnotations removeObjectForKey:[NSNumber numberWithInt:a._id]];
            }
        } else if(a.type == 2){
            APAnnotations* ap = (APAnnotations*) a;
            if([apAnnotations objectForKey:[NSNumber numberWithInt:a._id]] == nil){
                //Not found in current annotations, remove from mapview
                [mapView removeAnnotation:a];
                [mapView removeOverlay:ap.range];
            } else {
                //already in mapview, remove from siteAnnotation
                [apRange removeObjectForKey:[NSNumber numberWithInt:a._id]];
                [apAnnotations removeObjectForKey:[NSNumber numberWithInt:a._id]];
            }            
        }
    }
    
    [mapView addAnnotations:[siteAnnotations allValues]];
    [mapView addAnnotations:[apAnnotations allValues]];
    [mapView addOverlays:[apRange allValues]];
    
    //Make sure the current location annotation is over the top of the other annotations

 
}

//------------------------------------------------------------------
// Ensure that the current location view after annotations are added

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views{
    
    if (currentLocationView != nil) {
        [[currentLocationView superview] bringSubviewToFront:currentLocationView];
    }
}




//----------------------------------------------------------------------
// Map has stopped moving, get new add
//----------------------------------------------------------------------
- (void)mapView:(MKMapView*)mapView regionDidChangeAnimated:(BOOL)animated{
    //Might wanna thread this to make it smoother
    [self updateAnnotations];
    
    //Call to the update with mapview coordiantes and span
    [self startAPUpdate:mapView.region];
}




//-------------------------------------------------------
// Defines the view of the annotaitons and their callouts
//-------------------------------------------------------
- (MKAnnotationView*)mapView:(MKMapView*)mapViewin viewForAnnotation:(id<MKAnnotation>)annotation {
    //NSLog(@"In view for annotation");
    
    //Cast t
    Annotation* a = (Annotation*) annotation;


    MKAnnotationView* pin = nil;

    //TODO - make an eduroam site pin, add callouts to these bad boys
    switch (a.type) {
        case 1:{
            pin = [mapView dequeueReusableAnnotationViewWithIdentifier:@"site"];
            if (pin == nil){
                pin = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"site"] autorelease];
            } else {
                pin.annotation = annotation;
            }
            pin.image = siteMarker;
            pin.canShowCallout = YES;
            pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pin.centerOffset = CGPointMake(4, -18);
        }
            break;
        case 2:
            pin = [mapView dequeueReusableAnnotationViewWithIdentifier:@"ap"];
            if (pin == nil){
                pin = [[[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"ap"] autorelease];
            } else {
                pin.annotation = annotation;
            }
            pin.image = apMarker;
            pin.canShowCallout = YES;
            pin.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            pin.centerOffset = CGPointMake(4, -18);

            break;
        case 3:
            pin = [mapView dequeueReusableAnnotationViewWithIdentifier:@"youarehere"];
            if (pin == nil) {
                pin = [[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"youarehere"] autorelease];
                pin.canShowCallout = YES;
            } else {
                pin.annotation = annotation;
            }
            currentLocationView = pin;
            
        default:
            break;
    }
 
    return pin;
}


//-----------------------------------------------------------
// AnnotationView button has been pressed, go to details view
//-----------------------------------------------------------
- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control{
    NSLog(@"callout button pressed!");
    //Can get the annotation from mkannotationview.annotation
    
    //find out the type of the annotation
    Annotation* a = (Annotation*) view.annotation;
    switch (a.type) {
        case 1:
            if(siteView == NULL){
                // SiteDetailsViewController* d = [[SiteDetailsViewController alloc] initWithNibName:@"SiteDetails" bundle:[NSBundle mainBundle]];
                siteView = [[SiteDetailsViewController alloc] initWithNibName:@"SiteDetails" bundle:[NSBundle mainBundle]];
                //[d release];
            }
            [siteView loadSite:a._id];
            [self.navigationController pushViewController:siteView animated:YES];
            break;
        case 2:
            //NSLog(@"This is an AP");
            if (apView == nil){
                apView = [[APDetailsViewController alloc] initWithNibName:@"APDetails" bundle:[NSBundle mainBundle]];
            }
            [apView loadAP:a._id];
            [self.navigationController pushViewController:apView animated:YES];
            break;
        default:
            break;
    }
    
    
    

    
}


//------------------------------------------------
// Deal with views for overlays
//------------------------------------------------
-(MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id)overlay{
    MKCircleView* circleView = [[[MKCircleView alloc] initWithOverlay:overlay] autorelease];
    circleView.strokeColor = [UIColor whiteColor];
    circleView.lineWidth = 2.0;
    //Uncomment below to fill in the circle
    circleView.fillColor = [UIColor colorWithRed:0 green:0 blue:255 alpha:0.15];
    return circleView;
}


#pragma mark - Map Search Bar

//-----------------------------
// User has started to edit the
//-----------------------------
- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar{
    if (searchBar == searchBarMap){
        [searchBar setShowsCancelButton:YES animated:YES];
    }
}

//--------------------------------------------------------------
// User has finished editing the search bar, hide the cancel bar
//--------------------------------------------------------------
- (void) searchBarTextDidEndEditing:(UISearchBar *)searchBar{
    if (searchBar == searchBarMap){
        [searchBar setShowsCancelButton:NO animated:YES];
    }
}

//--------------------------------------------------------------
// When the cancel button is clicked, resign the first responder
//--------------------------------------------------------------
- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    if (searchBar == searchBarMap) {
        if([searchBar isFirstResponder]){
            [searchBar resignFirstResponder];
        }
    }
}

//----------------------------------------
// When the search button has been pressed
//----------------------------------------
- (void) searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    

    //If it is the searchbarmap that we are dealing with
    if (searchBarMap == searchBar){
    
        NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
        [parameters setObject:@"true" forKey:@"sensor"];
        [parameters setObject:[self textToHTML:searchBarMap.text] forKey:@"address"];
        //[parameters setObject:@"50.56,-3.76&|50.84,-3.32" forKey:@"bounds"];  //Tried to use bounds, but NSURL does not like the '|' symbol


        int outcome = [jsonSearch getJSON:@"search" withParameters:parameters];
        switch (outcome) {
            case 0:
                //Success
                break;
            case 1:{
                //Failed because of no connection, AlertView it up
                UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"No Connection" 
                                                                message:@"Your search cannot be conducted as you do not have a connection to the Internet" 
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles: nil];
                [error show];
                [error release];
                return;
            }
                break;
            default:
                break;
        }


        //Sort out first responder? hide keyboard?
        [searchBarMap resignFirstResponder];
    }
    
}

//----------------------------------------------------
// Take a string, convert it ready for html submission
//----------------------------------------------------
- (NSString*) textToHTML:(NSString*)inputString{
    inputString = [inputString stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    return inputString;
}

//---------------------------------------------
// Receive Map Search Results and act upon them
//---------------------------------------------
- (void) dealWithSearchResults:(NSMutableDictionary*)data{
    
    
    //Status needs to be 'OK'
    if (!([[data objectForKey:@"status"] isEqualToString:@"OK"])) {
        NSLog(@"Error with search");
        return;
    }
    
    //Get the lat/lng and the span
    data = (NSMutableDictionary*) [[data objectForKey:@"results"] objectAtIndex:0];
    double lat = [[[[data objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] doubleValue];
    double lng = [[[[data objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] doubleValue];
    
    
    double swlng = [[[[[data objectForKey:@"geometry"] objectForKey:@"viewport"] objectForKey:@"southwest"] objectForKey:@"lng"] doubleValue];
    double nelng = [[[[[data objectForKey:@"geometry"] objectForKey:@"viewport"] objectForKey:@"northeast"] objectForKey:@"lng"] doubleValue];
    double lngspan = nelng - swlng;
    
    double swlat = [[[[[data objectForKey:@"geometry"] objectForKey:@"viewport"] objectForKey:@"southwest"] objectForKey:@"lat"] doubleValue];
    double nelat = [[[[[data objectForKey:@"geometry"] objectForKey:@"viewport"] objectForKey:@"northeast"] objectForKey:@"lat"] doubleValue];
    double latspan = nelat - swlat;

    
    //move the map view to the location
    MKCoordinateRegion region;
    region.span.latitudeDelta = latspan;
    region.span.longitudeDelta = lngspan;
    region.center.latitude = lat;
    region.center.longitude = lng;
    
    //setregion animated
    [mapView setRegion:region animated:YES];
}





#pragma mark - Location

//------------------------------------------------------
// Called when location changes, 
//------------------------------------------------------
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    //On first initialisation, go to the marker
    if (oldLocation == nil) {
        [self locateButtonClicked];
    }
    
    if (currentLocation != nil) {
        [mapView removeAnnotation:currentLocation];
    }
    //create a new annotation
    currentLocation = [[YouAreHereAnnotation alloc] initWithCoordinate:newLocation.coordinate andLatAccuracy:newLocation.verticalAccuracy andLngAccuracy:newLocation.horizontalAccuracy];
    [mapView addAnnotation:currentLocation];
    
    //Update the list of the n nearest sites to the user
    self.nearestSites = [self getNearestSites:NUMBER_OF_NEAREST_SITES fromLat:newLocation.coordinate.latitude andLng:newLocation.coordinate.longitude];
    [tableView reloadData];
}


#pragma mark - User Interaction

//----------------------------------------
// Flip the views around, go from table to 
//----------------------------------------
- (void)toggleButtonClicked{
    
    if([secondView isHidden]){
                
        //Begin the animation to hide the mapview and show the table view (secondview)
        [firstView setHidden:YES];
        [secondView setHidden:NO];
        [UIView transitionFromView:firstView 
                            toView:secondView 
                          duration:0.75 
                           options:(UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionCurveEaseInOut) 
                        completion:^(BOOL done){
                            if ([nearestSites count] <= 0 && !TABLE_NO_LOCATION_ALERT) {
                                //Check if the array of nearest sites is empty - if so, display an alert
                                UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"Unable To Determine Location" 
                                                                                message:@"Unable to display list of nearest sites as your current location is unknown. This could be because Location Services in the iPhone settings is turned off" 
                                                                               delegate:self 
                                                                      cancelButtonTitle:@"OK" 
                                                                      otherButtonTitles:nil];
                                
                                [error show];
                                [error release];
                                TABLE_NO_LOCATION_ALERT = YES;
                            }                      
                        }];
        
        //change button image
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"mapicon1.png"];

    } else {
        
        [firstView setHidden:NO];
        [secondView setHidden:YES];
        [UIView transitionFromView:secondView 
                            toView:firstView 
                          duration:0.75 
                           options:(UIViewAnimationOptionTransitionFlipFromLeft | UIViewAnimationOptionCurveEaseInOut) 
                        completion:^(BOOL done){}];
        
        self.navigationItem.leftBarButtonItem.image = [UIImage imageNamed:@"table.png"];

        
    }   
}


//-----------------------------------------------
// Centre mapview onto the user
//-----------------------------------------------
- (void)locateButtonClicked{
    
    //Check permission
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"Location Services Are Turned Off" 
                                                        message:@"In order to locate you, please give this application permission to do so by going to the iPhone Settings" 
                                                       delegate:self 
                                              cancelButtonTitle:@"OK" 
                                              otherButtonTitles:nil];
        
        [error show];
        [error release];
    }
    
    [self centerOnUser];

}

//------------------------------
// Centre on the user's location
//------------------------------
- (void) centerOnUser{
    
        //Get the location if one is available
    CLLocation* location = [[locationManager manager] location];
    if(location == nil){
        NSLog(@"Error: Current location is nil");
        return;
    }
    
    
    //Describe the lat/lng for the centre of the view
    [mapView setCenterCoordinate:location.coordinate animated:TRUE];
    
    //Cannot zoom in because of funky business with mkmapview altering the lat/lng deltas
    //original plan was to be able to keep the zoom level if zoomed in closer than default, else zoom to default zoom level
    //even passing in the current deltas into mkmapview will mean figures are changed the zoom level will change
}


#pragma mark - Table Functions

//----------------------------------------
// Return array of n nearest sites
//----------------------------------------
- (NSArray*) getNearestSites:(int)n fromLat:(double)lat andLng:(double)lng {
    
    //get n nearest sites in terms of lat
    NSString* query = @"SELECT Site.name, SubSites.name, SubSites.lat, SubSites.lng, SubSites.id FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id ORDER BY (ABS(lat - ?) + ABS(lng - ?)) ASC LIMIT ?";
    NSMutableArray* parameters = [NSMutableArray array];
    [parameters addObject:[NSNumber numberWithDouble:lat]];
    [parameters addObject:[NSNumber numberWithDouble:lng]];
    [parameters addObject:[NSNumber numberWithInt:n]];
    
    NSMutableDictionary* data = [dbManager selectQuery:query withParameters:parameters ofTypes:@"ddi" andColumnTypes:@"ssddi"];
    
    if([[data objectForKey:@"error"] intValue]!= 0){
        //something went wrong
        NSLog(@"Error 001: SQLite Query failed to get nearest sites with error code %@", [data objectForKey:@"error"]);
        return nil;
    }
    


    //remove the size and error entries
    [data removeObjectForKey:@"size"];
    [data removeObjectForKey:@"error"];
    
    
    //calcualte the distance between each point using the haversine formula, which gives a distance in Km
    NSEnumerator* e = [[data allValues] objectEnumerator];
    NSMutableDictionary* site;
    
      //radius of the earth in Km
    while ((site = [e nextObject])) {
        
        double siteLat = [[site objectForKey:[NSNumber numberWithInt:2]] doubleValue];
        double siteLng = [[site objectForKey:[NSNumber numberWithInt:3]] doubleValue];
       
        [site setValue:[NSNumber numberWithDouble:[self getDistanceBetweenTwoPlaces:lat andLng:lng withPlaceTwo:siteLat andLng:siteLng]] forKey:@"distance"];        
    }
    
    //Sort them into an array
    NSMutableArray* orderedList = [[[NSMutableArray alloc] initWithCapacity:n] autorelease];
    NSNumber* sitekey;


    for (int i=0; i<n; i++) {
        NSEnumerator* j =[[data allKeys] objectEnumerator];
        NSNumber* currentSmallest = [j nextObject];
        while ((sitekey = [j nextObject])) {
            if([[[data objectForKey:sitekey] objectForKey:@"distance"] doubleValue] < [[[data objectForKey:currentSmallest] objectForKey:@"distance"] doubleValue]){
                currentSmallest = sitekey;             
            }
        }
        
        [orderedList addObject:[data objectForKey:currentSmallest]];
        [data removeObjectForKey:currentSmallest];
    }
    
    return orderedList;
}


//-------------------------------------------------------------------------------
// Takes 2 lat/lng pairs, uses haversine to calculate distance between the points
//-------------------------------------------------------------------------------
- (double) getDistanceBetweenTwoPlaces:(double)lat1 andLng:(double)lng1 withPlaceTwo:(double)lat2 andLng:(double)lng2{
        
    //This is the haversine formula
    double dlat = [self degreesToRadians:(lat1 - lat2)];
    double dlng = [self degreesToRadians:(lng1 - lng2)];
    double a = (sin(dlat/2) * sin(dlat/2)) 
    + (cos([self degreesToRadians:lat2]) * cos([self degreesToRadians:lat1]) * (sin(dlng/2) * sin(dlng/2)));
    double c = 2 * atan2(sqrt(a), sqrt(1-a));
    double d = EARTH_RADIUS * c;
    
    return d;
}


//------------------------------------------------
// Convert from degrees to radians
//------------------------------------------------
- (double) degreesToRadians:(double) degrees{
    return (degrees * (M_PI / 180));
}

//------------------------------------------------
// Convert from radians to degrees
//------------------------------------------------
- (double) radiansToDegrees:(double) radians{
    return (radians * (180 / M_PI));
}


//---------------------------------------
// Return the number of rows in the table
//---------------------------------------
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (tableView == [self tableView]) {
        return [nearestSites count];
    } else {
        return [searchResults count];
    }
}

//---------------------------------------
// Return a cell given an index
//---------------------------------------
- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString* cellIdentifier = @"Cell";
	
	//attempt to get at a reusable cell
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	//If we cannot get a reusable cell, then create a new cell
	if(cell == nil){
		//cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
	}
    
    //UIColor* backgroundColour = [UIColor colorWithRed:46.0/255.0 green:46.0/255.0 blue:46.0/255.0 alpha:1.0];
    //UIColor* titleTextColour = [UIColor whiteColor];
    //UIColor* subTitleTextColour = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
    //UIColor* redColour = [UIColor colorWithRed:179.0/255.0 green:0.0 blue:1.0/255.0 alpha:1.0];
    //UIColor* darkerRedColour = [UIColor colorWithRed:80.0/255.0 green:0.0 blue:1.0/255.0 alpha:1.0];
    UIColor* whiteColour= [UIColor whiteColor];
    //UIColor* halfBlack = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    
    
    CGSize maxSize = CGSizeMake(70.0, cell.frame.size.height-1);

    
    
//    UIView* backgroundView = [ [ [ UIView alloc ] initWithFrame:CGRectZero ] autorelease ];
//    backgroundView.backgroundColor = whiteColour;
//    cell.backgroundView = backgroundView;
        
//    cell.textLabel.textColor = [UIColor blackColor];
//    cell.detailTextLabel.textColor = backgroundColour;

    

    
    if (tableView == [self tableView]){
        cell.textLabel.text = [[nearestSites objectAtIndex:[indexPath row]] objectForKey:[NSNumber numberWithInt:0]];
        cell.detailTextLabel.text = [[nearestSites objectAtIndex:[indexPath row]] objectForKey:[NSNumber numberWithInt:1]];
        UILabel* temp = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, cell.frame.size.height-1)];
        temp.text = [NSString stringWithFormat:@"%.1f Km", [[[nearestSites objectAtIndex:[indexPath row]] objectForKey:@"distance"] doubleValue]];
        temp.font = [UIFont fontWithName:@"Helvetica" size:14];
        temp.backgroundColor = whiteColour;

        //Get the size just right to allow for maximum room for the text
        CGSize labelSize = [temp.text sizeWithFont:temp.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeTailTruncation];
        temp.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
        //temp.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
        temp.textColor = eduroamDarkBlue;
        temp.textAlignment = UITextAlignmentRight;
        //temp.backgroundColor = [UIColor blueColor];
        cell.accessoryView = temp;
//        [cell.accessoryView addSubview:temp];
//        cell.accessoryView.frame = temp.frame;
    } else {
        cell.textLabel.text = [[searchResults objectAtIndex:[indexPath row]] objectForKey:[NSNumber numberWithInt:0]];
        cell.detailTextLabel.text = [[searchResults objectAtIndex:[indexPath row]] objectForKey:[NSNumber numberWithInt:1]];
        
        if ([[[searchResults objectAtIndex:[indexPath row]] objectForKey:@"distance"] doubleValue] != -1){
            UILabel* temp = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, cell.frame.size.height-1)];
            
            
            temp.text = [NSString stringWithFormat:@"%.1f Km", [[[searchResults objectAtIndex:[indexPath row]] objectForKey:@"distance"] doubleValue]];
            //temp.textColor = [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1];
            temp.textColor = eduroamDarkBlue;
            temp.font = [UIFont fontWithName:@"Helvetica" size:14];
            
            //Get the size just right to allow for maximum room for the text
            CGSize labelSize = [temp.text sizeWithFont:temp.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeTailTruncation];
            temp.frame = CGRectMake(0, 0, labelSize.width, cell.frame.size.height-1);
            cell.accessoryView = temp;
        }
    }
    
    
//    UIView* backgroundView = [ [ [ UIView alloc ] initWithFrame:CGRectZero ] autorelease ];
//    backgroundView.backgroundColor = [ UIColor yellowColor ];
//    cell.backgroundView = backgroundView;
//    NSLog(@"About to go throguh");
//    for ( UIView* view in cell.contentView.subviews ) 
//    {
//        view.backgroundColor = [ UIColor clearColor ];
//    }
    
    return cell;
}

//--------------------------------------------
// Returns the header for the section
//--------------------------------------------
- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *headerView = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)] autorelease];


    [headerView setBackgroundColor: [UIColor colorWithRed:51.0/255.0 green:105.0/255.0 blue:135.0/255.0 alpha:0.9]];
    if (tableView == [self tableView]){
        headerView.text = @"  Sites (Closest First)";
    } else {
        headerView.text = @"  Search Results";
    }
    headerView.textColor = [UIColor whiteColor];
    headerView.font = [UIFont fontWithName:@"Helvetica-Bold" size:16 ];

    //headerView.text = @"Sites";

    return headerView;
}

//--------------------------------------------------
// When user selects table cell, load site info view
//--------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //alter the query and get hte ID of the site
    //change the colour of the distance to site when selected
    //sort out diddeselectrowatindexpath to return colour to normal
    

    
    //Load the new view
    if(siteView == NULL){
        // SiteDetailsViewController* d = [[SiteDetailsViewController alloc] initWithNibName:@"SiteDetails" bundle:[NSBundle mainBundle]];
        siteView = [[SiteDetailsViewController alloc] initWithNibName:@"SiteDetails" bundle:[NSBundle mainBundle]];
        //[d release];
    }
    
    if(tableView == [self tableView]){
        [siteView loadSite:[[[nearestSites objectAtIndex:indexPath.row] objectForKey:[NSNumber numberWithInt:4]]intValue]];
        UILabel* label = (UILabel*) [[tableView cellForRowAtIndexPath:indexPath] accessoryView];
        label.textColor = [UIColor whiteColor];
    } else {
        [siteView loadSite:[[[searchResults objectAtIndex:indexPath.row] objectForKey:[NSNumber numberWithInt:4]]intValue]];
    }
    [self.navigationController pushViewController:siteView animated:YES];
}



//----------------------------------------------------------------------
// change the colour of the distance text back to normal when deselected
//----------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    UILabel* label = (UILabel*) [[tableView cellForRowAtIndexPath:indexPath] accessoryView];
    label.textColor = eduroamDarkBlue;

}


#pragma mark - Search Table

//------------------------------------------------------------------------------------
// Called when the text changes in the search bar - this is from the search controller
//------------------------------------------------------------------------------------
- (BOOL) searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString{
    //Do the filtering here
    [self filterSitesForSearchText:searchString];
    
    return YES;
}

//------------------------------------------------------
// Update the search results array given a search string
//------------------------------------------------------
- (void) filterSitesForSearchText:(NSString*)searchText{
    
    //do the filtering in here
    //Remove the current contents of the search results array
    [searchResults removeAllObjects];
    
    
    //If only a couple of characters have been enetered, do a more constrainted search to keep speed up
    NSString* query;
    NSMutableArray* parameters;
//    if ([searchText length] < 2){
//        query = @"SELECT Site.name, SubSites.name, SubSites.lat, SubSites.lng, SubSites.id FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id WHERE Site.name LIKE ? || '%' OR SubSites.name LIKE ? || '%' OR SubSites.address LIKE ? || '%'";
//        parameters = [NSMutableArray arrayWithObjects:searchText, searchText, searchText, nil];
//    } else {
        query = @"SELECT Site.name, SubSites.name, SubSites.lat, SubSites.lng, SubSites.id FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id WHERE Site.name LIKE '%' || ? || '%' OR SubSites.name LIKE '%' || ? || '%' OR SubSites.address LIKE '%' || ? || '%' LIMIT 100";
        parameters = [NSMutableArray arrayWithObjects:searchText, searchText, searchText, nil];
//    }
    
    //Fire a query
    NSMutableDictionary* data = [dbManager selectQuery:query withParameters:parameters ofTypes:@"sss" andColumnTypes:@"ssddi"];

    [data removeObjectForKey:@"size"];
    [data removeObjectForKey:@"error"];
    
    
    //calcualte the distance between each point using the haversine formula, which gives a distance in Km
    NSEnumerator* e = [[data allValues] objectEnumerator];
    NSMutableDictionary* site;
    CLLocationCoordinate2D currentcoord = [currentLocation coordinate];
    
    //radius of the earth in Km
    while ((site = [e nextObject])) {
        
        if (currentLocation != nil){
            double siteLat = [[site objectForKey:[NSNumber numberWithInt:2]] doubleValue];
            double siteLng = [[site objectForKey:[NSNumber numberWithInt:3]] doubleValue];
            
            [site setValue:[NSNumber numberWithDouble:[self getDistanceBetweenTwoPlaces:currentcoord.latitude andLng:currentcoord.longitude withPlaceTwo:siteLat andLng:siteLng]] forKey:@"distance"]; 
        } else {
            [site setValue:[NSNumber numberWithDouble:-1] forKey:@"distance"];
        }
  
            [searchResults addObject:site];
    }

    
    
}


#pragma - Network
- (void)receiveJSONDictionary:(NSMutableDictionary*)dictionary{
    
    
    NSLog(@"JSONDictionary: %@", dictionary);
}


#pragma mark - Misc

- (NSString*) getFilePath{
    return NULL;
    
}



#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
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

- (IBAction)buttonPress:(id)sender{
    NSLog(@"Hello World");
    
    if(siteView == NULL){
       // SiteDetailsViewController* d = [[SiteDetailsViewController alloc] initWithNibName:@"SiteDetails" bundle:[NSBundle mainBundle]];
        siteView = [[SiteDetailsViewController alloc] initWithNibName:@"SiteDetails" bundle:[NSBundle mainBundle]];
        //[d release];
    }
    
    [self.navigationController pushViewController:siteView animated:YES];
    
}


#pragma mark - Destruction & House Keeping


- (void)dealloc
{
    [siteView release];
    [mapView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

//if ([CLLocationManager authorizationStatus] != KCLAuthorizationStatus Authorized){}
//UIAlertView* error = [[UIAlertView alloc] initWithTitle:@"oh hai!" 
//                                                message:@"MESSAGE" 
//                                               delegate:self 
//                                      cancelButtonTitle:@"OK" 
//                                      otherButtonTitles:nil];
//
//[error show];
//[error release];

@end























