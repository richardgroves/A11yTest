//
//  ViewController.m
//  A11yTest
//
//  Created by Richard Groves on 09/07/2013.
//  Copyright (c) 2013 NoodlFroot Ltd. All rights reserved.
//

#import "ViewController.h"
#import "A11yContainerView.h"
#import "A11yContainerScrollView.h"


const float kDelayInScrollProcessing = 0.1f;

const int kTagDetailSlotBase = 10;

@interface ViewController ()
@property (nonatomic, retain) A11yContainerScrollView* dayView;
@property (nonatomic, retain) UILabel* summaryLabel; 					 // Stand in for the summary panel
@property (nonatomic, retain) A11yContainerView* detailedSlotsContainer; // Will hold all the hourly slot columns
@property (nonatomic, assign) BOOL detailSlotsHidden;
@end

@implementation ViewController

- (void)loadView
{
	self.view = [[A11yContainerView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
//	self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	{
		// Demonstration of the UILabel bug with isAccessibilityElement that occurs when linked against MessageUI.framework and have A11y inspector on in simulator, or VO available on device
		UILabel* dn = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 100, 40)];
		
		dn.text = @"A message";
		
		//dn.isAccessibilityElement = YES; // Even without this line the first log will report YES
		dn.accessibilityIdentifier = @"some text";
		
		NSLog(@"Test-a11y A: %@", dn.isAccessibilityElement ? @"YES" : @"NO");
		dn.isAccessibilityElement = NO; // But it wont be honoured when the bug is active (MessageUI framework, iOS6 simulator + a11y inspector etc)
		NSLog(@"Test-a11y B: %@", dn.isAccessibilityElement ? @"YES" : @"NO");
		dn.accessibilityIdentifier = nil;
		NSLog(@"Test-a11y C: %@", dn.isAccessibilityElement ? @"YES" : @"NO");
		dn.isAccessibilityElement = NO;
		NSLog(@"Test-a11y D: %@", dn.isAccessibilityElement ? @"YES" : @"NO");
		
		dn.accessibilityElementsHidden = YES; // Fixes the -(void)setIsAccessibilityElement: not working by hiding the element
		//[self.view addSubview:dn]; // Don't actually want to use this label
	}
	
	// Test of how many a11y elements we can have using the UIAccessibilityContainer informal protocol
	// Trying to work out why the weather app list stops progressing properly when >12 hourly slots (about 25 views)
	
	// Replicate day view hierarchy
	// Main view -> label + (day view -> summary page + detailViewContainer -> N * hourly slots) + tab view
	// Following conversations with Chris on Apple dev list view hierarchy is:
	// Main view (a11y container) -> label + (day view (a11y scroll container) -> summary page + N * Hourly slots on other pages) + tab view label
	
	// Basic location label - first in a11y ordering
	UILabel* locationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 150, 30)];
	locationLabel.text = @"Location name";
	locationLabel.tag = 1; // A11y ordering
	[self.view addSubview:locationLabel];
	
	// Build our fundamental scroll view that holds the summary view and the detail slot views
	CGRect dayViewFrame = self.view.bounds;
	dayViewFrame.size.height *= 0.70f;
	dayViewFrame.origin.y = 80.0f;
	self.dayView = [[A11yContainerScrollView alloc] initWithFrame:dayViewFrame];
	self.dayView.delegate = self;
	self.dayView.pagingEnabled = YES;
	self.dayView.backgroundColor = [UIColor lightGrayColor];

	self.dayView.tag = 2; // Order the central page goes into the view system at
	
	// Has to be an A11yContainerView to hold subviews that are accessible otherwise get those nasty debug messages in the console
	A11yContainerView* summaryPage = [[A11yContainerView alloc] initWithFrame:self.dayView.bounds];
	summaryPage.tag = 2;
	
	self.summaryLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 50, 150, 30)];
	self.summaryLabel.text = @"Summary area";
	self.summaryLabel.tag = 2;
	self.summaryLabel.accessibilityTraits |= UIAccessibilityTraitButton;
	self.summaryLabel.accessibilityHint = NSLocalizedString(@"Opens hourly forecasts", @"A11y hint for tapping the summary area");
	[summaryPage addSubview:self.summaryLabel];
	[self.dayView addSubview:summaryPage];
	
	// Tap this to go to the details
	UITapGestureRecognizer* tapRecog = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(summaryTapped:)];
	[self.summaryLabel addGestureRecognizer:tapRecog];
	self.summaryLabel.userInteractionEnabled = YES;

	// Hourly slots equivalents - several pages of columns

#define USE_LOTS_OF_COLUMNS 1
	
	// Total a11y elements in the scene is 3 + num columns
#ifdef USE_LOTS_OF_COLUMNS
	const int numCols = 24; // Now (26Jul) works for 24 columns!!! // At 24 we can't even get to the end of the first page!
#else
	const int numCols = 10; // At 10 it works fine - cycles through multiple pages, ends up on Day tabs label
#endif

	// Pages here are not as good as in the app as it just stretches the columns out to fill all the pages - doesn't alter the problem though
	const int colsPerPage = 5;	
	int numPages = numCols/5;
	if (numPages*colsPerPage < numCols)
		numPages++;
	
	CGRect detailSlotsFrame = CGRectMake(self.dayView.bounds.size.width, 50, self.dayView.frame.size.width*numPages, self.dayView.frame.size.height*0.5f);
	
	// Using a container to hold the hourly slots makes turning them on/off easier
	self.detailedSlotsContainer = [[A11yContainerView alloc] initWithFrame:detailSlotsFrame];
	self.detailedSlotsContainer.tag = 37;
		
	[self buildItemsOntoView:self.detailedSlotsContainer //self.dayView
						area:self.detailedSlotsContainer.bounds //detailSlotsFrame
						cols:numCols
					startTag:kTagDetailSlotBase];
	
	[self setColumnViewsHiddenState:YES];  // These are initially hidden until the user taps to them from the summary button
	
	[self.dayView addSubview:self.detailedSlotsContainer];
	
	self.dayView.contentSize = CGSizeMake(summaryPage.frame.size.width + detailSlotsFrame.size.width, self.dayView.frame.size.height);
	
	// Reprocess the hierarchy as we've just removed all the slot views we added - not needed now they are in a container
	//[self.dayView recheckViews];
	NSLog(@"dayView: Element order: (%d elements) %@", [self.dayView accessibilityElementCount], [self.dayView describeElementOrder]);
	
	[self.view addSubview:self.dayView];
		
	// Add a view after the 'hourly slots' to represent the day tabs
	UILabel* dayTabsLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, dayViewFrame.origin.y+dayViewFrame.size.height+20.0f, 150.0f, 30.0f)];
	dayTabsLabel.text = @"Day tabs";
	dayTabsLabel.tag = kTagDetailSlotBase + numCols + 5; // Make this the last element
	[self.view addSubview:dayTabsLabel];
	
	// Get the view hierarchy correctly sorted - not needed here as the views are all setup before being added to self.view
	//[(A11yContainerView*)self.view recheckViews];
	
	NSLog(@"Main view: Element order: (%d elements) %@", [(A11yContainerView*)self.view accessibilityElementCount], [(A11yContainerView*)self.view describeElementOrder]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)summaryTapped:(UITapGestureRecognizer*)sender
{
	if (sender.state == UIGestureRecognizerStateEnded)
	{
		// Disable this animation if VO is on as it can switch the focus too late
		BOOL doAnimation = UIAccessibilityIsVoiceOverRunning() == NO;
		[self.dayView setContentOffset:CGPointMake(self.dayView.frame.size.width, 0) animated:doAnimation];
		
		// Delay this so the scroll processing can happen - even without animation the processing and rebuild of a11y hierarchy is delayed
		double delayInSeconds = kDelayInScrollProcessing + 0.02;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void)
		{
			// Set the a11y focus to the first detail slot
			//UIView* slot0 = [self.dayView viewWithTag:kTagDetailSlotBase + 0];
			UIView* slot0 = [self.detailedSlotsContainer viewWithTag:kTagDetailSlotBase + 0];
			UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, slot0); // Indicate that a medium level amount of screen change has happened
		});
	}
}

/*
// For when the column views were direct in the dayView
- (void)setColumnViewsHiddenState:(BOOL)value
{
	self.detailSlotsHidden = value;
	for (UIView* view in self.dayView.subviews)
	{
		if (view.tag>=kTagDetailSlotBase)
			view.accessibilityElementsHidden = self.detailSlotsHidden;
	}
}

- (BOOL)columnViewsHiddenState
{
	return self.detailSlotsHidden;
}
*/

// Simple access onto the detailSlotsContainer view
- (void)setColumnViewsHiddenState:(BOOL)value
{
	self.detailedSlotsContainer.accessibilityElementsHidden = value;
}

- (BOOL)columnViewsHiddenState
{
	return self.detailedSlotsContainer.accessibilityElementsHidden;
}

- (void)buildItemsOntoView:(UIView*)targetView area:(CGRect)targetFrame cols:(int)numCols startTag:(int)startTag
{
	//const int numCols = 4;
	const int numRows = 1;
	
	float xInset = targetFrame.origin.x;
	float yInset = targetFrame.origin.y;
	
	float width = (targetFrame.size.width-xInset)/(float)numCols;
	float height = (targetFrame.size.height-yInset)/(float)numRows;
	
	int tagNum = startTag;
	
	float xPos = xInset;
	for (int i=0; i<numCols; i++)
	{
		float yPos = yInset;
		for (int j=0; j<numRows; j++)
		{
			CGRect viewFrame = CGRectMake(xPos, yPos, 0.66f*width, 0.66f*height);
			
			UIView* nView = [[UIView alloc] initWithFrame:viewFrame];
			
			nView.backgroundColor = [UIColor colorWithRed:(float)i/(float)numCols green:(float)j/(float)numRows blue:0.5f alpha:1.0f];
			nView.tag = tagNum++;
			nView.isAccessibilityElement = YES;
			nView.accessibilityLabel = [NSString stringWithFormat:@"%d: column %d, row %d", nView.tag-startTag, i, j];
			
			[targetView addSubview:nView];
			
			// Text label inside the view - the parent view (nView) is the a11y element so no need to worry about label problems
			UILabel* textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, viewFrame.size.height*0.1f, viewFrame.size.width, viewFrame.size.height*0.8f)];
			textLabel.text = [NSString stringWithFormat:@"%d", nView.tag-startTag]; // The item number
			textLabel.textAlignment = NSTextAlignmentCenter;
			[nView addSubview:textLabel];
			
			yPos += height;
		}
		
		xPos += width;
	}
}

#pragma mark - UIScrollView delegate methods to track the movement between day summary and detailed slot views
// From http://stackoverflow.com/questions/993280/how-to-detect-when-a-uiscrollview-has-finished-scrolling
-(void)scrollViewDidScroll:(UIScrollView *)sender
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:nil];
    // Ensure the end scrolling method is called as if we moved without animation it wont be without this...
    [self performSelector:@selector(scrollViewDidEndScrollingAnimation:) withObject:nil afterDelay:kDelayInScrollProcessing];
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:nil];
	
	// The scrollview has moved and ended moving
	
	// NB: scrollView param will be nil if we came in from the 'scrollViewDidScroll' call
	
	// Work out which part of the view we are looking at
	int pageNum = self.dayView.contentOffset.x / self.dayView.bounds.size.width;
	
	if (pageNum>0)
	{
		// On a detailed slot page - enable the a11y elements for the detail slots if we have just come from summary page
		if (self.columnViewsHiddenState == YES)
		{
			[self setColumnViewsHiddenState:NO];
			
			// Re-scan the hierarchy as what views are hidden or not from VO might have changed
			[self.dayView recheckViews];
			//[(A11yContainerView*)self.view recheckViews]; // Not sure this is needed as the content of this doesn't change now
			NSLog(@"Exposing columns: Element order: (%d elements) %@", [(A11yContainerView*)self.view accessibilityElementCount], [(A11yContainerView*)self.view describeElementOrder]);
			NSLog(@"dayView: Element order: (%d elements) %@", [self.dayView accessibilityElementCount], [self.dayView describeElementOrder]);
			NSLog(@"detailedSlotsContainer: Element order: (%d elements) %@", [self.detailedSlotsContainer accessibilityElementCount], [self.detailedSlotsContainer describeElementOrder]);
		}
	}
	else
	{
		if (self.columnViewsHiddenState == NO) // Were we on a detail page?
		{
			// Disable the a11y elements for the detail slots
			[self setColumnViewsHiddenState:YES];

			BOOL doAnimation = UIAccessibilityIsVoiceOverRunning() == NO;
			[self.dayView setContentOffset:CGPointMake(0.0f, 0.0f) animated:doAnimation]; // Reset it back to the full page 0 being on screen
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(scrollViewDidEndScrollingAnimation:) object:nil]; // Stop the repeat processing that doing the setContentOffset causes

			// Re-scan the hierarchy as what views are hidden or not from VO will have changed
			[self.dayView recheckViews];
			//[(A11yContainerView*)self.view recheckViews]; // Not sure this is needed as the content of this doesn't change now
			NSLog(@"Hiding columns: self.view: Element order: (%d elements) %@", [(A11yContainerView*)self.view accessibilityElementCount], [(A11yContainerView*)self.view describeElementOrder]);
			NSLog(@"dayView: Element order: (%d elements) %@", [self.dayView accessibilityElementCount], [self.dayView describeElementOrder]);
			//NSLog(@"detailedSlotsContainer: Element order: (%d elements) %@", [self.detailedSlotsContainer accessibilityElementCount], [self.detailedSlotsContainer describeElementOrder]);

			// Set main area of the summary view to be VO focus
			UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.summaryLabel);
		}
	}	
}

@end
