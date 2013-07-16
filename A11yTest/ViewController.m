//
//  ViewController.m
//  A11yTest
//
//  Created by Richard Groves on 09/07/2013.
//  Copyright (c) 2013 NoodlFroot Ltd. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

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
	
	[self.view addSubview:dn];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
