//
//  LocationManager.m
//  Eduroam App3
//
//  Created by Ashley Browning on 07/04/2011.
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

#import "LocationManager.h"
#import "SynthesiseSingleton.h"


@implementation LocationManager

SYNTHESIZE_SINGLETON_FOR_CLASS(LocationManager);

//INSTANCE VARIABLES
@synthesize manager;


//---------------------------------
// This returns the shared instance
//---------------------------------
+ (LocationManager *)sharedLocationManager { 
    @synchronized(self) 
    { 
        if (sharedLocationManager == nil) 
        { 
            sharedLocationManager = [[self alloc] init]; 
            [sharedLocationManager initLocationManager];
        } 
    } 
    
    return sharedLocationManager; 
} 


//----------------------------------------
// Creates a manager with default settings
//----------------------------------------
- (void) initLocationManager{
    
    manager = [[CLLocationManager alloc] init];
    [manager setDesiredAccuracy:kCLLocationAccuracyBest];
    CLLocationDirection delta = 1;
    [manager setDistanceFilter:delta];
}


//----------------------------
// Return the location manager
//----------------------------
- (CLLocationManager*)getLocationManager{
    return manager;
}


//-------------------------------------------------
// This will set the delegate for the shared object
//-------------------------------------------------
- (void)setDelegate:(id<CLLocationManagerDelegate>)indelegate{
    manager.delegate = indelegate;    
}




@end
