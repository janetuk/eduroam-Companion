//
//  TagViewController.h
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
#import "TagPickSiteViewController.h"
#import "GeneralButton.h"


@interface TagCheckSiteViewController : UIViewController <CLLocationManagerDelegate, UIAlertViewDelegate> {

}

@property (retain, nonatomic) IBOutlet UIScrollView* scrollView;
@property (retain, nonatomic) IBOutlet UILabel* siteNameLabel;
@property (retain, nonatomic) IBOutlet UILabel* subsiteNameLabel;
@property (retain, nonatomic) IBOutlet UIButton* checkSiteButton;
@property (retain, nonatomic) IBOutlet UIButton* nextButon;
@property (retain, nonatomic) IBOutlet UILabel* textLabel1;
@property (retain, nonatomic) IBOutlet UILabel* textLabel2;
@property (retain, nonatomic) IBOutlet UIView* noGPSView;

@property (assign, nonatomic) BOOL needToUpdate;
@property (assign, nonatomic) BOOL userSelected;
@property (retain, nonatomic) NSDictionary* selectedSite;


- (IBAction) checkSiteButtonClicked:(id)sender;
- (IBAction) nextButtonClicked:(id)sender;

- (double) radiansToDegrees:(double) radians;
- (double) degreesToRadians:(double) degrees;
- (double) getDistanceBetweenTwoPlaces:(double)lat1 andLng:(double)lng1 withPlaceTwo:(double)lat2 andLng:(double)lng2;
- (void)findNearestSite:(CLLocationCoordinate2D)coord;
- (void)updateDisplay;
- (void) userSelection:(NSDictionary*)site;





@end
