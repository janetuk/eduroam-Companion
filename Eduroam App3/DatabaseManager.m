//
//  Database.m
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

#import "DatabaseManager.h"
#import "SynthesiseSingleton.h"

@implementation DatabaseManager

@synthesize DBPath;

SYNTHESIZE_SINGLETON_FOR_CLASS(DatabaseManager);
sqlite3* db;


#pragma mark - Initialse

//----------------------------------------------------------------------------
// Initialises Singleton if not already exists, additional initialisation here
//----------------------------------------------------------------------------
+ (DatabaseManager *)sharedDatabaseManager
{ 
    @synchronized(self) 
    { 
        if (sharedDatabaseManager == nil) 
        { 
            sharedDatabaseManager = [[self alloc] init]; 
            
            ////////////////////////////////
            //ADDITIONAL INITIALISATION HERE
            ////////////////////////////////
            [sharedDatabaseManager initDBPath];
            [sharedDatabaseManager copyDatabaseIfNeeded];
            [sharedDatabaseManager openDatabase];
        } 
    } 
    return sharedDatabaseManager; 
} 



//--------------------------------------------------------------------
// Return the path to where database should be in the Documents Folder
//--------------------------------------------------------------------
- (void) initDBPath{

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);      //Search for specific directory in specific domain
    NSString *documentsDir = [paths objectAtIndex:0];   //Result is going to be in the first part of the array
    DBPath = [documentsDir stringByAppendingPathComponent:@"eduroam.sqlite"];
    [DBPath retain];
    
}

//-----------------------------------------------------------------------
// Check if database exists in Documents folder. If not, copy from Bundle
//-----------------------------------------------------------------------
- (void)copyDatabaseIfNeeded{
    
    //NEED TO CHECK DATABASE VERSIONS IF A DB ALREADY EXISTS IN THE DOCUMENTS FOLDER
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* dbPath = self.DBPath;
    NSString* bundleDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"eduroam.sqlite"];

    
    if( ![fileManager fileExistsAtPath:dbPath]){
        NSError* error;
        //Move the database file from the bundle to the Documents directory
        if(![fileManager copyItemAtPath:bundleDBPath toPath:dbPath error:&error]){
            //Failure
            NSLog(@"Error 1: Database Copy Failure - %@", [error localizedDescription]);
        }
    } else {
        //If the file exists, then check the database versions
        
        //open the database in the bundle
        sqlite3* bundleDB;
        if(sqlite3_open([bundleDBPath UTF8String], &bundleDB) != SQLITE_OK){
            sqlite3_close(bundleDB);
            NSAssert(0, @"Error 3: The database failed to open");
        }
        
        sqlite3* docDB;
        if(sqlite3_open([dbPath UTF8String], &docDB) != SQLITE_OK){
            sqlite3_close(docDB);
            NSAssert(0, @"Error 4: The database failed to open");
        }
        
        //Find the version of the bundleDB
        NSString* query = @"SELECT baseversion FROM Info";
        sqlite3_stmt* stmt;
        int outcome = sqlite3_prepare(bundleDB, [query UTF8String], -1, &stmt, nil);
        
        if (outcome != SQLITE_OK) {
            //Error and abort
            NSLog(@"Error 5: Problem prepareing statement");
            sqlite3_close(bundleDB);
            sqlite3_close(docDB);
            return;
        }
        
        int bundleVersion = -1;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            bundleVersion = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);        
        
        //Find the version of the bundleDB
        outcome = sqlite3_prepare(docDB, [query UTF8String], -1, &stmt, nil);
        
        if (outcome != SQLITE_OK) {
            //Error and abort
            NSLog(@"Error 6: Problem prepareing statement");
            sqlite3_close(bundleDB);
            sqlite3_close(docDB);
            return;
        }
        
        int docVersion = -1;
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            docVersion = sqlite3_column_int(stmt, 0);
        }
        sqlite3_finalize(stmt);
        
        sqlite3_close(bundleDB);
        sqlite3_close(docDB);
        
        
        //Compare the versions
        if (docVersion < bundleVersion) {
            NSLog(@"Bundle and Doc databases are different versions, copying across");
            NSError* error;
            //remove the current one in the doc
            if (![fileManager removeItemAtPath:dbPath error:&error]){
                NSLog(@"Error 8: Failed to remove database from documents");
            }
            
            //Move the database file from the bundle to the Documents directory
            if(![fileManager copyItemAtPath:bundleDBPath toPath:dbPath error:&error]){
                //Failure
                NSLog(@"Error 7: Database Copy Failure - %@", [error localizedDescription]);
            }
        }
    }
}

//-----------------------------------------------------------------------
// Open the database
//-----------------------------------------------------------------------
- (void)openDatabase{
    if(sqlite3_open([DBPath UTF8String], &db) != SQLITE_OK){
        sqlite3_close(db);
        NSAssert(0, @"Error 2: The database failed to open");
    }
}


-(void)closeDatabase{
    sqlite3_close(db);
}

//Get some data and pop it in the document folder
- (int) overwriteDatabase:(NSData*)data{
    
    //close database
    [self closeDatabase];
    
    //rename old database
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES);      //Search for specific directory in specific domain
    NSString *documentsDir = [paths objectAtIndex:0];   //Result is going to be in the first part of the array
//    DBPath = [documentsDir stringByAppendingPathComponent:@"eduroam.sqlite"];
    NSString* tempPath = [documentsDir stringByAppendingPathComponent:@"eduroamtemp.sqlite"];
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    //If the file does not exist
    if (![fileManager fileExistsAtPath:DBPath]){
        NSLog(@"Database does not exist at path");
        return 1;
    }
    
    NSError* error;
    if (![fileManager moveItemAtPath:DBPath toPath:tempPath error:&error]){
        NSLog(@"Error moving file");
        return 2;
    }

    //save new database
    if (![data writeToFile:DBPath atomically:YES]){
        NSLog(@"Update failed, restoring previous db");
        if (![fileManager moveItemAtPath:tempPath toPath:DBPath error:&error]){
            NSLog(@"Error moving file again");
            return 4;
        }
        return 3;
    }
    
    //if everything went well, delete the old database
    if (![fileManager removeItemAtPath:tempPath error:&error]) {
        NSLog(@"Could not delete old database");
        return 5;
    }
    
    [self openDatabase];
    
    return 0;
}

//---------------------------
// Return the database object
//---------------------------
- (sqlite3*) getDB{
    return db;
}


#pragma mark Database Operations - 
//----------------------------------------------------------------------
// Insert/update into database - string and parameters to bind passed in
//----------------------------------------------------------------------
/* Return Codes
    0 = All went well!
    1 = Problem occured when preparing the statement
    2 = Problem with binding variable 10 or 20...
    3 = Problem with binding variable 1 or 11 or 21..
    ...
    11 = Problem with binding variable 9 or 19 or 29
    20 = Problem executing the query
    21 = Unequal number of paramters and types
 */
- (int) insertQuery:(NSString*) query withParameters:(NSArray*)parameters ofTypes:(NSString*)types{
    
    //Check number of parameters against the number of types that have been submitted
    if([parameters count] != [types length]){
        return 21;
    }
    
    //Prepare and bind
    sqlite3_stmt *stmt;
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);

    if( outcome == SQLITE_OK){
        //for all the parameters that have been passed through
        for(int i=0; i<[parameters count]; i++){
            //Switch statement for the types - s=text, d=double, i=integer
            switch ([types characterAtIndex:i]) {
                case 's':
                    outcome = sqlite3_bind_text(stmt, i+1, [[parameters objectAtIndex:i] UTF8String], -1, NULL);
                    break;
                case 'd':
                    outcome = sqlite3_bind_double(stmt, i+1, [[parameters objectAtIndex:i] doubleValue]);
                    break;
                case 'i':
                    outcome = sqlite3_bind_int(stmt, i+1, [[parameters objectAtIndex:i] intValue]);
                    break;
                default:
                    outcome = sqlite3_bind_text(stmt, i+1, [[parameters objectAtIndex:i] UTF8String], -1, NULL);
                    break;
            }
            if(outcome != SQLITE_OK){
                return 2+(i%10);
            }
        }
    } else {
        //unable to prepare the statement
        NSLog(@"Update outcome in db: %d", outcome);
        return 1;
    }
    
    //execute
    outcome = sqlite3_step(stmt);
    if( outcome != SQLITE_DONE){
        //Fail in completing operation
        return 20;
    }
    sqlite3_finalize(stmt);
    return 0;
}

//--------------------------------------------
// Insert/update into database - no parameters
//--------------------------------------------
/* Return Codes
 0 = All went well!
 1 = Problem occured when preparing the statement
 20 = Problem executing the query
 */
- (int) insertQuery:(NSString*) query{
    
   
    //Prepare and bind
    sqlite3_stmt *stmt;
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);
    
    if( outcome != SQLITE_OK){
        //unable to prepare the statement
        return 1;
    }
    
    //execute
    outcome = sqlite3_step(stmt);
    if( outcome != SQLITE_DONE){
        //Fail in completing operation
        return 20;
    }
    sqlite3_finalize(stmt);
    return 0;
}


//-------------------------------------------------------------------
// Select from the database - string and parameters to bind passed in
//-------------------------------------------------------------------
/* Rows returned in dictionary with a numeric key (ie, 0,1,2,3,4....)
   Size is returned in dictionary with key "size"
   Error code is returned in dictionary with key 'error'
 0 = All went well!
 1 = Problem occured when preparing the statement
 2 = Problem with binding variable 10 or 20...
 3 = Problem with binding variable 1 or 11 or 21..
 ...
 11 = Problem with binding variable 9 or 19 or 29
 20 = Problem executing the query
 21 = Unequal number of paramters and types
 */
- (NSMutableDictionary*) selectQuery:(NSString*)query withParameters:(NSArray*)parameters ofTypes:(NSString*)types andColumnTypes:(NSString*)cTypes{
    
    NSMutableDictionary* output = [[[NSMutableDictionary alloc] init] autorelease];
    
    //Check number of parameters against the number of types that have been submitted
    if([parameters count] != [types length]){
        [output setObject:[NSNumber numberWithInt:21] forKey:@"error"];
        return [NSDictionary dictionaryWithDictionary:output];
    }
    
    ///////////////////
    // PREPARE AND BIND
    ///////////////////
    sqlite3_stmt *stmt;
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);
    
    if( outcome == SQLITE_OK){
        //for all the parameters that have been passed through
        for(int i=0; i<[parameters count]; i++){
            //Switch statement for the types - s=text, d=double, i=integer
            switch ([types characterAtIndex:i]) {
                case 's':
                    NSLog(@"binding String %@", [parameters objectAtIndex:i]);
                    outcome = sqlite3_bind_text(stmt, i+1, [[parameters objectAtIndex:i] UTF8String], -1, NULL);
                    NSLog(@"Outcome is: %d", outcome);
                    break;
                case 'd':
                    outcome = sqlite3_bind_double(stmt, i+1, [[parameters objectAtIndex:i] doubleValue]);
                    break;
                case 'i':
                    outcome = sqlite3_bind_int(stmt, i+1, [[parameters objectAtIndex:i] intValue]);
                    break;
                default:
                    outcome = sqlite3_bind_text(stmt, i+1, [[parameters objectAtIndex:i] UTF8String], -1, NULL);
                    break;
            }
            if(outcome != SQLITE_OK){
                [output setObject:[NSNumber numberWithInt:2+(i%10)] forKey:@"error"];
                //return [NSDictionary dictionaryWithDictionary:output];
                return output;
            }
        }
    } else {
        //unable to prepare the statement
        [output setObject:[NSNumber numberWithInt:1] forKey:@"error"];
        //return [NSDictionary dictionaryWithDictionary:output];
        return output;
    }
    
    /////////
    //EXECUTE
    /////////
    
    int j = 0;
    while (sqlite3_step(stmt) == SQLITE_ROW) {

        NSMutableDictionary* row = [NSMutableDictionary dictionary];
        for(int i=0; i<[cTypes length]; i++){
            //Switch statement for the types - s=text, d=double, i=integer
            switch ([cTypes characterAtIndex:i]) {
                case 's':{
                    char* field = (char*) sqlite3_column_text(stmt, i);
                    NSString* field1str = [NSString stringWithUTF8String:field];
                    [row setObject:field1str forKey:[NSNumber numberWithInt:i]];
                break;
                }
                case 'd':{
                    double field = sqlite3_column_double(stmt, i);
                    NSNumber* no = [NSNumber numberWithDouble:field];
                    [row setObject:no forKey:[NSNumber numberWithInt:i]];                    
                break;
                }
                case 'i':{
                    int field = sqlite3_column_int(stmt, i);
                    NSNumber* no = [NSNumber numberWithInt:field];
                    [row setObject:no forKey:[NSNumber numberWithInt:i]];   
                break;
                }
                default:{
                    char* field = (char*) sqlite3_column_text(stmt, i);
                    NSString* field1str = [NSString stringWithUTF8String:field];
                    [row setObject:field1str forKey:[NSNumber numberWithInt:i]];
                break;
                }
            }
        }
        
        [output setObject:row forKey:[NSNumber numberWithInt:j]];
        j++;
    }
    
    [output setObject:[NSNumber numberWithInt:j] forKey:@"size"];
    [output setObject:[NSNumber numberWithInt:0] forKey:@"error"];
   

    sqlite3_finalize(stmt);
    //return [NSDictionary dictionaryWithDictionary:output];
    return output;
}


//-----------------------------------------------------------------------
// Select from the database without parameters. Column types are required
//-----------------------------------------------------------------------
/* ///error/// Codes are stored as an NSNumber in the first element of the array
 0 = All went well!
 1 = Problem occured when preparing the statement
 20 = Problem executing the query
 21 = Unequal number of paramters and types
 
 ///size/// gives the number of rows that have been returned
 ///x/// the key 'number' signifies the number of row returned.
 */
- (NSDictionary*) selectQuery:(NSString*)query andColumnTypes:(NSString*)cTypes{
    
    NSMutableDictionary* output = [[[NSMutableDictionary alloc] init] autorelease];
    
    ///////////////////
    // PREPARE AND BIND
    ///////////////////
    sqlite3_stmt *stmt;
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);

    if( outcome != SQLITE_OK){
        [output setObject:[NSNumber numberWithInt:1] forKey:@"error"];
        return [NSDictionary dictionaryWithDictionary:output];
    }
    
    /////////
    //EXECUTE
    /////////
    
    int j = 0;
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        
        NSMutableDictionary* row = [NSMutableDictionary dictionary];
        for(int i=0; i<[cTypes length]; i++){
            //Switch statement for the types - s=text, d=double, i=integer
            switch ([cTypes characterAtIndex:i]) {
                case 's':{
                    char* field = (char*) sqlite3_column_text(stmt, i);
                    NSString* field1str = [NSString stringWithUTF8String:field];
                    [row setObject:field1str forKey:[NSNumber numberWithInt:i]];
                    break;
                }
                case 'd':{
                    double field = sqlite3_column_double(stmt, i);
                    NSNumber* no = [NSNumber numberWithDouble:field];
                    [row setObject:no forKey:[NSNumber numberWithInt:i]];                    
                    break;
                }
                case 'i':{
                    int field = sqlite3_column_int(stmt, i);
                    NSNumber* no = [NSNumber numberWithInt:field];
                    [row setObject:no forKey:[NSNumber numberWithInt:i]];   
                    break;
                }
                default:{
                    char* field = (char*) sqlite3_column_text(stmt, i);
                    NSString* field1str = [NSString stringWithUTF8String:field];
                    [row setObject:field1str forKey:[NSNumber numberWithInt:i]];
                    break;
                }
            }
        }
        
        [output setObject:row forKey:[NSNumber numberWithInt:j]];
        j++;
    }
    
    [output setObject:[NSNumber numberWithInt:j] forKey:@"size"];
    [output setObject:[NSNumber numberWithInt:0] forKey:@"error"];
    
    
    sqlite3_finalize(stmt);
    return [NSDictionary dictionaryWithDictionary:output];

}

//----------------------------------------------------------------------
// Delete query - with parameters and types
//----------------------------------------------------------------------
/* Return Codes
 0 = All went well!
 1 = Problem occured when preparing the statement
 2 = Problem with binding variable 10 or 20...
 3 = Problem with binding variable 1 or 11 or 21..
 ...
 11 = Problem with binding variable 9 or 19 or 29
 20 = Problem executing the query
 21 = Unequal number of paramters and types
 */
- (int) deleteQuery:(NSString*)query withParameters:(NSArray*)parameters ofTypes:(NSString*)types{
    
    //Check number of parameters against the number of types that have been submitted
    if([parameters count] != [types length]){
        return 21;
    }
    
    //Prepare and bind
    sqlite3_stmt *stmt;
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);
    
    if( outcome == SQLITE_OK){
        //for all the parameters that have been passed through
        for(int i=0; i<[parameters count]; i++){
            //Switch statement for the types - s=text, d=double, i=integer
            switch ([types characterAtIndex:i]) {
                case 's':
                    outcome = sqlite3_bind_text(stmt, i+1, [[parameters objectAtIndex:i] UTF8String], -1, NULL);
                    break;
                case 'd':
                    outcome = sqlite3_bind_double(stmt, i+1, [[parameters objectAtIndex:i] doubleValue]);
                    break;
                case 'i':
                    outcome = sqlite3_bind_int(stmt, i+1, [[parameters objectAtIndex:i] intValue]);
                    break;
                default:
                    outcome = sqlite3_bind_text(stmt, i+1, [[parameters objectAtIndex:i] UTF8String], -1, NULL);
                    break;
            }
            if(outcome != SQLITE_OK){
                return 2+(i%10);
            }
        }
    } else {
        //unable to prepare the statement
        return 1;
    }
    
    //execute
    outcome = sqlite3_step(stmt);
    if( outcome != SQLITE_DONE){
        //Fail in completing operation
        return 20;
    }
    sqlite3_finalize(stmt);
    return 0;

}

//----------------------------------------------------------------------
// Delete query - without parameters
//----------------------------------------------------------------------
/* Return Codes
 0 = All went well!
 1 = Problem occured when preparing the statement
 20 = Problem executing the query
 */
- (int) deleteQuery:(NSString*)query {
    
    //Check number of parameters against the number of types that have been submitted
    
    //Prepare and bind
    sqlite3_stmt *stmt;
    int outcome = sqlite3_prepare_v2(db, [query UTF8String], -1, &stmt, nil);
    
    if( outcome != SQLITE_OK){
        //unable to prepare the statement
        return 1;
    }
    
    //execute
    outcome = sqlite3_step(stmt);
    if( outcome != SQLITE_DONE){
        //Fail in completing operation
        return 20;
    }
    sqlite3_finalize(stmt);
    return 0;
    
}


@end

/*	sqlite3's error codes:
 
 #define SQLITE_OK           0   // Successful result
 #define SQLITE_ERROR        1   // SQL error or missing database
 #define SQLITE_INTERNAL     2   // Internal logic error in SQLite
 #define SQLITE_PERM         3   // Access permission denied
 #define SQLITE_ABORT        4   // Callback routine requested an abort
 #define SQLITE_BUSY         5   // The database file is locked
 #define SQLITE_LOCKED       6   // A table in the database is locked
 #define SQLITE_NOMEM        7   // A malloc() failed
 #define SQLITE_READONLY     8   // Attempt to write a readonly database
 #define SQLITE_INTERRUPT    9   // Operation terminated by sqlite3_interrupt()
 #define SQLITE_IOERR       10   // Some kind of disk I/O error occurred
 #define SQLITE_CORRUPT     11   // The database disk image is malformed
 #define SQLITE_NOTFOUND    12   // NOT USED. Table or record not found
 #define SQLITE_FULL        13   // Insertion failed because database is full
 #define SQLITE_CANTOPEN    14   // Unable to open the database file
 #define SQLITE_PROTOCOL    15   // Database lock protocol error
 #define SQLITE_EMPTY       16   // Database is empty
 #define SQLITE_SCHEMA      17   // The database schema changed
 #define SQLITE_TOOBIG      18   // String or BLOB exceeds size limit
 #define SQLITE_CONSTRAINT  19   // Abort due to constraint violation
 #define SQLITE_MISMATCH    20   // Data type mismatch
 #define SQLITE_MISUSE      21   // Library used incorrectly
 #define SQLITE_NOLFS       22   // Uses OS features not supported on host
 #define SQLITE_AUTH        23   // Authorization denied
 #define SQLITE_FORMAT      24   // Auxiliary database format error
 #define SQLITE_RANGE       25   // 2nd parameter to sqlite3_bind out of range
 #define SQLITE_NOTADB      26   // File opened that is not a database file
 #define SQLITE_ROW         100  // sqlite3_step() has another row ready
 #define SQLITE_DONE        101  // sqlite3_step() has finished executing
 */

