//
//  A11yContainedView.m
//  A11yTest
//
//  Created by Richard Groves on 25/07/2013.
//  Copyright (c) 2013 NoodlFroot Ltd. All rights reserved.
//

#import "A11yContainedView.h"

@implementation A11yContainedView

- (id)accessibilityContainer
{
	return self.override_accessibilityContainer;
}

@end

@implementation A11yContainedLabel

- (id)accessibilityContainer
{
	return self.override_accessibilityContainer;
}

@end
