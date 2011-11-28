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

#import "NetworkJSON.h"
#import "JSON.h"
#import "NetworkManager.h"


@interface NetworkJSON () {
    //INSTANCE VARIABLES
    NSMutableData* receivingData;
    NetworkManager* networkManager;
    
}

@property (retain, nonatomic) NSString* identifier;

- (int)sendRequest:(NSDictionary*)parameters;
- (void)processData;



@end

@implementation NetworkJSON


@synthesize urlstring;
@synthesize parameters;
@synthesize delegate;
@synthesize identifier;
@synthesize returnDict;




//----------------------------------
// Initialise JSON object with a URL
//----------------------------------
- (id)initWithURL:(NSString*)initurl withDelegate:(id <NetworkJSONProtocol>)initdelegate{
    self = [super init];
    if (self){
        urlstring = initurl;
        delegate = initdelegate;
        networkManager = [NetworkManager sharedNetworkManager];
        returnDict = YES;
    }
    return self;
}


//------------------------------------------------------------------
// Return Dictionary from a url supplying JSON with given parameters
//------------------------------------------------------------------
/* Return codes
 0 = All went fine
 1 = There is no Internet connection
 
 */
- (int)getJSON:(NSString*)inIdentifier withParameters:(NSDictionary*)tempParameters{
    //	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    //Create the parameter string
    
    identifier = inIdentifier;    

    
    return [self sendRequest:tempParameters];
}

//--------------------------------------------------------------------
// Return Dictionary from a url supplying JSON with default parameters
//--------------------------------------------------------------------
/* Return codes
 0 = All went fine
 1 = There is no Internet connection
 
 */
- (int)getJSON:(NSString*)inIdenifier{
    NSLog(@"in Get JSON");
    
    identifier = inIdenifier;  
    
    return [self sendRequest:parameters];
    

}

//---------------------------------------
// Send the request to the designated URL
//---------------------------------------
/* Return codes
 0 = All went fine
 1 = There is no Internet connection
 
 */
- (int)sendRequest:(NSDictionary*)lParameters{
    
    //If it is possible to access the internet
    if ([networkManager getCurrentNetworkStatus] == NotReachable){
        NSLog(@"Not reachable!");
        return 1;
    }

    //build up the URL
    NSString* urltemp = [NSString stringWithString:urlstring];
    
    if ([lParameters count] > 0) {
        urltemp = [urltemp stringByAppendingString:@"?"];
        
        //NSString* toAppend;
        NSEnumerator* e = [lParameters keyEnumerator];
        NSString* key = (NSString*) [e nextObject];
        NSString* toAppend = [NSString stringWithString:key];
        toAppend = [toAppend stringByAppendingString:@"="];
        toAppend = [toAppend stringByAppendingString:(NSString*)[lParameters objectForKey:key]];
        //[toAppend stringByAppendingString:@"&"];
        while ((key = (NSString*)[e nextObject])) {
            toAppend = [toAppend stringByAppendingString:@"&"];
            toAppend = [toAppend stringByAppendingString:key];
            toAppend = [toAppend stringByAppendingString:@"="];
            toAppend = [toAppend stringByAppendingString:[lParameters objectForKey:key]];
        }
        
        urltemp = [urltemp stringByAppendingString:toAppend];
    }
    
    
    NSLog(@"url: %@", urltemp);

    
    NSURL* url = [[NSURL alloc] initWithString:urltemp];
    
    NSURLRequest* urlReq = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:25];
    NSURLConnection* connection = [[NSURLConnection alloc] initWithRequest:urlReq delegate:self startImmediately:YES];
    
    if (connection) {
        receivingData = [[NSMutableData data] retain];
    } else {
        NSLog(@"Something went wrong when creating a connection");
    }
    
    [url release];
    [urlReq release];
    [connection release];
    
    
    
    return 0;
}


#pragma - NSURLConnection delegate methods
//--------------------------------------------------
// When data is available, append to the data object
//--------------------------------------------------
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    [receivingData appendData:data];
    //NSLog(@"Didreceivedata");
}


//---------------------------------------------------------
// When there is a response from the server, this is called
//---------------------------------------------------------
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    [receivingData setLength:0];
    NSLog(@"didReceiveResponse");
}


//--------------------------------------------------
// When no connection can be made, this is called
//--------------------------------------------------
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"didFailWithError: %@", error);
    
    //Pass the error on to the delegate
    [delegate receiveConnectionError:identifier];
}

//-----------------------------------------------------
// Called when all the data has finished being sent
//-----------------------------------------------------
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"Finished sending the data!");
    if (returnDict){
        [self processDataToJSON];
    } else {
        [self processData];
    }
}

//----------------------------------------
// Called when data has been sent, turns Data>JSON String>NSDictionary
//----------------------------------------
- (void)processDataToJSON{
    
    NSString* jsonString = [[NSString alloc] initWithData:receivingData encoding:NSUTF8StringEncoding];
    //NSLog(@"JSONString: %@", jsonString);
    NSMutableDictionary* results = [NSDictionary dictionaryWithDictionary:[jsonString JSONValue]];
    if([results count] == 0){
        [delegate receiveJSONError:identifier];
    } else {
        [delegate receiveJSONDictionary:results withID:identifier];
    }
    [jsonString release];
    
}

//-----------------------------------------------
// Process and return the data without JSON magic
//-----------------------------------------------
- (void)processData{
    
    if (receivingData == nil){
        [delegate receiveJSONError:identifier];
    } else {
        [delegate receiveData:receivingData withID:identifier];
    }
    
    
    //- (void)receiveData:(NSMutableData*)data withID:(NSString*)identifier{

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

@end


