//
//  SiteSelectionViewController.h
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

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "sqlite3.h"
#import "NetworkManager.h"
#import "NetworkJSON.h"
#import "NetworkJSONProtocol.h"
#import "APDetailsViewController.h"

@class SiteDetailsViewController;

@interface SiteSelectionViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UISearchDisplayDelegate, NetworkJSONProtocol> {
    
    NSString* startKey;
    double rating;
    APDetailsViewController* apView;
    MKAnnotationView* currentLocationView;
}

@property (nonatomic, retain) IBOutlet MKMapView* mapView;
@property (nonatomic, retain) IBOutlet UIView* secondView;
@property (nonatomic, retain) IBOutlet UITableView* tableView;
@property (nonatomic, retain) IBOutlet UISearchBar* searchBarTable;
@property (nonatomic, retain) IBOutlet UISearchBar* searchBarMap;
@property (nonatomic, retain) IBOutlet UIView* firstView;
@property (nonatomic, retain) UIColor* eduroamDarkBlue;
@property (nonatomic, assign) MKCoordinateRegion previousUpdateRegion;
@property (assign, nonatomic) BOOL updating;
@property (retain, nonatomic) NetworkJSON* jsonUpdateAP;
@property (retain, nonatomic) NetworkJSON* jsonSearch;
@property (retain, nonatomic) NSMutableArray* nearestSites;



- (IBAction) buttonPress:(id)sender;

- (NSMutableDictionary*) getSiteAnnotations;
- (NSMutableDictionary*) getAPAnnotations;
- (void) updateAnnotations;
- (NSString* ) getFilePath;
- (void)toggleButtonClicked;
- (void)locateButtonClicked;
- (NSArray*) getNearestSites:(int)n fromLat:(double)lat andLng:(double)lng;
- (void)filterSitesForSearchText:(NSString*)searchText;
- (double) getDistanceBetweenTwoPlaces:(double)lat1 andLng:(double)lng1 withPlaceTwo:(double)lat2 andLng:(double)lng2;
- (void) centerOnUser; 
- (void) startAPUpdate:(MKCoordinateRegion)region;
- (void) sendForAPUpdate;
- (NSString *) rot13String:(NSString*)input;
- (void) applyAPUpdate:(NSDictionary*)data;
- (void) mapRefresh;
- (void) dealWithSearchResults:(NSMutableDictionary*)data;
- (NSString*) textToHTML:(NSString*)inputString;




- (double) degreesToRadians:(double) degrees;
- (double) radiansToDegrees:(double) radians;


@end
