//
//  TrayMenu.h
//
//  Created by Clem on 21.06.09.
//

#import <Foundation/Foundation.h>
#import "Controller.h"


@interface TrayMenu : NSObject {
@private
	NSStatusItem *_statusItem;
	Controller *myController;
	NSMenuItem *tapItem;
	NSMenuItem *clickItem;
	NSMenuItem *singleTapItem;
	NSMenuItem *doubleClickItem;
	NSMenuItem *doubleTapItem;
}
- (id)initWithController:(Controller *)ctrl;
- (void)setChecks;
@end