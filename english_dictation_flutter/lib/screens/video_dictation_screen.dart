import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import '../providers/dictation_provider.dart';
import 'dictation/results_screen.dart';

class VideoDictationScreen extends StatefulWidget {
  final String videoUrl;

  const VideoDictationScreen({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoDictationScreenState createState() => _VideoDictationScreenState();
}

class _VideoDictationScreenState extends State<VideoDictationScreen> {
  late VideoPlayerController _controller;
  bool _isSubtitlesHidden = true;
  final TextEditingController _textController = TextEditingController();

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
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final provider = Provider.of<DictationProvider>(context, listen: false);
    if (provider.isSubmitting) return;
    if (provider.testQueue.isEmpty) return;

    provider.isSubmitting = true;
    final ans = _textController.text.trim();
    final meta = provider.testQueue[provider.currentQIndex];
    final target = meta['word'] as String? ?? "";

    final isCorrect = ans.toLowerCase() == target.toLowerCase();

    provider.recordAnswerAndNext(
      isCorrect,
      'video_dictation',
      target,
      ans,
      !isCorrect,
      [target],
      isCorrect ? 1.0 : 0.0
    );

    provider.isSubmitting = false;
    _textController.clear();

    if (provider.userAnswers.length >= provider.testQueue.length) {
      provider.submitTest();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ResultsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<DictationProvider>(
          builder: (context, provider, child) {
            final qNum = provider.testQueue.isEmpty ? 0 : provider.currentQIndex + 1;
            final total = provider.testQueue.length;
            return Text("Video Dictation ($qNum/$total)");
          },
        ),
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
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter your dictation here...",
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submit,
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
