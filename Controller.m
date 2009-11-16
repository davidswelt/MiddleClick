//
//  Controller.m
//  MiddleClick
//
//  Created by Alex Galonsky on 11/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
#import <Cocoa/Cocoa.h>
#import "TrayMenu.h"
#include <math.h>
#include <unistd.h>
#include <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h> 
#import "WakeObserver.h"




@implementation Controller

- (void) start
{
	callbackController =  self;
	//pressed = NO;
	tap1Type = SINGLE_CLICK;
	tap3Type = DOUBLE_CLICK;
	click1Type = NO_CLICK;
	click3Type = MIDDLE_CLICK;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
    [NSApplication sharedApplication];
	
	//
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
								 [NSNumber numberWithInt:tap1Type], @"tap1Type",
								 [NSNumber numberWithInt:tap3Type], @"tap3Type",
								 [NSNumber numberWithInt:click1Type], @"click1Type",
								 [NSNumber numberWithInt:click3Type], @"click3Type", nil];
	[defaults registerDefaults:appDefaults];
	tap1Type = [[NSUserDefaults standardUserDefaults] integerForKey:@"tap1Type"];
	tap3Type = [[NSUserDefaults standardUserDefaults] integerForKey:@"tap3Type"];
	click1Type = [[NSUserDefaults standardUserDefaults] integerForKey:@"click1Type"];
	click3Type = [[NSUserDefaults standardUserDefaults] integerForKey:@"click3Type"];
	
	
	//Get list of all multi touch devices
	NSMutableArray* deviceList = (NSMutableArray*)MTDeviceCreateList(); //grab our device list
	
	
	//Iterate and register callbacks for multitouch devices.
	for(int i = 0; i<[deviceList count]; i++) //iterate available devices
	{
		MTRegisterContactFrameCallback((MTDeviceRef)[deviceList objectAtIndex:i], callback); //assign callback for device
		MTDeviceStart((MTDeviceRef)[deviceList objectAtIndex:i]); //start sending events
	}
	
	
	//register a callback to know when osx come back from sleep
	WakeObserver *wo = [[WakeObserver alloc] init];
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: wo selector: @selector(receiveWakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];
	
	
	//add traymenu
    TrayMenu *menu = [[TrayMenu alloc] initWithController:self];
    [NSApp setDelegate:menu];
    [NSApp run];
	
	
	[pool release];
}

- (BOOL)getClickMode
{
return false;
} 

- (void)setTap1Type:(int)type
{
	tap1Type = type;
	[[NSUserDefaults standardUserDefaults] setInteger:type forKey:@"tap1Type"];
}
- (void)setTap3Type:(int)type
{
	tap3Type = type;
	[[NSUserDefaults standardUserDefaults] setInteger:type forKey:@"tap3Type"];
}
- (void)setClick1Type:(int)type
{
	click1Type = type;
	[[NSUserDefaults standardUserDefaults] setInteger:type forKey:@"click1Type"];
}
- (void)setClick3Type:(int)type
{
	click3Type = type;
	[[NSUserDefaults standardUserDefaults] setInteger:type forKey:@"click3Type"];
}


void PostMouseEvent(CGMouseButton button, CGEventType type, const CGPoint point, int clickCount)
{
    CGEventRef theEvent = CGEventCreateMouseEvent(NULL, type, point, button);
    CGEventSetType(theEvent, type);
	CGEventSetIntegerValueField(theEvent, kCGMouseEventClickState, clickCount);
    CGEventPost(kCGHIDEventTap, theEvent);
    CFRelease(theEvent);
}

- (void) sendClickInputType:(int) type
{
	CGEventRef ourEvent = CGEventCreate(NULL);
	CGPoint ourLoc = CGEventGetLocation(ourEvent);
	switch (type)
	{
	case SINGLE_CLICK:
			
			PostMouseEvent(   kCGMouseButtonLeft, kCGEventLeftMouseDown, ourLoc, 1);
			PostMouseEvent(   kCGMouseButtonLeft, kCGEventLeftMouseUp, ourLoc, 1);
			break;
	case MIDDLE_CLICK:
		// Real middle click
		CGPostMouseEvent( ourLoc, 1, 3, 0, 0, 1);
		CGPostMouseEvent( ourLoc, 1, 3, 0, 0, 0);
			break;
	case DOUBLE_CLICK:
		PostMouseEvent(   kCGMouseButtonLeft, kCGEventLeftMouseDown, ourLoc, 2);
		PostMouseEvent(   kCGMouseButtonLeft, kCGEventLeftMouseUp, ourLoc, 2);
//		PostMouseEvent(   kCGMouseButtonLeft, kCGEventLeftMouseDown, ourLoc, 2);
//		PostMouseEvent(   kCGMouseButtonLeft, kCGEventLeftMouseUp, ourLoc, 2);
			break;
	case NO_CLICK:
		break;
	}
}

- (void) executeClickType:(BOOL) clicked  withFingers:(int) numFingers
{

	if (numFingers == 1)
	{
		if (clicked)
			[self sendClickInputType:click1Type];
		else
			[self sendClickInputType: tap1Type];
			
	} else {

		if (clicked)
			[self sendClickInputType: click3Type];
		else
			[self sendClickInputType: tap3Type];
	}
}


int callback(int device, Finger *data, int nFingers, double timestamp, int frame) {

	
	static BOOL maybeMiddleClick = NO;
	static BOOL pressed = NO;
	static int nFingersUsed = 0;
	static CGPoint touchStartLoc;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];	
	
	if(pressed)
	{
		[callbackController executeClickType: YES withFingers: nFingers==3?3:1];

		/*		
		if(nFingers == 3)
		{
			if(!pressed)
			{
				CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)55, true );
				pressed = YES;
			}
			
		}
		else {
			if(pressed)
			{
				CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)55, false );
				pressed = NO;
			}
		}
	  */
	}
	else 
	 
	{
		
		/* let's recognize numFingers not as absolute number, but by the difference in Fingers
		 i.e. let them move mouse with two fingers and tap with a third */
		
		// get the current pointer location
		CGEventRef ourEvent = CGEventCreate(NULL);
		CGPoint ourLoc = CGEventGetLocation(ourEvent);
		if (nFingers==0){
			if(middleclickX+middleclickY) {
				
				float delta = ABS(middleclickX-middleclickX2)+ABS(middleclickY-middleclickY2); 
				float deltaLoc = ABS(touchStartLoc.x - ourLoc.x)+ABS(touchStartLoc.y - ourLoc.y);
				if (delta < 0.4f && deltaLoc < 10 && -[touchStartTime timeIntervalSinceNow]<0.3f) {
					// Emulate a middle or left click
					

					
					/*
					 // CMD+Click code
					 CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)55, true );
					 CGPostMouseEvent( ourLoc, 1, 1, 1);
					 CGPostMouseEvent( ourLoc, 1, 1, 0);
					 CGPostKeyboardEvent( (CGCharCode)0, (CGKeyCode)55, false );
					 */
					
					if (nFingersUsed == 1 )
					{
						if (ABS(middleclickX-middleclickX2)<2 && ABS(middleclickY-middleclickY2)<2)
						{
							[callbackController executeClickType: pressed withFingers:1];
							maybeMiddleClick = NO;
							middleclickX = 0.0f;
							middleclickY = 0.0f;
							touchStartTime = NULL;	
						}
					}
					else {
						[callbackController executeClickType: pressed withFingers: 3];

					}
				}
			}
			touchStartTime = NULL;
			maybeMiddleClick = NO;	
			
		} else if (nFingers>0 && touchStartTime == NULL){		
			NSDate *now = [[NSDate alloc] init];
			touchStartTime = [now retain];
			[now release];
			
			maybeMiddleClick = YES;
			middleclickX = 0.0f;
			middleclickY = 0.0f;
			nFingersUsed = nFingers;
			touchStartLoc = ourLoc;
		} else {
			if (maybeMiddleClick==YES){
				NSTimeInterval elapsedTime = -[touchStartTime timeIntervalSinceNow];  
				if (elapsedTime > 0.5f)
					maybeMiddleClick = NO;
			}
		}
		
		if (nFingers>3) {
			maybeMiddleClick = NO;
			middleclickX = 0.0f;
			middleclickY = 0.0f;
		}
		
		if (nFingers==3) {
			Finger *f1 = &data[0];
			Finger *f2 = &data[1];
			Finger *f3 = &data[2];
			
			if (maybeMiddleClick==YES) {
				middleclickX = (f1->normalized.pos.x+f2->normalized.pos.x+f3->normalized.pos.x);
				middleclickY = (f1->normalized.pos.y+f2->normalized.pos.y+f3->normalized.pos.y);
				middleclickX2 = middleclickX;
				middleclickY2 = middleclickY;
				maybeMiddleClick=NO;
			} else {
				middleclickX2 = (f1->normalized.pos.x+f2->normalized.pos.x+f3->normalized.pos.x);
				middleclickY2 = (f1->normalized.pos.y+f2->normalized.pos.y+f3->normalized.pos.y);
			}
		} else if (nFingers==1) {
			Finger *f1 = &data[0];
			
			if (maybeMiddleClick==YES) {
				middleclickX =  f1->normalized.pos.x;
				middleclickY =  f1->normalized.pos.y;
				middleclickX2 = middleclickX;
				middleclickY2 = middleclickY;
				maybeMiddleClick=NO;
			} else {
				middleclickX2 = f1->normalized.pos.x;
				middleclickY2 = f1->normalized.pos.y;
			}
		}
	}

	
	[pool release];
	return 0;
}

@end
