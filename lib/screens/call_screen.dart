import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/agora_service.dart';
import '../config/agora_config.dart';

class CallScreen extends StatefulWidget {
  final String channelName;
  final String? token;

  const CallScreen({
    Key? key,
    this.channelName = AgoraConfig.channelName,
    this.token,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _infoStrings = <String>[];
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request().then((status) {
      setState(() {
        _permissionGranted = status[Permission.camera]!.isGranted &&
            status[Permission.microphone]!.isGranted;
      });

      if (_permissionGranted) {
        _initAgora();
      } else {
        _addInfo('Permissions not granted');
      }
    });
  }

  void _addInfo(String info) {
    setState(() {
      _infoStrings.add(info);
    });
  }

  Future<void> _initAgora() async {
    final agoraService = Provider.of<AgoraService>(context, listen: false);
    await agoraService.initialize();
    await agoraService.joinChannel(widget.channelName, token: widget.token);
  }

  @override
  void dispose() {
    final agoraService = Provider.of<AgoraService>(context, listen: false);
    agoraService.leaveChannel();
    super.dispose();
  }

  Widget _buildLocalView(AgoraService agoraService) {
    if (agoraService.engine == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: agoraService.engine!,
        canvas: const VideoCanvas(uid: 0),
      ),
    );
  }

  Widget _buildRemoteView(AgoraService agoraService) {
    if (agoraService.remoteUid == null) {
      return const Center(
        child: Text(
          'Waiting for remote user to join...',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: agoraService.engine!,
        canvas: VideoCanvas(uid: agoraService.remoteUid),
        connection: RtcConnection(channelId: widget.channelName),
      ),
    );
  }

  Widget _buildControls(AgoraService agoraService) {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RawMaterialButton(
            onPressed: agoraService.toggleLocalAudio,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: agoraService.localAudioMuted ? Colors.red : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              agoraService.localAudioMuted ? Icons.mic_off : Icons.mic,
              color: agoraService.localAudioMuted ? Colors.white : Colors.blue,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              agoraService.leaveChannel();
              Navigator.pop(context);
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.red,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 24.0,
            ),
          ),
          RawMaterialButton(
            onPressed: agoraService.toggleLocalVideo,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: agoraService.localVideoMuted ? Colors.red : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              agoraService.localVideoMuted
                  ? Icons.videocam_off
                  : Icons.videocam,
              color: agoraService.localVideoMuted ? Colors.white : Colors.blue,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: agoraService.switchCamera,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
              Icons.switch_camera,
              color: Colors.blue,
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call Demo'),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: !_permissionGranted
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Please grant camera and microphone permissions',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _requestPermissions,
                    child: const Text('Request Permissions'),
                  ),
                ],
              ),
            )
          : Consumer<AgoraService>(
              builder: (context, agoraService, _) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: agoraService.callStatus == CallStatus.idle
                              ? const CircularProgressIndicator()
                              : _buildRemoteView(agoraService),
                        ),
                      ),
                    ),

                    Positioned(
                      right: 16,
                      top: 16,
                      width: 120,
                      height: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.white),
                        ),
                        child: _buildLocalView(agoraService),
                      ),
                    ),

                    Positioned.fill(
                      child: _buildControls(agoraService),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
