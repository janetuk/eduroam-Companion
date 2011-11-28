//
//  MapKitDragAndDropViewController.h
//  MapKitDragAndDrop
//
//  Created by digdog on 11/1/10.
//  Copyright 2010 Ching-Lan 'digdog' HUANG. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "LocationManager.h"
#import "NetworkJSONProtocol.h"


@interface TagCheckLocationViewController : UIViewController <MKMapViewDelegate, UIAlertViewDelegate ,CLLocationManagerDelegate, NetworkJSONProtocol> {

}

@property (nonatomic, retain) IBOutlet MKMapView* oMapView;
@property (nonatomic, retain) IBOutlet UIButton* oTagButton;
@property (nonatomic, retain) NSDictionary* site;


- (IBAction) tagButtonPressed:(id)sender;
- (void)receiveJSONDictionary:(NSMutableDictionary*)dictionary withID:(NSString*)identifier;



@end

