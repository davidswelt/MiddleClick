//
//  TrayMenu.m
//
//  Created by Clem on 21.06.09.
//

#import "TrayMenu.h"
#import "Controller.h"

@implementation TrayMenu

- (id)initWithController:(Controller *)ctrl
{
	[super init];
	myController = ctrl;
	return self;
}
	

- (void) openWebsite:(id)sender {
	NSURL *url = [NSURL URLWithString:@"http://clement.beffa.org/labs/projects/middleclick/"];
	[[NSWorkspace sharedWorkspace] openURL:url];
	//[url release];
}

- (void)setSingleTap:(id)sender
{
	[myController setTap1Type:singleTapItem.state==NSOffState?SINGLE_CLICK:NO_CLICK];
	[self setChecks];
}

- (void)set3TapMiddle:(id)sender
{
	[myController setTap3Type:tapItem.state==NSOffState?MIDDLE_CLICK:NO_CLICK];
	[self setChecks];
}

- (void)set3TapDouble:(id)sender
{
	[myController setTap3Type:doubleTapItem.state==NSOffState?DOUBLE_CLICK:NO_CLICK];
	[self setChecks];
}

- (void)set3ClickMiddle:(id)sender
{
	[myController setClick3Type:clickItem.state==NSOffState?MIDDLE_CLICK:NO_CLICK];
	[self setChecks];
}

- (void)set3ClickDouble:(id)sender
{
	[myController setClick3Type:doubleClickItem.state==NSOffState?DOUBLE_CLICK:NO_CLICK];
	[self setChecks];
}
 


- (void)setChecks
{
	[singleTapItem setState:(myController->tap1Type==SINGLE_CLICK?NSOnState:NSOffState)];
	[tapItem setState:(myController->tap3Type==MIDDLE_CLICK?NSOnState:NSOffState)];
	[doubleTapItem setState:(myController->tap3Type==DOUBLE_CLICK?NSOnState:NSOffState)];
	[clickItem setState:(myController->click3Type==MIDDLE_CLICK?NSOnState:NSOffState)];
	[doubleClickItem setState:(myController->click3Type==DOUBLE_CLICK?NSOnState:NSOffState)];
}

- (void) openFinder:(id)sender {
	[[NSWorkspace sharedWorkspace] launchApplication:@"Finder"];
}

- (void) actionQuit:(id)sender {
	[NSApp terminate:sender];
}

- (NSMenu *) createMenu {
	NSZone *menuZone = [NSMenu menuZone];
	NSMenu *menu = [[NSMenu allocWithZone:menuZone] init];
	NSMenuItem *menuItem;
	
	// Add About
	menuItem = [menu addItemWithTitle:@"About MiddleClick"
							   action:@selector(openWebsite:)
						keyEquivalent:@""];
	[menuItem setTarget:self];
	
	
	singleTapItem = [menu addItemWithTitle:@"Single Finger Tap for Left Click" action:@selector(setSingleTap:) keyEquivalent:@""];
	[singleTapItem setTarget:self];
	
	clickItem = [menu addItemWithTitle:@"3 Finger Click: middle" action:@selector(set3ClickMiddle:) keyEquivalent:@""];
	[clickItem setTarget:self];
	doubleClickItem = [menu addItemWithTitle:@"3 Finger Click: double" action:@selector(set3ClickDouble:) keyEquivalent:@""];
	[doubleClickItem setTarget:self];
	
	tapItem = [menu addItemWithTitle:@"3 Finger Tap: middle" action:@selector(set3TapMiddle:) keyEquivalent:@""];
	[tapItem setTarget:self];
	doubleTapItem = [menu addItemWithTitle:@"3 Finger Tap: double" action:@selector(set3TapDouble:) keyEquivalent:@""];
	[doubleTapItem setTarget:self];

	[self setChecks];
	
	// Add Separator
	[menu addItem:[NSMenuItem separatorItem]];
	
	// Add Quit Action
	menuItem = [menu addItemWithTitle:@"Quit"
							   action:@selector(actionQuit:)
						keyEquivalent:@""];
	[menuItem setTarget:self];
	
	return menu;
}

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
	NSMenu *menu = [self createMenu];
	
	_statusItem = [[[NSStatusBar systemStatusBar]
					statusItemWithLength:NSSquareStatusItemLength] retain];
	[_statusItem setMenu:menu];
	[_statusItem setHighlightMode:YES];
	[_statusItem setToolTip:@"MiddleClick"];
	[_statusItem setImage:[NSImage imageNamed:@"mouse.png"]];
	
	[menu release];
}

@end