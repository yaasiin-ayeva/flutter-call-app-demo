import 'package:flutter/material.dart';
import 'package:flutter_call_app_demo/screens/call_screen.dart';
import '../config/agora_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _channelController = TextEditingController(text: AgoraConfig.channelName);
  final _tokenController = TextEditingController();
  bool _validateError = false;

  @override
  void dispose() {
    _channelController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call Demo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Video Call Demo',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _channelController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Channel Name',
                errorText: _validateError ? 'Channel name is mandatory' : null,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Token (Optional)',
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _onJoin(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Start Call',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onJoin(BuildContext context) {
    setState(() {
      _channelController.text.isEmpty
          ? _validateError = true
          : _validateError = false;
    });

    if (_channelController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallScreen(
            channelName: _channelController.text,
            token: _tokenController.text.isEmpty ? null : _tokenController.text,
          ),
        ),
      );
    }
  }
}
