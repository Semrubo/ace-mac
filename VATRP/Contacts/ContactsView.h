//
//  ContactsView.h
//  ACE
//
//  Created by User on 24/11/15.
//  Copyright © 2015 VTCSecure. All rights reserved.
//

#import "BackgroundedViewController.h"

@interface ContactsView : BackgroundedViewController
- (void) setFrame:(NSRect)frame;
- (void)refreshContactList;
-(void)clearData;
@end
