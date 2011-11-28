//
//  LoadOverlay.m
//  Eduroam App3
//
//  Created by Ashley Browning on 15/04/2011.
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

#import "PermissionOverlay.h"

@interface PermissionOverlay () {
    
    UILabel* text;
    //UIActivityIndicatorView* activity;
    
}
@end



@implementation PermissionOverlay


//---------------------------------------------------
// Initialise the frame with text, colour and whatnot
//---------------------------------------------------
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        
        //Make semi-transparent
        self.opaque = NO;
        self.backgroundColor = [UIColor blackColor];
        self.alpha = 0.85;
        
        //float width = 100;
        float width = frame.size.width;
		float height = 100;
		//float x = (frame.size.width - width) / 2;
        float x = 0;
		float y = (frame.size.height - height - 40) / 2;
		
		text = [[UILabel alloc] initWithFrame:CGRectMake(x, y, width, height)];
		
		text.text = @"Permission Needed To Tag \n\n Please go to settings to give permission";
		text.textColor = [UIColor whiteColor];
		text.textAlignment = UITextAlignmentCenter;
		text.backgroundColor = [UIColor clearColor];
        text.numberOfLines = 0;
		
		[self addSubview:text];
		
		
		//width = 37;
		//height = 37;
		//x = (frame.size.width - width) / 2;
		//y = (frame.size.height - height - 100) / 2;
		
//		activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//		activity.frame = CGRectMake(x, y, width, height);									 
//		
//		[self addSubview:activity];
		[self hide];
        
        
    }
    return self;
}


// Update the text, rearrange view layout based on text
- (void) updateText:(NSString*)pMessage{
    text.text = pMessage;
}

#pragma mark - actions
- (void) show{
    //[activity startAnimating];
	[self setHidden:NO];
}

- (void) hide{
    //[activity stopAnimating];
	[self setHidden:YES];
}

- (void) reOrientate:(CGRect)frame{
    
}




/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)dealloc
{
    [super dealloc];
}

@end

