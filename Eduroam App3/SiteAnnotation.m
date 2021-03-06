//
//  SiteAnnotation.m
//  Eduroam App3
//
//  Created by Ashley Browning on 19/03/2011.
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

#import "SiteAnnotation.h"


@implementation SiteAnnotation

@synthesize siteName;
@synthesize subName;

#pragma mark - Initialisation

//---------------------------------------------------
//Initialises the Annotation object with a coordinate
//---------------------------------------------------
//- (id)initWithCoordinate:(CLLocationCoordinate2D) c {
//    
//    self = [super init];
//    if(self){
//        coordinate = c;
//        return self;
//    }
//    
//    return self;
//}


//----------------------------------------------------------------------
//Initialises the Annotation object with a coordinate and title/subtitle
//----------------------------------------------------------------------
- (id)initWithCoordinate:(CLLocationCoordinate2D)c withTitle:(NSString*)title andSubTitle:(NSString*)subtitle andID:(int)inid andSiteID:(int)site{
    
    
    self = [super initWithCoordinate:c withType:1 andid:inid andSiteID:site];
    if (self){
        self.siteName = title;
        self.subName = subtitle;
    }
    return self;
}

#pragma mark - MKAnnotation Protocol Things
- (NSString*) subtitle{
    return subName;
}

- (NSString*) title{
    return siteName;
}


@end
