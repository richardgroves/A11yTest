//
//  A11yContainerScrollView.h
//  A11yTest
//
//  Created by Richard Groves on 19/07/2013.
//  Copyright (c) 2013 NoodlFroot Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface A11yContainerScrollView : UIScrollView

- (void)recheckViews;
- (NSArray*)describeElementOrder;

@end
