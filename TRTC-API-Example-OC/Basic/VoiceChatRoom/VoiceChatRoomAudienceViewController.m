//
//  VoiceChatRoomAudienceViewController.m
//  TRTC-API-Example-OC
//
//  Created by adams on 2021/4/14.
//  Copyright © 2021 Tencent. All rights reserved.
//

/*
 Interactive Live Audio Streaming - Listener
 The TRTC app supports interactive live audio streaming.
 This document shows how to integrate the interactive live audio streaming feature.
 1. Enter a room: [self.trtcCloud enterRoom:params appScene:TRTCAppSceneLIVE]
 2. Enable local audio: [self.trtcCloud startLocalAudio:TRTCAudioQualityMusic]
 3. Mute a remote user: [self.trtcCloud muteRemoteAudio:userId mute:sender.selected]
 4. Become speaker/listener: [self.trtcCloud switchRole: TRTCRoleAudience]
 Documentation: https://cloud.tencent.com/document/product/647/45753
 */

#import "VoiceChatRoomAudienceViewController.h"

// In the demo, the maximum number of users who can enter the room is 6.
// The maximum number of users who can enter the room can be determined according to the needs.
static const NSInteger maxRemoteUserNum = 6;

@interface VoiceChatRoomAudienceViewController () <TRTCCloudDelegate>
@property (weak, nonatomic) IBOutlet UILabel *audienceLabel;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *upMicButton;
@property (strong, nonatomic) TRTCCloud *trtcCloud;
@property (strong, nonatomic) NSMutableOrderedSet *anchorIdSet;
@end

@implementation VoiceChatRoomAudienceViewController

- (NSMutableOrderedSet *)anchorIdSet {
    if (!_anchorIdSet) {
        _anchorIdSet = [[NSMutableOrderedSet alloc] initWithCapacity:maxRemoteUserNum];
    }
    return _anchorIdSet;
}

- (TRTCCloud *)trtcCloud {
    if (!_trtcCloud) {
        _trtcCloud = [TRTCCloud sharedInstance];
    }
    return _trtcCloud;
}

- (instancetype)initWithRoomId:(UInt32)roomId userId:(NSString *)userId {
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        [self onEnterRoom:roomId userId:userId];
    }
    return  self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDefaultUIConfig];
}

- (void)setupDefaultUIConfig {
    self.audienceLabel.text = localize(@"TRTC-API-Example.VoiceChatRoomAudience.AudienceOperate");
    [self.muteButton setTitle:localize(@"TRTC-API-Example.VoiceChatRoomAnchor.mute") forState:UIControlStateNormal];
    [self.muteButton setTitle:localize(@"TRTC-API-Example.VoiceChatRoomAnchor.cancelmute") forState:UIControlStateSelected];
    [self.upMicButton setTitle:localize(@"TRTC-API-Example.VoiceChatRoomAnchor.upMic") forState:UIControlStateNormal];
    [self.upMicButton setTitle:localize(@"TRTC-API-Example.VoiceChatRoomAnchor.downMic") forState:UIControlStateSelected];
    
    self.muteButton.titleLabel.adjustsFontSizeToFitWidth = true;
    self.upMicButton.titleLabel.adjustsFontSizeToFitWidth = true;
}

- (void)onEnterRoom:(UInt32)roomId userId:(NSString *)userId {
    TRTCParams *params = [[TRTCParams alloc] init];
    params.sdkAppId = SDKAppID;
    params.roomId = roomId;
    params.userId = userId;
    params.userSig = [GenerateTestUserSig genTestUserSig:userId];
    params.role = TRTCRoleAudience;
    self.trtcCloud.delegate = self;
    [self.trtcCloud enterRoom:params appScene:TRTCAppSceneVoiceChatRoom];
}

#pragma mark - IBActions
- (IBAction)onMuteClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    NSInteger index = 0;
    for (NSString* userId in self.anchorIdSet) {
        if (index >= maxRemoteUserNum) { return; }
        [self.trtcCloud muteRemoteAudio:userId mute:sender.selected];
    }
}

- (IBAction)onUpMicClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self.trtcCloud switchRole: TRTCRoleAnchor];
        [self.trtcCloud startLocalAudio:TRTCAudioQualityMusic];
    } else {
        [self.trtcCloud switchRole: TRTCRoleAudience];
        [self.trtcCloud stopLocalAudio];
    }
}

#pragma mark - TRTCCloudDelegate
- (void)onUserAudioAvailable:(NSString *)userId available:(BOOL)available {
    NSInteger index = [self.anchorIdSet indexOfObject:userId];
    if (available) {
        if (index != NSNotFound) { return; }
        [self.anchorIdSet addObject:userId];
    } else {
        if (index) {
            [self.anchorIdSet removeObject:userId];
        }
    }
}

- (void)dealloc
{
    [self.trtcCloud stopLocalAudio];
    [self.trtcCloud exitRoom];
    [TRTCCloud destroySharedIntance];
}

@end
