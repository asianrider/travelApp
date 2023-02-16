import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class IframePlayerWidget extends StatefulWidget {
  const IframePlayerWidget({Key? key, required this.youtubeVideoUrl}) : super(key: key);
  final String youtubeVideoUrl;

  @override
  _IframePlayerWidgetState createState() => _IframePlayerWidgetState();
}

class _IframePlayerWidgetState extends State<IframePlayerWidget> {
  late YoutubePlayerController _controller;

  static getYoutubeVideoIdFromUrl(String videoUrl) {
    return YoutubePlayerController.convertUrlToId(videoUrl);
  }

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
        videoId: getYoutubeVideoIdFromUrl(widget.youtubeVideoUrl),
        autoPlay: false,
        params: YoutubePlayerParams(
          // desktopMode: false,
          loop: true,
          showControls: true,
          enableCaption: false,
          showFullscreenButton: true,
          // useHybridComposition: true,
          strictRelatedVideos: true,
          showVideoAnnotations: false,
          // privacyEnhanced: true,
        ));
    // ..listen((value) {
    //   if (value.isReady && !value.hasPlayed) {
    //     _controller
    //       ..hidePauseOverlay()
    //       ..hideTopMenu();
    //   }
    // });

    _controller.setFullScreenListener((value) {
      if (value) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = YoutubePlayer(controller: _controller);
    return YoutubePlayerControllerProvider(
      controller: _controller,
      child: Container(
        child: Stack(
          children: [
            player,
            Positioned.fill(
              child: YoutubeValueBuilder(
                controller: _controller,
                builder: (context, value) {
                  return AnimatedCrossFade(
                    firstChild: SizedBox.shrink(),
                    secondChild: Container(
                      color: Colors.black,
                      child: Center(
                          child: CircularProgressIndicator(
                        color: Colors.white,
                      )),
                    ),
                    crossFadeState:
                        value.playerState == PlayerState.cued ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    duration: Duration(milliseconds: 200),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
