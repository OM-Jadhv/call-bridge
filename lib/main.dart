import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'signaling.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Signaling signaling = Signaling();
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  String? roomId;
  TextEditingController textEditingController = TextEditingController(text: '');
  bool _isMuted = false;

  @override
  void initState() {
    _localRenderer.initialize();
    _remoteRenderer.initialize();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    super.initState();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });

    if (signaling.localStream != null) {
      signaling.localStream!.getAudioTracks().forEach((track) {
        track.enabled = !_isMuted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(_remoteRenderer),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.width * 0.2 / 1.6,
              child: RTCVideoView(_localRenderer, mirror: true),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    signaling.openUserMedia(_localRenderer, _remoteRenderer);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.add_box_outlined, color: Colors.white),
                  onPressed: () async {
                    roomId = await signaling.createRoom(_remoteRenderer);
                    textEditingController.text = roomId!;
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: Icon(Icons.meeting_room, color: Colors.white),
                  onPressed: () {
                    signaling.joinRoom(
                      textEditingController.text.trim(),
                      _remoteRenderer,
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.call_end, color: Colors.white),
                  onPressed: () {
                    signaling.hangUp(_localRenderer);
                  },
                ),
                IconButton(
                  icon: Icon(_isMuted ? Icons.mic_off : Icons.mic, color: Colors.white),
                  onPressed: _toggleMute,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Join :  ",
                  style: TextStyle(color: Colors.white),
                ),
                Flexible(
                  child: TextFormField(
                    controller: textEditingController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      fillColor: Colors.grey[800],
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}