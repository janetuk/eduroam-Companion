/* InitViewContorller.m
 * Created by: Ashley Browning
 * Created on: 19/03/2011
 * Version: v1.00 (19/03/2011)
 *
 * Amended from CocoaWithLove's SynthesizeSingleton.h, defines a generic singleton class. In order to add
 * specific initialisation methods, the sharedXXX method needs to be implemented in the Singleton's 
 * implementation fileadiu
 *
 */

//
//  SynthesizeSingleton.h
//  CocoaWithLove
//
//  Created by Matt Gallagher on 20/10/08.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//


////////////////////////////////////////////////////////
// MUST HAVE THE BELOW IMPLEMENTED IN SINGLETON CLASS!!!
////////////////////////////////////////////////////////

//+ (DatabaseManager *)sharedDatabaseManager
//{ 
//    @synchronized(self) 
//    { 
//        if (sharedDatabaseManager == nil) 
//        { 
//            sharedDatabaseManager = [[self alloc] init]; 
//        } 
//    } 
//    
//    return sharedDatabaseManager; 
//} 




#define SYNTHESIZE_SINGLETON_FOR_CLASS(classname) \
\
static classname *shared##classname = nil; \
\
+ (id)allocWithZone:(NSZone *)zone \
{ \
@synchronized(self) \
{ \
if (shared##classname == nil) \
{ \
shared##classname = [super allocWithZone:zone]; \
return shared##classname; \
} \
} \
\
return nil; \
} \
\
- (id)copyWithZone:(NSZone *)zone \
{ \
return self; \
} \
\
- (id)retain \
{ \
return self; \
} \
\
- (NSUInteger)retainCount \
{ \
return NSUIntegerMax; \
} \
\
- (void)release \
{ \
} \
\
- (id)autorelease \
{ \
return self; \
}

