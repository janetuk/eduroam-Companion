//
//  NetworkJSON.m
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

#import "NetworkManager.h"
#import "SynthesiseSingleton.h"
#import "NetworkJSONProtocol.h"

#define kHostName @"https://eduroam-app-api.dev.ja.net"

@implementation NetworkManager

SYNTHESIZE_SINGLETON_FOR_CLASS(NetworkManager);

@synthesize internetConnectionStatus;
@synthesize reachability;


//INSTANCE VARIABLES
NSMutableData* receivingData;


+ (NetworkManager *)sharedNetworkManager
{ 
    @synchronized(self) 
    { 
        if (sharedNetworkManager == nil) 
        { 
            sharedNetworkManager = [[self alloc] init]; 
            [sharedNetworkManager initManager];
        } 
    } 
    
    return sharedNetworkManager; 
} 


//--------------------------------------------
// Initialise the manager object
//--------------------------------------------
- (id)initManager{
    
    self = [super init];
    
    if(self){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachibilityChanged:) name: kReachabilityChangedNotification object:nil];
        reachability = [[Reachability reachabilityForInternetConnection] retain];
        [reachability startNotifier];
        NSLog(@"Started the notifier");
    }
    
    return self;
}


//---------------------------------------------------
// Called when network status has changed
//---------------------------------------------------
- (void)reachibilityChanged:(NSNotification*)notice{
    NSLog(@"Reachability has changed!");
    if ([reachability currentReachabilityStatus] == NotReachable){
        //There is no connection to the internet
        //NSLog(@"No connection to the internet!");
    } else {
        //NSLog(@"There is a connection to the internet!");
    }
    
}

//------------------------------------
// Return the current network status
//------------------------------------
- (NetworkStatus)getCurrentNetworkStatus{
    return [reachability currentReachabilityStatus];    
}


+ (NetworkJSON*)getJSONObject:(NSString*)url withDelegate:(id <NetworkJSONProtocol>)delegate{
    NetworkJSON* json = [[[NetworkJSON alloc] initWithURL:url withDelegate:delegate] autorelease];
    return json;
}

//NSURLCONNECTION
//REACHABILITY class

/*
 
 Things that could happen
 - phone not connected to the internet
 - unable to reach server
 - server is non-responsive
 - server returns an unplanned error code
 - server returns a planned error code
 - server returns expected information
 
 */

-(void)dealloc{
    [reachability release];
    [super dealloc];
}

@end
