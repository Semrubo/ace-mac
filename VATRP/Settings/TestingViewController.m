//
//  TestingViewController.m
//  ACE
//
//  Created by Ruben Semerjyan on 10/8/15.
//  Copyright © 2015 VTCSecure. All rights reserved.
//

#import "TestingViewController.h"
#import "LinphoneManager.h"
#import "CallService.h"
#import "SettingsService.h"
#import "AppDelegate.h"
#import "SettingsHandler.h"
#import "FXKeyChain.h"
#import "AccountsService.h"
#import "SettingsConstants.h"

@interface TestingViewController () {
    BOOL isChanged;
}

@property (weak) IBOutlet NSButton *buttonEnableAVPF;
@property (weak) IBOutlet NSButton *buttonSendDTMF;
@property (weak) IBOutlet NSButton *buttonEnableAdaptiveRateControl;
@property (weak) IBOutlet NSComboBox *comboBoxRTCPFeedBack;

@property (weak) IBOutlet NSTextField *textFieldMaxUpload;
@property (weak) IBOutlet NSTextField *textFieldMaxDownload;
@property (weak) IBOutlet NSButton *buttonQoS;
@property (weak) IBOutlet NSTextField *textFieldSignaling;
@property (weak) IBOutlet NSTextField *textFieldAudio;
@property (weak) IBOutlet NSTextField *textFieldVideo;

@property (strong) SettingsWindowController* parentWindowController;

@end

@implementation TestingViewController

-(id) init:(SettingsWindowController*)parentController
{
    self = [super initWithNibName:@"TestingViewController" bundle:nil];
    if (self)
    {
        // init
        self.parentWindowController = parentController;
    }
    return self;
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self initializeData];
    // Do view setup here.
    // note: when we open the dialog for teh second time, this method will nto be called, so items will not be refreshed.
    // moving initialization into a separate emthod that will e call from this as well as the viewWillAppear method.
    
    // this method is a good place for items that are permanent changes to the presentation of the dialog or delegates, not for values.
    
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle:NSNumberFormatterNoStyle];
    [numberFormatter setAllowsFloats:NO];
    [[self.textFieldMaxUpload cell] setFormatter:numberFormatter];
    [[self.textFieldMaxDownload cell] setFormatter:numberFormatter];
    
    [self.textFieldMaxUpload setDelegate:self];
    [self.textFieldMaxDownload setDelegate:self];
    [self.buttonEnableAVPF setEnabled:NO];
    [self.buttonEnableAVPF removeFromSuperview];
    
    [self.comboBoxRTCPFeedBack setEditable:NO];
    
    [self initializeData];
}

-(void)initializeData{
    LinphoneProxyConfig* proxyCfg = linphone_core_get_default_proxy_config([LinphoneManager getLc]);

    if (proxyCfg) {
        self.buttonEnableAVPF.state = linphone_proxy_config_avpf_enabled(proxyCfg);
    }
    
    self.buttonEnableAdaptiveRateControl.state = linphone_core_adaptive_rate_control_enabled([LinphoneManager getLc]);
    
//    SettingsHandler* settingsHandler = [SettingsHandler settingsHandler];
//    int upBand = [settingsHandler getUploadBandwidth];
    self.textFieldMaxUpload.intValue = linphone_core_get_upload_bandwidth([LinphoneManager getLc]);
    self.textFieldMaxDownload.intValue = linphone_core_get_download_bandwidth([LinphoneManager getLc]);
    
    NSString *rtcpFbMode = [SettingsHandler.settingsHandler getRtcpFbMode];
    if(!rtcpFbMode){ rtcpFbMode = @"Implicit"; }
    
    [self.comboBoxRTCPFeedBack setStringValue:rtcpFbMode];
    self.buttonQoS.state = [[SettingsHandler settingsHandler] isQosEnabled];
    if (![[SettingsHandler settingsHandler] getQoSEnabled]) {
        self.textFieldSignaling.stringValue =  [NSString stringWithFormat:@"%i",0];
        self.textFieldAudio.stringValue = [NSString stringWithFormat:@"%i",0];
        self.textFieldVideo.stringValue = [NSString stringWithFormat:@"%i",0];
    } else {
        self.textFieldSignaling.stringValue =  [NSString stringWithFormat:@"%i",[[SettingsHandler settingsHandler] getQoSSignalingValue]];
        self.textFieldAudio.stringValue = [NSString stringWithFormat:@"%i",[[SettingsHandler settingsHandler] getQoSAudioValue]];
        self.textFieldVideo.stringValue = [NSString stringWithFormat:@"%i",[[SettingsHandler settingsHandler] getQoSVideoValue]];
    }
}


- (void) save {
    [self saveQosValues];
    if (!isChanged) {
        return;
    }
    
//    if (proxyCfg) {
//        linphone_proxy_config_enable_avpf(proxyCfg, self.buttonEnableAVPF.state);
//    }
    
    linphone_core_set_use_info_for_dtmf([LinphoneManager getLc], self.buttonSendDTMF.state);
    linphone_core_enable_adaptive_rate_control([LinphoneManager getLc], self.buttonEnableAdaptiveRateControl.state);
    
    SettingsHandler* settingsHandler = [SettingsHandler settingsHandler];
    int uploadBandwidth = self.textFieldMaxUpload.intValue;
    if (uploadBandwidth > 0)
    {
        // sets the value int he linphone core if the core exists.
        [settingsHandler setUploadBandwidth:uploadBandwidth];
    }
    int downloadBandwidth = self.textFieldMaxDownload.intValue;
    if (downloadBandwidth > 0)
    {
        // sets the value int he linphone core if the core exists.
        [settingsHandler setDownloadBandwidth:downloadBandwidth];
    }
}

- (void)saveQosValues {
    bool stateQoS = [self.buttonQoS state];
    [[SettingsHandler settingsHandler] setQoSEnable:stateQoS];
    if (stateQoS)
    {
        NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        int signalValue = 24;
        if (self.textFieldSignaling.stringValue != nil)
        {
            // verify integer value, if not leave as default
            if ([self.textFieldSignaling.stringValue rangeOfCharacterFromSet:notDigits].location == NSNotFound)
            {
                signalValue = self.textFieldSignaling.intValue;
            }
            else
            {
                self.textFieldSignaling.stringValue = [NSString stringWithFormat:@"%d",signalValue];
            }
        }
        int audioValue = 46;
        if (self.textFieldAudio.stringValue != nil)
        {
            // verify integer value, if not leave as default
            if ([self.textFieldAudio.stringValue rangeOfCharacterFromSet:notDigits].location == NSNotFound)
            {
                audioValue = self.textFieldAudio.intValue;
            }
            else
            {
                self.textFieldAudio.stringValue = [NSString stringWithFormat:@"%d",audioValue];
            }
        }
        int videoValue = 46;
        if (self.textFieldVideo.stringValue != nil)
        {
            // verify integer value, if not leave as default
            if ([self.textFieldVideo.stringValue rangeOfCharacterFromSet:notDigits].location == NSNotFound)
            {
                videoValue = self.textFieldVideo.intValue;
            }
            else
            {
                self.textFieldVideo.stringValue = [NSString stringWithFormat:@"%d",videoValue];
            }
        }
        [[SettingsHandler settingsHandler] setQoSSignalingValue:signalValue];
        [[SettingsHandler settingsHandler] setQoSAudioValue:audioValue];
        [[SettingsHandler settingsHandler] setQoSVideoValue:videoValue];
        if ([LinphoneManager getLc] != nil)
        {
            linphone_core_set_sip_dscp([LinphoneManager getLc], signalValue);
            linphone_core_set_audio_dscp([LinphoneManager getLc], audioValue);
            linphone_core_set_video_dscp([LinphoneManager getLc], videoValue);
        }
    }
    else
    {
        linphone_core_set_sip_dscp([LinphoneManager getLc], 0);
        linphone_core_set_audio_dscp([LinphoneManager getLc], 0);
        linphone_core_set_video_dscp([LinphoneManager getLc], 0);
    }
}

- (IBAction)onCheckBox:(id)sender {
    isChanged = YES;
}

- (IBAction)onQoSCheckBox:(id)sender {
    [self.textFieldSignaling setEditable:self.buttonQoS.state];
    [self.textFieldAudio setEnabled:self.buttonQoS.state];
    [self.textFieldVideo setEnabled:self.buttonQoS.state];
    if (self.buttonQoS.state) {
        self.textFieldSignaling.stringValue =  [NSString stringWithFormat:@"%i", [[SettingsHandler settingsHandler] getQoSSignalingValue]];
        self.textFieldAudio.stringValue = [NSString stringWithFormat:@"%i", [[SettingsHandler settingsHandler] getQoSAudioValue]];
        self.textFieldVideo.stringValue = [NSString stringWithFormat:@"%i", [[SettingsHandler settingsHandler] getQoSVideoValue]];
    } else {
        self.textFieldSignaling.stringValue = @"0";
        self.textFieldAudio.stringValue = @"0";
        self.textFieldVideo.stringValue = @"0";
    }
    
    isChanged = YES;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    isChanged = YES;
}
- (IBAction)onRTCPFeedbackSelected:(id)sender
{
    NSString *rtcpFeedback = ((NSComboBox*)sender).stringValue;
    [[SettingsHandler settingsHandler] setRtcpFbMode:rtcpFeedback];
}

- (IBAction)onButtonCleareUserData:(id)sender {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [documentsPath stringByAppendingPathComponent:@"linphone_chats.db"];
    
    if ([fileManager fileExistsAtPath:filePath]) {
        [fileManager removeItemAtPath:filePath error:nil];
    }

    [[AppDelegate sharedInstance] SignOut];
    [SettingsHandler.settingsHandler resetDefaultsWithCoreRunning];

    linphone_core_clear_call_logs([LinphoneManager getLc]);
    linphone_core_clear_all_auth_info([LinphoneManager getLc]);
    system("defaults delete com.vtcsecure.ace.mac;\
           rm -rf ~/Library/Application\\ Support/com.vtcsecure.ace.mac;\
            rm -rf ~/Library/Preferences/com.vtcsecure.ace.mac.plist;");
    [[SettingsHandler settingsHandler]  initializeUserDefaults:false settingForNoConfig:false];
    [[SettingsHandler settingsHandler] resetDefaultsWithCoreRunning];
    FXKeychain *fxKeyChainObj=[[FXKeychain alloc]init];
    [fxKeyChainObj removeObjectForKey:USER_DEFAULTS_ACCOUNT_LIST];

    if (self.parentWindowController != nil)
    {
        [self.parentWindowController closeWindow];
    }
}

@end
