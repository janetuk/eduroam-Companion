//
//  TagPickSiteViewController.m
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

#import "TagPickSiteViewController.h"


@implementation TagPickSiteViewController


@synthesize tableView;
@synthesize siteArray;
@synthesize parent;
@synthesize eduroamDarkBlue;
@synthesize eduroamLightBlue;
//-------------------------------------------------
// Initalise the view
//-------------------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

//-------------------------------------
// Init with reference to parent
//-------------------------------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil andParentController:(TagCheckSiteViewController*)inparent{
    
    self = [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self){
       parent = inparent;
    }
    return self;
}

//-------------------------------------------------
// Additional setting up of the view/controller is done here
//-------------------------------------------------
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.eduroamDarkBlue = [UIColor colorWithRed:51.0/255.0 green:105.0/255.0 blue:135.0/255.0 alpha:1.0];
    self.eduroamLightBlue = [UIColor colorWithRed:191.0/255.0 green:213.0/255.0 blue:220.0/255.0 alpha:1.0];
    [self setTitle:@"Select Site"];
    tableView.separatorColor = self.eduroamDarkBlue;


}

//--------------------------------------------------
// Pass in a new source data array and refresh table
//--------------------------------------------------
- (void)refreshTableWithArray:(NSArray*)array{
    self.siteArray = array;
    [tableView reloadData];
}

#pragma mark - Table Delegate methods

//--------------------------------------------------
// For an index, return a table cell
//--------------------------------------------------
- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString* cellIdentifier = @"Cell";
	
	//attempt to get at a reusable cell
	UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	//If we cannot get a reusable cell, then create a new cell
	if(cell == nil){
		//cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier] autorelease];
	}
    
    CGSize maxSize = CGSizeMake(70.0, cell.frame.size.height-1);

    cell.textLabel.text = [[siteArray objectAtIndex:[indexPath row]] objectForKey:[NSNumber numberWithInt:0]];
    cell.detailTextLabel.text = [[siteArray objectAtIndex:[indexPath row]] objectForKey:[NSNumber numberWithInt:1]];
    UILabel* temp = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 70, cell.frame.size.height-1)];
    temp.text = [NSString stringWithFormat:@"%.1f Km", [[[siteArray objectAtIndex:[indexPath row]] objectForKey:@"distance"] doubleValue]];
    temp.font = [UIFont fontWithName:@"Helvetica" size:14];
    
    //Get the size just right to allow for maximum room for the text
    CGSize labelSize = [temp.text sizeWithFont:temp.font constrainedToSize:maxSize lineBreakMode:UILineBreakModeTailTruncation];
    temp.frame = CGRectMake(0, 0, labelSize.width, labelSize.height);
    temp.textColor = eduroamDarkBlue;
    temp.textAlignment = UITextAlignmentRight;
    //temp.backgroundColor = [UIColor blueColor];
    cell.accessoryView = temp;
    
    return cell;
    
}

//--------------------------------------------
// Returns the header for the section
//--------------------------------------------
- (UIView*) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UILabel *headerView = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 30)] autorelease];
    
    
    [headerView setBackgroundColor: [UIColor colorWithRed:51.0/255.0 green:105.0/255.0 blue:135.0/255.0 alpha:0.9]];
    headerView.text = @"  Nearby Sites (Closest First)";

    headerView.textColor = [UIColor whiteColor];
    headerView.font = [UIFont fontWithName:@"Helvetica-Bold" size:16 ];
    
    //headerView.text = @"Sites";
    
    return headerView;
}

//----------------------------------------
// Return the number of cells in the table
//----------------------------------------
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [siteArray count];
}


//-------------------------------------------------------------------
// Handle a user selection, tell the parent the selection and go back
//-------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    //get the site and send it to the parent
    [parent userSelection:[siteArray objectAtIndex:indexPath.row]];
    [self.navigationController popViewControllerAnimated:YES];
}

//--------------------------------------------------------
// Title for the table view
//--------------------------------------------------------
- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    return @"Nearby Sites (Closest First)";
}

#pragma mark - View lifecycle

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
