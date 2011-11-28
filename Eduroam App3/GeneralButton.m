//
//  GeneralButton.m
//  Eduroam App3
//
//  Created by Ashley Browning on 12/04/2011.
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

#import "GeneralButton.h"
#import <QuartzCore/QuartzCore.h>


@implementation GeneralButton

@synthesize bgButton;

- (void) myInit {
    

        self.bgButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        bgButton.frame = self.frame;
        bgButton.autoresizingMask = self.autoresizingMask;
        bgButton.layer.cornerRadius = 11.0f;
        
}


- (void) drawHighlighted{
    
    
    
    
//    [checkSiteButton.layer setCornerRadius:11.0f];
//    [checkSiteButton.layer setBorderColor:[[UIColor colorWithRed:(179/255.0) green:0.0 blue:(1.0/255.0) alpha:1.0] CGColor]];
//    [checkSiteButton.layer setBorderWidth:2.0f];
//    [checkSiteButton.layer setBackgroundColor:[[UIColor colorWithRed:1 green:1 blue:1 alpha:1.0] CGColor]];
//    [checkSiteButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
}

- (void) drawNormal{
    

}

- (void)setHighlighted:(BOOL)highlighted{
    [super setHighlighted:highlighted];
    [bgButton setHighlighted:highlighted];
    if (highlighted){
        [self drawHighlighted];
    } else {
        [self drawNormal];
    }
}

- (void)didMoveToSuperview {
	[super didMoveToSuperview];
	[self.superview insertSubview:bgButton belowSubview:self];
}

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self myInit];
    }

    return self;
}

- (id)initWithCoder:(NSCoder*)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        NSLog(@"%s: buttonType=%d", __func__, self.buttonType);
        [self myInit];
    }
    return self;
}

- (void)dealloc {
	[bgButton release];
	[super dealloc];
}

@end
