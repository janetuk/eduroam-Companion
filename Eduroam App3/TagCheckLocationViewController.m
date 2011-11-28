//
//  MapKitDragAndDropViewController.m
//  MapKitDragAndDrop
//
//  Created by digdog on 11/1/10.
//  Copyright 2010 Ching-Lan 'digdog' HUANG. All rights reserved.
//

#import "TagCheckLocationViewController.h"
#import "DDAnnotation.h"
#import "DDAnnotationView.h"
#import "NetworkJSON.h"
#import "NetworkManager.h"
#import "LoadOverlay.h"


@interface TagCheckLocationViewController () {
    
    DDAnnotation* currentLocation;
    BOOL userHasMovedPin;       //If the user has moved the pin, do not update the location of the pin
    BOOL userHasMovedView;      //If the user has moved the view, then do not centre on the current location
    BOOL justCentered;          //Used to distinguish between a user action and a center action on the map view
    BOOL obtainingFix;          //Used to identify when the loading view is there because it is obtaining a fix <<<< TODO
    LocationManager* locationManager;
    LoadOverlay* loadOverlay;
    
    double USER_ACCURACY;  //Used to describe the accuracy (in meters) of the user when they have moved the pin
}

@property (retain, nonatomic) NetworkJSON* jsonWorker;



- (void)coordinateChanged_:(NSNotification *)notification;
- (void)centreMapOnUser;
- (NSString*) getUserID;
- (NSString *) rot13String:(NSString*)input;


    
@end

@implementation TagCheckLocationViewController

@synthesize oMapView;
@synthesize oTagButton;
@synthesize site;
@synthesize jsonWorker;



#pragma mark - Initialise View
//---------------------------------------------------
// Initialise the view and variables
//---------------------------------------------------
- (void)viewDidLoad {
    [super viewDidLoad];
    
    /////////////////
    //LOCATION SET UP
    /////////////////
    locationManager = [LocationManager sharedLocationManager];

    ////////////////
    //NETWORK SET UP
	////////////////
    self.jsonWorker = [NetworkManager getJSONObject:@"https://eduroam-app-api.dev.ja.net/v1.0/live/tag.php" withDelegate:self];

    /////////////////////////
    //VARIABLE INITIALISATION
    /////////////////////////

    loadOverlay = nil;
    USER_ACCURACY = 10;

    /////////////////////
    //VIEW INITIALISATION
    /////////////////////
    self.navigationItem.title = @"Select Location";
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background1.png"]];

    
}

- (void)viewWillAppear:(BOOL)animated{
    
    //Location set up
    [super viewWillAppear:animated];
	
    userHasMovedPin = NO;
    userHasMovedView = NO;
    justCentered = NO;
    obtainingFix = NO;
    locationManager.manager.delegate = self;
    [locationManager.manager startUpdatingLocation];

    
	// NOTE: This is optional, DDAnnotationCoordinateDidChangeNotification only fired in iPhone OS 3, not in iOS 4.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(coordinateChanged_:) name:@"DDAnnotationCoordinateDidChangeNotification" object:nil];
    
        
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorized) {
        UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disallowed" 
                                                                    message:@"You have not given this application permission to use Location Services. To tag, your location must be known. Please go to the iPhone settings and allow this application to access Location Services" 
                                                                   delegate:self 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
        [disconnectedAlert show];
        [disconnectedAlert release];
        
    }
    
    
    if (locationManager.manager.location == nil) {
        //No Location data available, display load overlay, set pin to default
        CLLocationCoordinate2D theCoordinate;
        theCoordinate.latitude = 51.08011;
        theCoordinate.longitude = -1.46006;
        
        currentLocation = [[DDAnnotation alloc] initWithCoordinate:theCoordinate addressDictionary:nil];
        currentLocation.title = @"Hold and Drag to Move Pin";
        currentLocation.subtitle = [NSString stringWithFormat:@"Lat:%f Lng:%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
        
        obtainingFix = YES;
        NSLog(@"Obtaining a fix");
        if (loadOverlay == nil) {
            loadOverlay = [[LoadOverlay alloc] initWithFrame:self.view.frame];
            [loadOverlay updateText:@"Obtaining Your Position"];
        }
        [self.view addSubview:loadOverlay];
        [loadOverlay show];
        
    } else {
        currentLocation = [[DDAnnotation alloc] initWithCoordinate:locationManager.manager.location.coordinate addressDictionary:nil];
        currentLocation.title = @"Hold and Drag to Move Pin";
        currentLocation.subtitle = [NSString stringWithFormat:@"Lat:%f Lng:%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
    }

	[self.oMapView addAnnotation:currentLocation];	
    [self centreMapOnUser];
    
}

//---------------------------------
// The view is about to disappear,
//----------------------------------
- (void) viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
    locationManager.manager.delegate = nil;
	
	
	// NOTE: This is optional, DDAnnotationCoordinateDidChangeNotification only fired in iPhone OS 3, not in iOS 4.
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DDAnnotationCoordinateDidChangeNotification" object:nil];	
    
    if(currentLocation != nil){
        [oMapView removeAnnotation:currentLocation];
    }
}

#pragma mark - Map
//--------------------------------------------------------------------
// Map has moved view, but need to determine if it is the user's doing
//--------------------------------------------------------------------
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    if (justCentered) {
        justCentered = NO;
    } else {
        //User has moved the map view, flag it
        userHasMovedView = YES;
    }
}

//-------------------------------------------------------------
// Called when the user selects a pin/anotation view on the map
//-------------------------------------------------------------
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    
    //Make sure that it is the current location pin we are dealing with
    if(currentLocation != nil){
        if (currentLocation == view.annotation) {
            //Because the user has touched the pin, stop it from moving around!
            userHasMovedPin = YES;
            NSLog(@"user has touched the pin!");
        }
    }
    
}




#pragma mark - Location
/////////////////////////////////////////
//Called when the user has moved location
/////////////////////////////////////////
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
    
    //Do not move the pin if the user has already done so
    NSLog(@"new location found");
    if (![loadOverlay isHidden]) {
        [loadOverlay hide];
        obtainingFix = NO;
    } 

    if (!userHasMovedPin) {
        
        NSLog(@"user has not moved the pin");

        if(currentLocation != nil){
            [oMapView removeAnnotation:currentLocation];
        }
        
        [currentLocation release];
        currentLocation = [[DDAnnotation alloc] initWithCoordinate:newLocation.coordinate addressDictionary:nil];
        currentLocation.title = @"Hold and Drag to Move Pin";
        currentLocation.subtitle = [NSString stringWithFormat:@"Lat:%f Lng:%f", currentLocation.coordinate.latitude, currentLocation.coordinate.longitude];
        [oMapView addAnnotation:currentLocation];

        //Do not update the view if the user has moved it
     
        if (!userHasMovedView){
            NSLog(@"centering on location");
            [self centreMapOnUser];
        }
    }
    
}

//------------------------------------------
//Center map view on user's current location
//------------------------------------------
- (void)centreMapOnUser{
    
    MKCoordinateRegion region;
    
    region.center = currentLocation.coordinate;
    region.span.latitudeDelta = 0.002;
    region.span.longitudeDelta = 0.002;
    
    justCentered = YES;
    
    [oMapView setRegion:region animated:YES];
    
}


#pragma mark - User Interaction
//--------------------------------------------------------
// Start tagging process and communicating with the server
//--------------------------------------------------------
- (IBAction) tagButtonPressed:(id)sender{
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    NSString* startKey = @"hVKPZAghhSfZJfFybmiqJEDAoUrPMqGRPxGMKKSFRbBPgCnDEhZnCPmnLJjKTqTh";
        
    [parameters setObject:@"1" forKey:@"msg"];
    [parameters setObject:[self getUserID] forKey:@"user"];
    [parameters setObject:[NSString stringWithFormat:@"%f", currentLocation.coordinate.latitude] forKey:@"lat"];
    [parameters setObject:[NSString stringWithFormat:@"%f", currentLocation.coordinate.longitude] forKey:@"lng"];
    [parameters setObject:[NSString stringWithFormat:@"%@", [site objectForKey:[NSNumber numberWithInt:4]]]forKey:@"site"];
    [parameters setObject:[self rot13String:startKey] forKey:@"key"];
    if (userHasMovedPin) {
        [parameters setObject:[NSString stringWithFormat:@"%f", USER_ACCURACY] forKey:@"accuracy"];
    } else {
        [parameters setObject:[NSString stringWithFormat:@"%f", locationManager.manager.location.horizontalAccuracy] forKey:@"accuracy"];
    }


    
    int outcome = [jsonWorker getJSON:@"test" withParameters:parameters];
    switch (outcome) {
        case 0:
            //Went well, sending data, display sending screen
            if (loadOverlay == nil) {
                loadOverlay = [[LoadOverlay alloc] initWithFrame:self.view.frame];
                [loadOverlay updateText:@"Sending"];
            }
            [self.view addSubview:loadOverlay];
            [loadOverlay show];
            
            break;
        case 1:{
            UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"No Connection" 
                                                                        message:@"You are currently not connected to the Internet. Please obtain a connection and try tagging again" 
                                                                       delegate:self 
                                                              cancelButtonTitle:@"OK" 
                                                              otherButtonTitles:nil];
            [disconnectedAlert show];
            [disconnectedAlert release];
        }
            break;
        default:
            break;
    }
    
}

//----------------------------------------
// Return the hashed user id of the device
//----------------------------------------
- (NSString*) getUserID{
    NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDir = [paths objectAtIndex:0];
    NSString* filePath = [documentsDir stringByAppendingPathComponent:@"user.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:documentsDir]) {
        NSDictionary *dict = [[[NSDictionary alloc] initWithContentsOfFile:filePath] autorelease];
        return [dict objectForKey:@"hashID"];
    } else {
        return nil;
    }
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


//---------------------------------
// Deal with alert view interaction
//---------------------------------
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.title == @"No Connection") {
        //There is no connection!
    }
    
    if (alertView.title == @"Location Services Disallowed"){
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    if (alertView.title == @"Success"){
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - Network
//-----------------------------
//Receive data from JSON object
//-----------------------------
- (void)receiveJSONDictionary:(NSMutableDictionary*)dictionary withID:(NSString*)identifier{
    NSLog(@"Data:%@", dictionary);
    int code = [[[dictionary objectForKey:@"rcode"] objectForKey:@"code"] intValue];
    NSLog(@"Rcode: %d", code);
    
    switch (code) {
        case 14:{
            //this is where the user has tagged too many times for one day
            [loadOverlay hide];
            UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"Too Many Tags" 
                                                                        message:@"You have reached the maximum number of tags you can submit today! Thank you for your enthusiasm though!" 
                                                                       delegate:self 
                                                              cancelButtonTitle:@"OK" 
                                                              otherButtonTitles:nil];
            [disconnectedAlert show];
            [disconnectedAlert release];
        }
            break;
        case 19:{
            [loadOverlay hide];
            UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"Success" 
                                                                        message:@"You have successfully tagged your location! Thank you for helping to improve this service" 
                                                                       delegate:self 
                                                              cancelButtonTitle:@"OK" 
                                                              otherButtonTitles:nil];
            [disconnectedAlert show];
            [disconnectedAlert release]; 
            
        }
            break;
        default:{
            [loadOverlay hide];
            UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"An Issue Has Occured" 
                                                                        message:@"Something went wrong with tagging your location. Please try again" 
                                                                       delegate:self 
                                                              cancelButtonTitle:@"OK" 
                                                              otherButtonTitles:nil];
            [disconnectedAlert show];
            [disconnectedAlert release];             
        }
            break;
    }
}

//---------------------------------------------------------------
// If there is an error with the connection, this method is fired
//---------------------------------------------------------------
- (void)receiveConnectionError:(NSString *)identifier{
    [loadOverlay hide];
    UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"Connection Problem" 
                                                                message:@"There has been an issue communicating with the server. Please try again" 
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
    [disconnectedAlert show];
    [disconnectedAlert release];     
}

//-----------------------------------------------------------------------
// Did receive a response, but not in JSON format, means server is faulty
//-----------------------------------------------------------------------
- (void)receiveJSONError:(NSString *)identifier{
    [loadOverlay hide];
    UIAlertView* disconnectedAlert = [[UIAlertView alloc] initWithTitle:@"Server Problem" 
                                                                message:@"There is an issue with the server. Please try again later" 
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
    [disconnectedAlert show];
    [disconnectedAlert release]; 
}

#pragma mark - DDAnnotationCoordinateDidChangeNotification

// NOTE: DDAnnotationCoordinateDidChangeNotification won't fire in iOS 4, use -mapView:annotationView:didChangeDragState:fromOldState: instead.
- (void)coordinateChanged_:(NSNotification *)notification {
	
	DDAnnotation *annotation = notification.object;
	annotation.subtitle = [NSString	stringWithFormat:@"Lat:%f Lng:%f", annotation.coordinate.latitude, annotation.coordinate.longitude];
}

#pragma mark - MKMapViewDelegate
//--------------------------------------------------------
// Called when an anootation view's drag state has changed
//--------------------------------------------------------
- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
	
    
	if (oldState == MKAnnotationViewDragStateDragging) {

        //user has moved the pin, so set the boolean flag
        userHasMovedPin = YES;
		
        DDAnnotation *annotation = (DDAnnotation *)annotationView.annotation;
		annotation.subtitle = [NSString	stringWithFormat:@"Lat:%f Lng:%f", annotation.coordinate.latitude, annotation.coordinate.longitude];		
	}
}

//--------------------------------
// Draw an annotation for the view
//--------------------------------
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {

    
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;		
	}
	
	static NSString * const kPinAnnotationIdentifier = @"PinIdentifier";
	MKAnnotationView *draggablePinView = [self.oMapView dequeueReusableAnnotationViewWithIdentifier:kPinAnnotationIdentifier];
	
	if (draggablePinView) {
		draggablePinView.annotation = annotation;
	} else {
		// Use class method to create DDAnnotationView (on iOS 3) or built-in draggble MKPinAnnotationView (on iOS 4).
		draggablePinView = [DDAnnotationView annotationViewWithAnnotation:annotation reuseIdentifier:kPinAnnotationIdentifier mapView:self.oMapView];
        
		if ([draggablePinView isKindOfClass:[DDAnnotationView class]]) {
			// draggablePinView is DDAnnotationView on iOS 3.
		} else {
			// draggablePinView instance will be built-in draggable MKPinAnnotationView when running on iOS 4.
		}
	}		
	
	return draggablePinView;
}


#pragma mark - View Lifecycle




// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	
	self.oMapView.delegate = nil;
	self.oMapView = nil;
}

- (void)dealloc {
	oMapView.delegate = nil;
	[oMapView release];
    [super dealloc];
}

@end
