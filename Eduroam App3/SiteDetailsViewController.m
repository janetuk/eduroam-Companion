//
//  SiteDetailsViewController.m
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

#import "SiteDetailsViewController.h"
#import "DatabaseManager.h"
#import "LocationManager.h"


@implementation SiteDetailsViewController

@synthesize siteID;
@synthesize scrollView;
@synthesize directionsButton;
//@synthesize tagButton;
@synthesize line;

@synthesize siteDataLabel;
@synthesize subsiteDataLabel;
@synthesize addressDataLabel;
@synthesize ssidDataLabel;
@synthesize encryptionDataLabel;

@synthesize subsiteStaticLabel;
@synthesize addressStaticLabel;
@synthesize ssidStaticLabel;
@synthesize encryptionStaticLabel;

//CONSTANTS
double MARGIN = 10;

//
DatabaseManager* dbManager;
LocationManager* locationManager;
bool needupdate = NO;

#pragma mark - Initialisation

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    scrollView.frame = CGRectMake(0, 0, 320, 367);
    [scrollView setContentSize:CGSizeMake(320, 713)];
    [self.view addSubview:scrollView];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background1.png"]];

}

//--------------------------------------------------------
// Called just before the view appears - put UI stuff here
//--------------------------------------------------------
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];

    if(needupdate){
        [self updateDisplay];
    }
    

}

#pragma mark - Update Display

//-----------------------------------------------
// Load a new siteID, and then update the display
//-----------------------------------------------
- (void)loadSite:(int)site{
    //Only update if it is necessary
    if (siteID != site) {
        siteID = site;
        needupdate = YES;
    }
}
 

//----------------------------------------------------
// Update the display
//----------------------------------------------------
- (void)updateDisplay {
    //Change the layout/size of uilabels by hand depending on the string content
    
    //////////
    //GET DATA
    //////////
    NSMutableArray* input = [[NSMutableArray alloc] init];
    NSNumber* number = [[NSNumber alloc] initWithInt:self.siteID];
    [input addObject:number];
    NSLog(@"SideID is: %d", siteID);
    NSDictionary* data = [dbManager selectQuery:@"SELECT Site.name, SubSites.name, SubSites.address, SubSites.ssid, SubSites.encryption FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id WHERE SubSites.id = ?" withParameters:input ofTypes:@"i" andColumnTypes:@"sssss"];
    [input release];
    [number release];
    if([[data objectForKey:@"error"] intValue] != 0){
        NSLog(@"UpdateDisplay error - code: %@", [data objectForKey:@"error"]);
        return;
    }
    
    //Get the data and store it sensibly
    NSDictionary* siteData = [data objectForKey:[NSNumber numberWithInt:0]];
    NSString* sitename = [siteData objectForKey:[NSNumber numberWithInt:0]];
    NSString* subsitename = [siteData objectForKey:[NSNumber numberWithInt:1]];
    NSString* address = [siteData objectForKey:[NSNumber numberWithInt:2]];
    NSString* ssid = [siteData objectForKey:[NSNumber numberWithInt:3]];
    NSString* encryption = [siteData objectForKey:[NSNumber numberWithInt:4]];
    
  
    //Find the width required of the static text
    CGSize staticSize = CGSizeMake(98, 22);     //The size of the static text frame
    double staticX = 20;                        //X origin of the static text frame
    double dataX = 118;                         //X origin of the data text frame
    
    //Variables keeping track of the y-origin of the next elements to draw
    double yorigin = 10.0;
    
    //Maximum size of the text area
    CGSize maxSize = CGSizeMake(280.0, MAXFLOAT);
    
    //Find the size of the sitename label
    CGSize labelsize = [sitename sizeWithFont:siteDataLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];

    //Configure the sitename
    siteDataLabel.frame = CGRectMake(20, yorigin, 280.0, labelsize.height + MARGIN);
    siteDataLabel.text = sitename;
    yorigin = yorigin + labelsize.height + (2*MARGIN);
    
    line.frame = CGRectMake(20, yorigin, line.frame.size.width, line.frame.size.height);
    

    yorigin = yorigin + line.frame.size.height + (2*MARGIN);
    
    //SubSiteName
    maxSize = CGSizeMake(182.0, MAXFLOAT);
    
    labelsize = [subsitename sizeWithFont:subsiteDataLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    subsiteStaticLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    subsiteDataLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    subsiteDataLabel.text = subsitename;
    
    //yorigin = yorigin + labelsize.height + (2*MARGIN);


    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);


    //Address
    if ([address isEqualToString: @","])
    {
        address = @"Address Unknown";
    }
    
    labelsize = [address sizeWithFont:addressDataLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    addressStaticLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    addressDataLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    addressDataLabel.text = address;
    
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);
    
    //SSID
    labelsize = [ssid sizeWithFont:ssidDataLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    ssidStaticLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    ssidDataLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    ssidDataLabel.text = ssid;
    
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);
    
    //Encryption
    labelsize = [encryption sizeWithFont:encryptionDataLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    encryptionStaticLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    encryptionDataLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    encryptionDataLabel.text = encryption;
    
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);
    
    yorigin = yorigin + (2*MARGIN);
    //Now to sort out the buttons
    directionsButton.frame = CGRectMake(50, yorigin, 220, 37);
    //tagButton.frame = CGRectMake(172, yorigin, 128, 37);
    yorigin = yorigin + directionsButton.frame.size.height + (4*MARGIN);
    
    //Set the height of the scrollview now
    [scrollView setContentSize:CGSizeMake(320, yorigin)];
    
}

# pragma mark - IBActions

- (IBAction)directionButtonPressed:(id)sender{
    
    //Get the location of the site
    NSString* query = @"SELECT lat, lng FROM SubSites WHERE id=?";
    NSMutableArray* parameters = [NSMutableArray array];
    [parameters addObject:[NSNumber numberWithInt:siteID]];
    
    NSMutableDictionary* data = [dbManager selectQuery:query withParameters:parameters ofTypes:@"i" andColumnTypes:@"dd"];
    if([[data objectForKey:@"error"] intValue] != 0){
        NSLog(@"Site details error - code: %@", [data objectForKey:@"error"]);
        return;
    }
    
    data = [data objectForKey:[NSNumber numberWithInt:0]];
    
    double lat = [[data objectForKey:[NSNumber numberWithInt:0]] doubleValue];
    double lng = [[data objectForKey:[NSNumber numberWithInt:1]] doubleValue];
    
    
    //Get the current user location
    if (locationManager == nil) {
        locationManager = [LocationManager sharedLocationManager];
    }
    
    CLLocation* currentLocation;
    currentLocation = [[locationManager getLocationManager] location];
    
    NSString* url = [NSString stringWithFormat:@"http://maps.google.com/maps?daddr=%f,%f", lat, lng];
    
    if (currentLocation != nil){
        url = [url stringByAppendingFormat:@"&saddr=%f,%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    }

    
    NSLog(@"String: %@", url);
    
    
    NSLog(@"Direction button pressed!");
    UIApplication *app = [UIApplication sharedApplication];
    [app openURL:[NSURL URLWithString: url]];   
}

- (IBAction)tagButtonPressed:(id)sender{
    
}



- (void)dealloc
{
    [scrollView release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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

@end
