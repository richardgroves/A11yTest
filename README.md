A11yTest
========

Accessibility code test - demonstrates a problem with setIsAccessibilityElement in iOS6

The code is very simple and what it shows on screen is not really relevant - check the console log for the output of the isAccessibilityElement state of a label as various things are changed.

Key code is in ViewController.m/viewDidLoad.

Problem demonstrates on iOS simulator 6.0/6.1 when the accessibility inspector is ON.
On a device (tested on iPhone 5-iOS6.1.4 and iPad 3rd gen - iOS6.1.3) the problem shows up if 
    a) voice over is enabled
    b) The home button -> triple click -> Voice over setting is on (not used, just on)
    
The 'problem' can be removed by removing the MessageUI.framework from the project - no code in the project uses it, it is just linked in.

Hypothesis - there is a category in the MessageUI framework that overrides the setting of accessibility protocol methods and makes the isAccessibilityElement value of UILabel (at least) be OR'ed with (accessibilityIdentifier != nil)

