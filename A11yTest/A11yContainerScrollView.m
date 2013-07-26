//
//  A11yContainerView.m
//  A11yTest
//
//  Created by Richard Groves on 19/07/2013.
//  Copyright (c) 2013 NoodlFroot Ltd. All rights reserved.
//

// NB: Identical in code to the A11ContainerView class - just a different base class. Just when you need multiple inheritance it isn't there...

// UIScrollView subclass that implements the UIAccessibilityContainer protocol by trapping add/remove subview to scan the added items
// Also has a manual re-scan method for when the user of the view knows the internal state has changed

#import "A11yContainerScrollView.h"
#import "A11yContainedView.h"

@interface A11yContainerScrollView ()
@property (strong, nonatomic) NSMutableArray* accessibilityElements;
@end

@implementation A11yContainerScrollView

// Lazy loading accessor, avoids instantiaton in initWithCoder and initWithFrame and init.
-(NSMutableArray *)accessibilityElements
{
    if (_accessibilityElements == nil)
        _accessibilityElements = [NSMutableArray array];
	
    return _accessibilityElements;
}

- (void)sortElementsIntoOrder
{
	[self.accessibilityElements sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
	 {
		 // Here we'll sort using the tag, but really any sort is possible.
		 UIView* view1 = obj1;
		 UIView* view2 = obj2;
		 
		 if (view1.tag < view2.tag) return NSOrderedAscending;
		 if (view1.tag > view2.tag) return NSOrderedDescending;
		 return NSOrderedSame;
	 }];
}

// An array of strings indicating the order of a11y identifiers
- (NSArray*)describeElementOrder
{
	NSMutableArray* identifiers = [NSMutableArray arrayWithCapacity:self.accessibilityElementCount];
	for (int i=0; i<self.accessibilityElementCount; i++)
	{
		id element = [self accessibilityElementAtIndex:i];
		UIView* view = element;
		long long tag = view.tag;
		
		NSString* identifier = view.accessibilityIdentifier;
		if (identifier == nil) // handle identifier being nil, and tack on the a11y label if it exists. Will miss some eg. UILabel that just have their .text
		{
			identifier = [element accessibilityLabel];
		}
		else if (view.accessibilityLabel)
		{
			identifier = [NSString stringWithFormat:@"%@ : %@", identifier, view.accessibilityLabel];
		}
		
		NSString* itemDesc = [NSString stringWithFormat:@"%lld: %@: %p: %@. Frame: %@", tag, [view class], view, identifier ?: [view description], NSStringFromCGRect(view.frame)];
		[identifiers addObject:itemDesc];
	}
	
	return identifiers;
}

#pragma mark - Required accessibility methods...
-(BOOL)isAccessibilityElement
{
    return NO;
}

-(NSInteger)accessibilityElementCount
{
    return self.accessibilityElements.count;
}

-(id)accessibilityElementAtIndex:(NSInteger)index
{
    return self.accessibilityElements[index];
}

-(NSInteger)indexOfAccessibilityElement:(id)element
{
	for (int i=0; i<self.accessibilityElementCount; i++)
	{
		NSDictionary* entry = self.accessibilityElements[i];
		id view = entry;
		if (view == element)
			return i;
	}
	
	return NSNotFound;
}

- (void)checkSubviewForAdding:(UIView *)subview
{
	// If the new subview is a visible accessibilty element add it to the array and then sort the array.
	if (subview.accessibilityElementsHidden == NO)
	{
	    if (subview.isAccessibilityElement == YES)
		{
			// Set the a11y container on the subview to self if we can (eg using one of our override classes)
			if ([subview respondsToSelector:@selector(setOverride_accessibilityContainer:)])
				[(id)subview setOverride_accessibilityContainer:self];
			
			[self.accessibilityElements addObject:subview];
			
			[self sortElementsIntoOrder];
    	}
		else if ([subview isKindOfClass:[self class]] == NO || // Don't scan down other A11yContainers
				 [subview respondsToSelector:@selector(accessibilityElementCount)] == NO ||
				 [subview accessibilityElementCount] == NSIntegerMax) // No something that really supports the UIAccessibilityContainer protocol
		{
			// Recursively add the subviews - simple hierarchy where the total mass of tag values have to avoid each other or take their chances
			for (UIView* sv in subview.subviews)
				[self checkSubviewForAdding:sv];
		}
	}
}

-(void)didAddSubview:(UIView *)subview
{
    [super didAddSubview:subview];
	
    [self checkSubviewForAdding:subview];
}

-(void)willRemoveSubview:(UIView *)subview
{
    [super willRemoveSubview:subview];
	
	// If this view was in the a11y elements then remove it
	NSInteger viewIndex = [self indexOfAccessibilityElement:subview];
	if (viewIndex != NSNotFound)
		[self.accessibilityElements removeObjectAtIndex:viewIndex];
}

// Client can call a re-scan on the hierarchy in case sub-views change (didAdd/willRemove only catch direct subviews, not grand child or further) or a11y states (hidden, isElement) change
- (void)recheckViews
{
	NSLog(@"Recheck views: Were %d elements", self.accessibilityElementCount);
	
	_accessibilityElements = nil;
	
	for (UIView* sv in self.subviews)
		[self checkSubviewForAdding:sv];
	
	NSLog(@"Recheck views: Now %d elements", self.accessibilityElementCount);
}

@end
