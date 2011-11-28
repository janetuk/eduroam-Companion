//
//  APDetailsViewController.h
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

#import <UIKit/UIKit.h>


@interface APDetailsViewController : UIViewController {
    
    
}



@property (retain, nonatomic) IBOutlet UILabel* titleLabel;
@property (retain, nonatomic) IBOutlet UIView* colourStrip;
@property (retain, nonatomic) IBOutlet UIButton* directionButton;
@property (retain, nonatomic) IBOutlet UIScrollView* scrollView;

@property (retain, nonatomic) IBOutlet UILabel* staticSiteLabel;
@property (retain, nonatomic) IBOutlet UILabel* staticAddressLabel;
@property (retain, nonatomic) IBOutlet UILabel* staticSSIDLabel;
@property (retain, nonatomic) IBOutlet UILabel* staticEncryptionLabel;
@property (retain, nonatomic) IBOutlet UILabel* staticConfidenceLabel;
@property (retain, nonatomic) IBOutlet UILabel* staticDateLabel;

@property (retain, nonatomic) IBOutlet UILabel* dataSiteLabel;
@property (retain, nonatomic) IBOutlet UILabel* dataSubSiteLabel;
@property (retain, nonatomic) IBOutlet UILabel* dataAddressLabel;
@property (retain, nonatomic) IBOutlet UILabel* dataSSIDLabel;
@property (retain, nonatomic) IBOutlet UILabel* dataEncryptionLabel;
@property (retain, nonatomic) IBOutlet UILabel* dataConfidenceLabel;
@property (retain, nonatomic) IBOutlet UILabel* dataDateLabel;


- (IBAction) directionButtonPressed:(id)sender;

- (void)updateDisplay;
- (void)loadAP:(int)ap;


@end
