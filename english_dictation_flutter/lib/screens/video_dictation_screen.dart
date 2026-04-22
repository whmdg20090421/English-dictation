import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoDictationScreen extends StatefulWidget {
  final String videoUrl;

  const VideoDictationScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoDictationScreenState createState() => _VideoDictationScreenState();
}

class _VideoDictationScreenState extends State<VideoDictationScreen> {
  late VideoPlayerController _controller;
  bool _isSubtitlesHidden = true;

  @override
  void initState() {
    super.initState();
    // Initialize video player
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Dictation"),
        actions: [
          IconButton(
            icon: Icon(_isSubtitlesHidden ? Icons.subtitles_off : Icons.subtitles),
            onPressed: () {
              setState(() {
                _isSubtitlesHidden = !_isSubtitlesHidden;
              });
            },
            tooltip: "Toggle Subtitles Blur",
          ),
        ],
      ),
      body: Column(
        children: [
          if (_controller.value.isInitialized)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  
                  // 模糊覆盖层，遮挡底部 20% 以隐藏字幕
                  if (_isSubtitlesHidden)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: MediaQuery.of(context).size.width / _controller.value.aspectRatio * 0.2, // 20% of video height
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            alignment: Alignment.center,
                            child: const Text(
                              "Subtitles Hidden",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Video Controls Overlay
                  Center(
                    child: IconButton(
                      icon: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 50.0,
                      ),
                      onPressed: () {
                        setState(() {
                          _controller.value.isPlaying ? _controller.pause() : _controller.play();
                        });
                      },
                    ),
                  ),
                ],
              ),
            )
          else
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          // Dictation Input Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Listen and type what you hear:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Expanded(
                    child: TextField(
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter your dictation here...",
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      // 这里可以添加提交听写文本的逻辑
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Dictation submitted!")),
                      );
                    },
                    child: const Text("Submit"),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
