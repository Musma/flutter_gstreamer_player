import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GstPlayerTextureController {
  static const MethodChannel _channel = MethodChannel(
    'flutter_gstreamer_player',
  );

  int textureId = 0;
  static int _id = 0;
  bool isPlaying = false;

  Future<int> initialize(String pipeline) async {
    GstPlayerTextureController._id = GstPlayerTextureController._id + 1;

    textureId = await _channel.invokeMethod('PlayerRegisterTexture', {
      'pipeline': pipeline,
      'playerId': GstPlayerTextureController._id,
    });

    isPlaying = true;
    return textureId;
  }

  Future<Duration> position() async {
    final int ms = await _channel.invokeMethod('position', {
      'playerId': GstPlayerTextureController._id,
    });
    return Duration(milliseconds: ms);
  }

  Future<Duration> duration() async {
    final int ms = await _channel.invokeMethod('duration', {
      'playerId': GstPlayerTextureController._id,
    });
    return Duration(milliseconds: ms);
  }

  Future<void> play() async {
    await _channel.invokeMethod('play', {
      'playerId': GstPlayerTextureController._id,
    });
    isPlaying = true;
  }

  Future<void> pause() async {
    await _channel.invokeMethod('pause', {
      'playerId': GstPlayerTextureController._id,
    });
    isPlaying = false;
  }

  Future<void> stop() async {
    await _channel.invokeMethod('stop', {
      'playerId': GstPlayerTextureController._id,
    });
    isPlaying = false;
  }

  Future<void> seekTo(Duration position) async {
    await _channel.invokeMethod('seekTo', {
      'playerId': GstPlayerTextureController._id,
      'position': position.inMilliseconds,
    });
  }

  Future<double> aspectRatio() async {
    return await _channel.invokeMethod('aspectRatio', {
      'playerId': GstPlayerTextureController._id,
    });
  }

  Future<void> dispose() async {
    await _channel.invokeMethod('dispose', {'textureId': textureId});
  }

  bool get isInitialized => textureId != 0;
}

enum GstPlayerCommand { play, pause, stop, seekTo }

class GstPlayer extends StatefulWidget {
  final String pipeline;
  final ValueNotifier<GstPlayerCommand>? controll;
  final ValueNotifier<Duration>? seekPosition;

  const GstPlayer({super.key, required this.pipeline, this.controll, this.seekPosition});

  @override
  State<GstPlayer> createState() => _GstPlayerState();
}

class _GstPlayerState extends State<GstPlayer> {
  final _controller = GstPlayerTextureController();
  late VoidCallback _commandListener;
  late VoidCallback _seekListener;

  @override
  void initState() {
    super.initState();
    initializeController();
    _commandListener = () {
      if (widget.controll == null) return;
      switch (widget.controll!.value) {
        case GstPlayerCommand.play:
          _controller.play();
          break;
        case GstPlayerCommand.pause:
          _controller.pause();
          break;
        case GstPlayerCommand.stop:
          _controller.stop();
          break;
        default:
          break;
      }
    };
    if (widget.controll != null) {
      widget.controll!.addListener(_commandListener);
    }
    _seekListener = () {
      if (widget.seekPosition == null) return;
      _controller.seekTo(widget.seekPosition!.value);
    };
    if (widget.seekPosition != null) {
      widget.seekPosition!.addListener(_seekListener);
    }
  }

  @override
  void didUpdateWidget(GstPlayer oldWidget) {
    if (widget.pipeline != oldWidget.pipeline) {
      _controller.stop();
      _controller.dispose();
      initializeController();
    }
    if (oldWidget.controll != widget.controll) {
      oldWidget.controll?.removeListener(_commandListener);
      widget.controll?.addListener(_commandListener);
    }
    if (oldWidget.seekPosition != widget.seekPosition) {
      oldWidget.seekPosition?.removeListener(_seekListener);
      widget.seekPosition?.addListener(_seekListener);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controll?.removeListener(_commandListener);
    widget.seekPosition?.removeListener(_seekListener);
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> initializeController() async {
    await _controller.initialize(widget.pipeline);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var currentPlatform = Theme.of(context).platform;

    switch (currentPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.android:
        return Container(
          child: _controller.isInitialized ? Texture(textureId: _controller.textureId) : null,
        );
      case TargetPlatform.iOS:
        String viewType = _controller.textureId.toString();
        final Map<String, dynamic> creationParams = <String, dynamic>{};
        return UiKitView(
          viewType: viewType,
          layoutDirection: TextDirection.ltr,
          creationParams: creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        throw UnsupportedError('Unsupported platform view');
    }
  }
}
