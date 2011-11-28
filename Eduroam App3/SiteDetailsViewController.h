//
//  SiteDetailsViewController.h
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


@interface SiteDetailsViewController : UIViewController {
    
    int siteID;
    IBOutlet UIScrollView* scrollView;
    IBOutlet UIButton* directionsButton;
    //IBOutlet UIButton* tagButton;
    IBOutlet UIView* line;
    
    //datalabels
    IBOutlet UILabel* siteDataLabel;
    IBOutlet UILabel* subsiteDataLabel;
    IBOutlet UILabel* addressDataLabel;
    IBOutlet UILabel* ssidDataLabel;
    IBOutlet UILabel* encryptionDataLabel;
    
    //Staticlabels
    IBOutlet UILabel* subsiteStaticLabel;
    IBOutlet UILabel* addressStaticLabel;
    IBOutlet UILabel* ssidStaticLabel;
    IBOutlet UILabel* encryptionStaticLabel;


    
}


- (IBAction) directionButtonPressed:(id)sender;
- (IBAction) tagButtonPressed:(id)sender;


@property (readonly, assign) int siteID;
@property (retain, nonatomic) UIScrollView* scrollView;
@property (retain, nonatomic) UIButton* directionsButton;
//@property (retain, nonatomic) UIButton* tagButton;
@property (retain, nonatomic) UIView* line;

@property (retain, nonatomic) UILabel* siteDataLabel;
@property (retain, nonatomic) UILabel* subsiteDataLabel;
@property (retain, nonatomic) UILabel* addressDataLabel;
@property (retain, nonatomic) UILabel* ssidDataLabel;
@property (retain, nonatomic) UILabel* encryptionDataLabel;

@property (retain, nonatomic) UILabel* subsiteStaticLabel;
@property (retain, nonatomic) UILabel* addressStaticLabel;
@property (retain, nonatomic) UILabel* ssidStaticLabel;
@property (retain, nonatomic) UILabel* encryptionStaticLabel;







//- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andSiteID:(int)site;
- (void)updateDisplay;
- (void)loadSite:(int)siteID;


@end
