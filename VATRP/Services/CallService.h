//
//  CallService.h
//  ACE
//
//  Created by Ruben Semerjyan on 10/16/15.
//  Copyright © 2015 VTCSecure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CallWindowController.h"
#import "LinphoneManager.h"

@interface CallService : NSObject

+ (CallService *)sharedInstance;
- (CallWindowController*) getCallWindowController;
- (void)closeCallWindowController;
+ (void) callTo:(NSString*)number;
- (int) decline:(LinphoneCall*)aCall;
- (bool) accept:(LinphoneCall*)aCall;
- (void) pause:(LinphoneCall*)aCall;
- (void) resume:(LinphoneCall*)aCall;
- (void) swapCallsToCall:(LinphoneCall*)aCall;
- (LinphoneCall*) getCurrentCall;
- (NSString*) getLastCalledUsername;
- (void)setDeclineMessage:(NSString*)declineMsg;
- (void) closeCallWindow;

//-(void)tempDebugMethodForIncomingCall:(NSString*)message call:(LinphoneCall*)call

@end
