//
//  APDetailsViewController.m
//  Eduroam App3
//
//  Created by Ashley Browning on 24/04/2011.
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

#import "APDetailsViewController.h"
#import "DatabaseManager.h"
#import "LocationManager.h"


@interface APDetailsViewController (){
    
    
    //CONSTANTS
    double MARGIN;
    
    //INSTANCE VARIABLES
    int apID;
    DatabaseManager* dbManager;
    LocationManager* locationManager;
    bool needupdate;
    
}
@end



@implementation APDetailsViewController

@synthesize titleLabel;
@synthesize colourStrip;
@synthesize directionButton;
@synthesize scrollView;

@synthesize staticSiteLabel;
@synthesize staticAddressLabel;
@synthesize staticSSIDLabel;
@synthesize staticEncryptionLabel;
@synthesize staticConfidenceLabel;
@synthesize staticDateLabel;

@synthesize dataSiteLabel;
@synthesize dataSubSiteLabel;
@synthesize dataAddressLabel;
@synthesize dataSSIDLabel;
@synthesize dataEncryptionLabel;
@synthesize dataConfidenceLabel;
@synthesize dataDateLabel;




- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        needupdate = NO;
        apID = -1;
        dbManager = [DatabaseManager sharedDatabaseManager];
        MARGIN = 10;
    }
    return self;
}


- (void) viewDidLoad{
    [super viewDidLoad];

    ////////////////////
    //INSTANCE VARIABLES
    ////////////////////


    
    //Set up the view
    scrollView.frame = CGRectMake(0, 0, 320, 367);
    [scrollView setContentSize:CGSizeMake(320, 713)];
    [self.view addSubview:scrollView];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background1.png"]];

    
}


//View is about to appear
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSLog(@"apdetails view will appear");
    if(needupdate){
        NSLog(@"In needupdate");
        [self updateDisplay];
    }
    
    
}



//FINISH THIS CLASS OFF


- (void)updateDisplay{
    
    //////////
    //GET DATA
    //////////
    NSLog(@"in the update dispaly bit");
    
    NSString* query = @"SELECT subsite, rating, strftime(\"%s\", lastUpdate) FROM APs WHERE id = ?";
    NSMutableArray* parameters = [NSMutableArray array];
    [parameters addObject:[NSNumber numberWithInt:apID]];
    NSMutableDictionary* data = [dbManager selectQuery:query withParameters:parameters ofTypes:@"i" andColumnTypes:@"idi"];
    if([[data objectForKey:@"error"] intValue] != 0){
        NSLog(@"UpdateDisplay error - code: %@", [data objectForKey:@"error"]);
        return;
    }
    NSDictionary* apData = [data objectForKey:[NSNumber numberWithInt:0]];
    int subsite = [[apData objectForKey:[NSNumber numberWithInt:0]] intValue];
    double rating = [[apData objectForKey:[NSNumber numberWithInt:1]] doubleValue];
    int unixdate = [[apData objectForKey:[NSNumber numberWithInt:2]] intValue];
    
    
    NSNumberFormatter* maxTwoDecimalPlaces = [[[NSNumberFormatter alloc] init] autorelease];
    [maxTwoDecimalPlaces setNumberStyle:NSNumberFormatterDecimalStyle];
    [maxTwoDecimalPlaces setMaximumFractionDigits:2];
    
    
    //NSLog(@"got data: %d, %f, %d", subsite, rating, unixdate);
    
    //Get the site information
    query = @"SELECT Site.name, SubSites.name, SubSites.address, SubSites.ssid, SubSites.encryption FROM SubSites LEFT JOIN Site ON SubSites.site=Site.id WHERE SubSites.id = ?";
    [parameters removeAllObjects];
    [parameters addObject:[NSNumber numberWithInt:subsite]];
    data = [dbManager selectQuery:query withParameters:parameters ofTypes:@"i" andColumnTypes:@"sssss"];
    if([[data objectForKey:@"error"] intValue] != 0){
        NSLog(@"UpdateDisplay error - code: %@", [data objectForKey:@"error"]);
        return;
    }
    
    NSDictionary* siteData = [data objectForKey:[NSNumber numberWithInt:0]];
    NSString* siteName = [siteData objectForKey:[NSNumber numberWithInt:0]];
    NSString* subSiteName = [siteData objectForKey:[NSNumber numberWithInt:1]];
    NSString* address = [siteData objectForKey:[NSNumber numberWithInt:2]];
    NSString* ssid = [siteData objectForKey:[NSNumber numberWithInt:3]];
    NSString* encryption = [siteData objectForKey:[NSNumber numberWithInt:4]];
    //NSString* confidence = [NSString stringWithFormat:@"%f", rating];
    float confidenceRating = rating * 100.0;
    NSString* confidence = [NSString stringWithFormat:@"%@%%", [maxTwoDecimalPlaces stringFromNumber:[NSNumber numberWithDouble:confidenceRating]]];
    
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:unixdate];
    NSDateFormatter* dateFormat = [[[NSDateFormatter alloc] init] autorelease];
    [dateFormat setDateFormat:@"dd-MM-yyyy HH:mm"];
    NSString* dateString = [dateFormat stringFromDate:date];
    
    
    
    //[maxTwoDecimalPlaces release];
    //maxTwoDecimalPlaces = nil;
    
    //NSLog(@"Date is: %@", date);

    
    ///////////////////
    //MANAGE THE LAYOUT
    ///////////////////
    
    
    //Find the width required of the static text
    CGSize staticSize = CGSizeMake(98, 22);     //The size of the static text frame
    double staticX = 20;                        //X origin of the static text frame
    double dataX = 118;                         //X origin of the data text frame
    
    //Variables keeping track of the y-origin of the next elements to draw
    double yorigin = 10.0;
    
    //Maximum size of the text area
    CGSize maxSize = CGSizeMake(280.0, MAXFLOAT);
    
    //Find the size of the title label
    CGSize labelsize = [titleLabel.text sizeWithFont:titleLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    titleLabel.frame = CGRectMake(20, yorigin, 280.0, labelsize.height + MARGIN);
    yorigin = yorigin + labelsize.height + (2*MARGIN);
    
    //line/strip
    colourStrip.frame = CGRectMake(20, yorigin, colourStrip.frame.size.width, colourStrip.frame.size.height);
    yorigin = yorigin + colourStrip.frame.size.height + (2*MARGIN);
    
    //New max size for the data labels
    maxSize = CGSizeMake(182.0, MAXFLOAT);
    
    //Site
    labelsize = [siteName sizeWithFont:dataSiteLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    staticSiteLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    dataSiteLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    dataSiteLabel.text = siteName;
    yorigin = yorigin + labelsize.height + MARGIN;
    
    //Subsite
    labelsize = [subSiteName sizeWithFont:dataSubSiteLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    dataSubSiteLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    dataSubSiteLabel.text = subSiteName;
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);
    
    //address
    labelsize = [address sizeWithFont:dataAddressLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    staticAddressLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    dataAddressLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    dataAddressLabel.text = address;
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);
    
    //ssid
    labelsize = [ssid sizeWithFont:dataSSIDLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    staticSSIDLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    dataSSIDLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    dataSSIDLabel.text = ssid;
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);
    
    //Encryption
    labelsize = [encryption sizeWithFont:dataEncryptionLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    staticEncryptionLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, staticSize.height + MARGIN);
    dataEncryptionLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    dataEncryptionLabel.text = encryption;
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);    
    
    
    //Confidence 
    labelsize = [confidence sizeWithFont:dataConfidenceLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    staticConfidenceLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, labelsize.height + MARGIN);
    dataConfidenceLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    dataConfidenceLabel.text = confidence;
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);
    
    
    //Date
    labelsize = [dateString sizeWithFont:dataDateLabel.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeWordWrap];
    staticDateLabel.frame = CGRectMake(staticX, yorigin, staticSize.width, labelsize.height + MARGIN);
    dataDateLabel.frame = CGRectMake(dataX, yorigin, maxSize.width, labelsize.height + MARGIN);
    dataDateLabel.text = dateString;
    yorigin = (labelsize.height + (2*MARGIN) > staticSize.height + (2*MARGIN)) ? yorigin + labelsize.height + (2*MARGIN) : yorigin + staticSize.height + (2*MARGIN);    
    
    
    yorigin = yorigin + (2*MARGIN);
    //Now to sort out the buttons
    directionButton.frame = CGRectMake(50, yorigin, 220, 37);
    //tagButton.frame = CGRectMake(172, yorigin, 128, 37);
    yorigin = yorigin + directionButton.frame.size.height + (4*MARGIN);
    
    //Set the height of the scrollview now
    [scrollView setContentSize:CGSizeMake(320, yorigin)];    
    
    
}

//Give the controller a new AP to display
- (void)loadAP:(int)ap{
    //Only update if it is necessary
    NSLog(@"loadAP");
    if (ap != apID) {
        NSLog(@"changing ap");
        apID = ap;
        needupdate = YES;
    }
}


//-----------------------------------------------------
// Direction button pressed, load google maps with data
//-----------------------------------------------------
- (IBAction) directionButtonPressed:(id)sender{
    
    //Get the location of the site
    NSString* query = @"SELECT lat, lng FROM APs WHERE id=?";
    NSMutableArray* parameters = [NSMutableArray array];
    [parameters addObject:[NSNumber numberWithInt:apID]];
    
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
    

    UIApplication *app = [UIApplication sharedApplication];
    [app openURL:[NSURL URLWithString: url]];    
}






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

#pragma mark - View lifecycle



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
