import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import '../config/agora_config.dart';

enum CallStatus { idle, connecting, connected, disconnected }

class AgoraService extends ChangeNotifier {
  int? _localUid;
  int? _remoteUid;
  RtcEngine? _engine;
  CallStatus _callStatus = CallStatus.idle;
  bool _localAudioMuted = false;
  bool _localVideoMuted = false;

  // Getters
  int? get localUid => _localUid;
  int? get remoteUid => _remoteUid;
  RtcEngine? get engine => _engine;
  CallStatus get callStatus => _callStatus;
  bool get localAudioMuted => _localAudioMuted;
  bool get localVideoMuted => _localVideoMuted;

  // Initialize Agora RTC Engine
  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: AgoraConfig.appId,
    ));

    // Register event handlers
    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        _localUid = connection.localUid;
        _callStatus = CallStatus.connecting;
        notifyListeners();
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        _remoteUid = remoteUid;
        _callStatus = CallStatus.connected;
        notifyListeners();
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        _remoteUid = null;
        _callStatus = CallStatus.disconnected;
        notifyListeners();
      },
      onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        _remoteUid = null;
        _callStatus = CallStatus.idle;
        notifyListeners();
      },
    ));

    // Enable video
    await _engine!.enableVideo();
    await _engine!.startPreview();
  }

  // Join a channel
  Future<void> joinChannel(String channelName, {String? token}) async {
    if (_engine == null) await initialize();
    
    // Set video encoding config
    await _engine!.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
        frameRate: 15,
        bitrate: 800,
      ),
    );

    // Join the channel
    await _engine!.joinChannel(
      token: token ?? AgoraConfig.token,
      channelId: channelName,
      uid: 0, // 0 means let Agora assign a uid
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  // Leave the channel
  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      _remoteUid = null;
      _callStatus = CallStatus.idle;
      notifyListeners();
    }
  }

  // Switch camera
  Future<void> switchCamera() async {
    if (_engine != null) {
      await _engine!.switchCamera();
      notifyListeners();
    }
  }

  // Toggle local audio
  Future<void> toggleLocalAudio() async {
    if (_engine != null) {
      _localAudioMuted = !_localAudioMuted;
      await _engine!.muteLocalAudioStream(_localAudioMuted);
      notifyListeners();
    }
  }

  // Toggle local video
  Future<void> toggleLocalVideo() async {
    if (_engine != null) {
      _localVideoMuted = !_localVideoMuted;
      await _engine!.muteLocalVideoStream(_localVideoMuted);
      notifyListeners();
    }
  }

  // Dispose
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }
}