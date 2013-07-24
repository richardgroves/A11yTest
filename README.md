A11yTest
========

**Part 1**

Accessibility code test - demonstrates a problem with setIsAccessibilityElement in iOS6

The code is very simple and what it shows on screen is not really relevant - check the console log for the output of the isAccessibilityElement state of a label as various things are changed.

Key code is in ViewController.m/viewDidLoad.

Problem demonstrates on iOS simulator 6.0/6.1 when the accessibility inspector is ON.
On a device (tested on iPhone 5-iOS6.1.4 and iPad 3rd gen - iOS6.1.3) the problem shows up if 
    a) voice over is enabled
    b) The home button -> triple click -> Voice over setting is on (not used, just on)
    
The 'problem' can be removed by removing the MessageUI.framework from the project - no code in the project uses it, it is just linked in.

Hypothesis - there is a category in the MessageUI framework that overrides the setting of accessibility protocol methods and makes the isAccessibilityElement value of UILabel (at least) be OR'ed with (accessibilityIdentifier != nil)

Result: Confirmed by Chris Fleizach (cfleizach@apple.com) on the Apple Accessibility Dev mailing list, 16Jul13, that this is a bug caused by having MessageUI.framework linked in.

**Part 2**

Creates a view hierarchy that replicates what we have in the BBC Weather app for each location to demonstrate the problem with not being able to access the later hourly slots with the VO swipe once there are more than a certain number of views in the 'container'

To demonstrate the issue:
Run the app on a device
Enable voice over
Cycle from the 'Location name' label to the 'Summary area' label
Double tap to activate the button
Cycle rightwards to go through the 'hourly' columns
End of list indicator is triggered after just a few columns - rest are unreachable


Comment out line 98 of ViewController.m to reduce the number of columns below the problem threshold.
Re-do the above test - can now cycle through the pages and get to the 'Day tab' label in the end as intended.

