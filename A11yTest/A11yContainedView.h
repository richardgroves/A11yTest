//
//  A11yContainedView.h
//  A11yTest
//
//  Created by Richard Groves on 25/07/2013.
//  Copyright (c) 2013 NoodlFroot Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface A11yContainedView : UIView

@property (nonatomic, assign) id accessibilityContainer;

@end

@interface A11yContainedLabel : UILabel

@property (nonatomic, assign) id accessibiilityContainer;

@end
