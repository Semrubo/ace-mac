//
//  AppDelegate.m
//  VATRP
//
//  Created by Ruben Semerjyan on 8/27/15.
//  Copyright (c) 2015 VTCSecure. All rights reserved.
//

#import "AppDelegate.h"
#import "HomeWindowController.h"
#import "AboutWindowController.h"
#import "LinphoneManager.h"
#import "AccountsService.h"
#import "RegistrationService.h"
#import "CallService.h"
#import "CallLogService.h"
#import "ChatService.h"
#import <HockeySDK/HockeySDK.h>

@interface AppDelegate () {
    HomeWindowController *homeWindowController;
    VideoCallWindowController *videoCallWindowController;
    AboutWindowController *aboutWindowController;
}

@end

@implementation AppDelegate

@synthesize loginWindowController;
@synthesize loginViewController;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    [AccountsService sharedInstance];
    [CallLogService sharedInstance];
    [RegistrationService sharedInstance];
    [CallService sharedInstance];
    [ChatService sharedInstance];

    videoCallWindowController = nil;
    
    // Set observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
    
    
    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"b7b28171bab92ce345aac7d54f435020"];
    [[BITHockeyManager sharedHockeyManager].crashManager setAutoSubmitCrashReport: YES];
    [[BITHockeyManager sharedHockeyManager] startManager];
    
    linphone_core_set_log_level(ORTP_ERROR);
    linphone_core_set_log_handler((OrtpLogFunc)linphone_iphone_log_handler);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    LinphoneCore *lc = [LinphoneManager getLc];
    if(linphone_core_get_current_call(lc)){
        linphone_core_terminate_all_calls(lc);
    }
}

+ (AppDelegate*)sharedInstance {
    return (AppDelegate*)[NSApplication sharedApplication].delegate;
}

- (void) showTabWindow {
    homeWindowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"HomeWindowController"];
    [homeWindowController showWindow:self];

    [[AppDelegate sharedInstance].loginWindowController close];
    [AppDelegate sharedInstance].loginWindowController = nil;
}

-(NSPoint) getTabWindowOrigin{
    NSPoint origin = [homeWindowController getWindowOrigin];
    return origin;
}

-(NSPoint) getTabWindowSize{
    CGSize cgSize = [homeWindowController getWindowSize];
    NSPoint size = {cgSize.width, cgSize.height};
    return size;
}

-(void) applicationDidResignActive:(NSNotification *)notification{
    CallWindowController *callWindowController = [[CallService sharedInstance] getCallWindowController];
    if(callWindowController){
        LinphoneCall *call = linphone_core_get_current_call([LinphoneManager getLc]);
        if(call){
            [callWindowController.window orderFrontRegardless];
            [callWindowController.window setLevel:NSFloatingWindowLevel];
            [self.viewController.videoMailWindowController enableSelfVideo];
        }
    }
}

-(void) setTabWindowPos:(NSPoint)pos{
    [homeWindowController setWindowPos:pos];
}

- (void) closeTabWindow {
    [homeWindowController close];
    homeWindowController = nil;
}

- (VideoCallWindowController*) getVideoCallWindow {
    if (!videoCallWindowController) {
        videoCallWindowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"VideoCall"];
        [videoCallWindowController showWindow:self];
    }
    
    return videoCallWindowController;
}

- (void)onMenuItemPreferences:(id)sender {
    [viewController showSettingsWindow];
}

- (IBAction)onMenuItemAbout:(id)sender {
    if (!aboutWindowController) {
        aboutWindowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"AboutWindowController"];
        [aboutWindowController showWindow:self];
    } else {
        [aboutWindowController showWindow:self];
    }
}

- (void)onMenuItemPreferencesSignOut:(id)sender {
    AccountModel *accountModel = [[AccountsService sharedInstance] getDefaultAccount];
    
    if (accountModel) {
        [[AccountsService sharedInstance] removeAccountWithUsername:accountModel.username];
        [[AccountsService sharedInstance] addAccountWithUsername:accountModel.username
                                                        Password:@""
                                                          Domain:@""
                                                       Transport:@""
                                                            Port:0
                                                       isDefault:YES];
    }
    
    [self closeTabWindow];
    [viewController closeAllWindows];
    
    // Get the default proxyCfg in Linphone
    LinphoneProxyConfig* proxyCfg = NULL;
    linphone_core_get_default_proxy([LinphoneManager getLc], &proxyCfg);
    
    // To unregister from SIP
    linphone_proxy_config_edit(proxyCfg);
    linphone_proxy_config_enable_register(proxyCfg, false);
    linphone_proxy_config_done(proxyCfg);
    
    self.loginWindowController = [[NSStoryboard storyboardWithName:@"Main" bundle:nil] instantiateControllerWithIdentifier:@"LoginWindowController"];
    [self.loginWindowController showWindow:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.loginViewController
                                             selector:@selector(configuringUpdate:)
                                                 name:kLinphoneConfiguringStateUpdate
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.loginViewController
                                             selector:@selector(registrationUpdateEvent:)
                                                 name:kLinphoneRegistrationUpdate
                                               object:nil];
}

- (void)registrationUpdateEvent:(NSNotification*)notif {
    LinphoneRegistrationState state = (LinphoneRegistrationState)[[notif.userInfo objectForKey: @"state"] intValue];
    
    if (state == LinphoneRegistrationOk) {
        [self.menuItemSignOut setAction:@selector(onMenuItemPreferencesSignOut:)];
    } else {
        [self.menuItemSignOut setAction:nil];
    }
}

void linphone_iphone_log_handler(int lev, const char *fmt, va_list args) {
    NSString *format = [[NSString alloc] initWithUTF8String:fmt];
    NSString *formatedString = [[NSString alloc] initWithFormat:format arguments:args];
    char levelC = 'I';
    switch ((OrtpLogLevel)lev) {
        case ORTP_FATAL:
            levelC = 'F';
            break;
        case ORTP_ERROR:
            levelC = 'E';
            break;
        case ORTP_WARNING:
            levelC = 'W';
            break;
        case ORTP_MESSAGE:
            levelC = 'I';
            break;
        case ORTP_TRACE:
        case ORTP_DEBUG:
            levelC = 'D';
            break;
        case ORTP_LOGLEV_END:
            return;
    }
    // since \r are interpreted like \n, avoid double new lines when logging packets
    NSLog(@"%c %@", levelC, [formatedString stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"]);
}

@end
