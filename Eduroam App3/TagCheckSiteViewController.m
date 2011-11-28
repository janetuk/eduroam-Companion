//
//  TagViewController.m
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

#import "TagCheckSiteViewController.h"
#import "LocationManager.h"
#import "DatabaseManager.h"
#import "TagPickSiteViewController.h"
#import "TagCheckLocationViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "LoadOverlay.h"
#import "PermissionOverlay.h"



@interface TagCheckSiteViewController () {
    //CONSTANTS
    double kEarth_Radius;
    double kMargin;
    
    
    //INSTANCE VARIABLES
    LocationManager* locationManager;
    DatabaseManager* dbManager;
    TagPickSiteViewController* pickController;
    TagCheckLocationViewController* tagController;
    NSMutableArray* siteList;
    BOOL obtainingFix;
    LoadOverlay* loadOverlay;
    PermissionOverlay* permissionOverlay;

}
@end


@implementation TagCheckSiteViewController

@synthesize scrollView;
@synthesize subsiteNameLabel;
@synthesize siteNameLabel;
@synthesize checkSiteButton;
@synthesize nextButon;
@synthesize textLabel1;
@synthesize textLabel2;
@synthesize noGPSView;

@synthesize needToUpdate;
@synthesize userSelected;
@synthesize selectedSite;






//---------------------------------------------------------------
// Initialisation - Function not called as class is setup from IB
//---------------------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


//----------------------------------------------------------------------------------
// All initialisation in here as the view is loaded from the navigational controller
//----------------------------------------------------------------------------------
- (void) viewDidLoad{
    [super viewDidLoad];
    
    //Start with all things invisible
    [scrollView setHidden:YES];
    
    ///////////////
    //VARIABLE INIT
    ///////////////
    userSelected = NO;      //Flag for if the user has selected their own site to tag  
    obtainingFix = NO;      //Describes if the GPS is trying to get a fix on the current location (ie, there is no position data present)
    
    //CONSTANTS
    kEarth_Radius = 6371;
    kMargin = 10;
    
    
    //INSTANCE VARIABLES
    pickController = nil;
    tagController = nil;
    permissionOverlay = nil;

    

    /////////////////
    //LOCATION SET UP
    /////////////////
    locationManager = [LocationManager sharedLocationManager];

    
    /////////////////
    //DATABASE SET UP
    /////////////////
    dbManager = [DatabaseManager sharedDatabaseManager];
    
    
    /////////////
    //VIEW SET UP
    /////////////
    scrollView.frame = CGRectMake(0, 93, 320, 367);
    [scrollView setContentSize:CGSizeMake(320, 713)];
    [self.view addSubview:scrollView];
    
    [self.noGPSView setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.view addSubview:noGPSView];
    [noGPSView setHidden:YES];
    
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
    [self setTitle:@"Site To Tag"];
    self.navigationController.title = @"Tag";
    
    [self.navigationItem.backBarButtonItem release];
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                     style: UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background1.png"]];
     
}



//- (void) viewDidAppear:(BOOL)animated{
//    [super viewDidAppear:animated];
//
//}


- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //////////////////
    //CHECK PERMISSION
    //////////////////
    if(permissionOverlay == nil){
        permissionOverlay = [[PermissionOverlay alloc] initWithFrame:self.view.frame];
        [self.view addSubview:permissionOverlay];
    }

    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    int permission = [[defaults objectForKey:@"permission"] intValue];

    //sort the permission bit out
    if(permission == 1){
        
        [permissionOverlay hide];
    
        
        /////////////////
        //LOCATION SET UP
        /////////////////
        locationManager.manager.delegate = self;
        [locationManager.manager startUpdatingLocation];
        
        if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
            UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disallowed" 
                                                                        message:@"You have not given this application permission to use Location Services. To tag, your location must be known. Please go to the iPhone settings and allow this application to access Location Services" 
                                                                       delegate:self 
                                                              cancelButtonTitle:@"OK" 
                                                              otherButtonTitles:nil];
            [disconnectedAlert show];
            [disconnectedAlert release];
            
        } else {
            [self.noGPSView setHidden:YES];
            if (locationManager.manager.location == nil) {
                //No Location data available, display load overlay, set pin to default
                
                obtainingFix = YES;
                if (loadOverlay == nil) {
                    loadOverlay = [[LoadOverlay alloc] initWithFrame:self.view.frame];
                    [loadOverlay updateText:@"Obtaining Your Position"];
                }
                [self.view addSubview:loadOverlay];
                [loadOverlay show];
                
            } else {
                [self findNearestSite:locationManager.manager.location.coordinate];
                [self updateDisplay];
            }
        }
    } else {
        //Permission is not given, display the overlay
        [permissionOverlay show];
        UIAlertView* msg = [[UIAlertView alloc] initWithTitle:@"Permission to Tag" 
                                                                    message:@"You need to give permission to tag your location. Please go to the application settings to give permission" 
                                                                   delegate:self 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
        [msg show];
        [msg release];
    }
    
}





#pragma mark - IBActions

//----------------------------------------------------------------
// Load up the table view of all sites to allow for user selection
//----------------------------------------------------------------
- (IBAction) checkSiteButtonClicked:(id)sender{
    
    if(pickController == nil){
        pickController = [[TagPickSiteViewController alloc] initWithNibName:@"TagPickSiteViewController" bundle:[NSBundle mainBundle] andParentController:self];
    }
    
    [pickController refreshTableWithArray:siteList];
    [self.navigationController pushViewController:pickController animated:YES];

}

- (IBAction) nextButtonClicked:(id)sender{
    
    if (tagController == nil) {
        tagController = [[TagCheckLocationViewController alloc] initWithNibName:@"TagCheckLocationViewController" bundle:[NSBundle mainBundle]];
    }
    
    tagController.site = selectedSite;
    [self.navigationController pushViewController:tagController animated:YES];

}

//-----------------------------------------------------------------
// AlertView delegate method - deal with user action on alert views
//-----------------------------------------------------------------
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.title == @"Location Services Disallowed") {
        //No GPS :(
        [self.noGPSView setHidden:NO];
    }
    
}

//------------------------------------------------------
// Receive data from table view, storing the site
//------------------------------------------------------
- (void) userSelection:(NSDictionary*)site{
    selectedSite = site;
    userSelected = YES;
    [self updateDisplay];
}



#pragma mark - Location

//---------------------------------------------------
// When the User's location has changed
//---------------------------------------------------
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    [self.noGPSView setHidden:YES];

    //get rid of load overlay if it is on
    if (obtainingFix) {
        obtainingFix = NO;
        [loadOverlay hide];
    }
    
    [self findNearestSite:newLocation.coordinate];
    [self updateDisplay];
}

#pragma mark - View Actions

//-----------------------------------------------
// Create nearest-first list of sites, update the dispaly
//-----------------------------------------------
- (void)updateDisplay{
    

    
    //Local variables
    double yorigin = kMargin;
    CGSize maxSize = CGSizeMake(280.0, MAXFLOAT);
    CGSize viewSize;
        
//    //Title
//    viewSize = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
//    titleLabel.frame = CGRectMake(20, yorigin, 280.0, viewSize.height);    
//    yorigin = yorigin + viewSize.height + (kMargin);
//    
//    //Line
//    lineView.frame = CGRectMake(20, yorigin, lineView.frame.size.width, lineView.frame.size.height);
//    yorigin = yorigin + (kMargin);
    
    //Text Label 1
    viewSize = [textLabel1.text sizeWithFont:textLabel1.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    textLabel1.frame = CGRectMake(20, yorigin, 280.0, viewSize.height);
    yorigin = yorigin + viewSize.height + (kMargin);
    
    //Site Name
    NSString* siteName = [selectedSite objectForKey:[NSNumber numberWithInt:0]];
    viewSize = [siteName sizeWithFont:siteNameLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    siteNameLabel.frame = CGRectMake(20.0, yorigin, 280.0, viewSize.height);
    siteNameLabel.text = siteName;
    yorigin = yorigin + viewSize.height;
    
    //Sub Site Name
    NSString* subSiteName = [selectedSite objectForKey:[NSNumber numberWithInt:1]];
    viewSize = [subSiteName sizeWithFont:subsiteNameLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    subsiteNameLabel.frame = CGRectMake(20.0, yorigin, 280.0, viewSize.height);
    subsiteNameLabel.text = subSiteName;
    yorigin = yorigin + viewSize.height + (2*kMargin);
    
    //Pick site button
    checkSiteButton.frame = CGRectMake(48, yorigin, 224, 37.0);
    yorigin = yorigin + checkSiteButton.frame.size.height + (2*kMargin);
    
    //Text Label 2
    viewSize = [textLabel2.text sizeWithFont:textLabel2.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    textLabel2.frame = CGRectMake(20, yorigin, 280.0, viewSize.height);
    yorigin = yorigin + viewSize.height + (3*kMargin);

    
    //Next Button
    nextButon.frame = CGRectMake(48, yorigin, 224, 37.0);
    yorigin = yorigin + nextButon.frame.size.height + (3*kMargin);
    
    [scrollView setContentSize:CGSizeMake(320, yorigin)];
    [scrollView setHidden:NO];
}


//-------------------------------------------------------
// Returns the id of the nearest subsite given a location
//-------------------------------------------------------
- (void)findNearestSite:(CLLocationCoordinate2D)coord{
    

    
    int n = 50;
    
    NSString* query = @"SELECT Site.name, SubSites.name, SubSites.lat, SubSites.lng, SubSites.id FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id ORDER BY (ABS(lat - ?) + ABS(lng - ?)) ASC LIMIT ?";
    NSMutableArray* parameters = [NSMutableArray array];
    [parameters addObject:[NSNumber numberWithDouble:coord.latitude]];
    [parameters addObject:[NSNumber numberWithDouble:coord.longitude]];
    [parameters addObject:[NSNumber numberWithInt:n]];
    
    NSMutableDictionary* data = [dbManager selectQuery:query withParameters:parameters ofTypes:@"ddi" andColumnTypes:@"ssddi"];
    
    if([[data objectForKey:@"error"] intValue]!= 0){
        //something went wrong
        NSLog(@"Error 001: SQLite Query failed to get nearest sites with error code %@", [data objectForKey:@"error"]);
        return;
    }
    
    [data removeObjectForKey:@"size"];
    [data removeObjectForKey:@"error"];
    //calcualte the distance between each point using the haversine formula, which gives a distance in Km
    NSEnumerator* e = [[data allValues] objectEnumerator];
    NSMutableDictionary* site;
    
    //radius of the earth in Km
    while ((site = [e nextObject])) {
        
        double siteLat = [[site objectForKey:[NSNumber numberWithInt:2]] doubleValue];
        double siteLng = [[site objectForKey:[NSNumber numberWithInt:3]] doubleValue];
        
        [site setValue:[NSNumber numberWithDouble:[self getDistanceBetweenTwoPlaces:coord.latitude andLng:coord.longitude withPlaceTwo:siteLat andLng:siteLng]] forKey:@"distance"];        
    }
    
    //Sort them into an array
    NSMutableArray* orderedList = [[NSMutableArray alloc] initWithCapacity:n];
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
    
    if (userSelected == NO) {
        self.selectedSite = [orderedList objectAtIndex:0];
    }
    
    siteList = orderedList;

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
    double d = kEarth_Radius * c;
    
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

#pragma mark - View lifecycle

- (void)dealloc
{
    [pickController release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

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

@end
