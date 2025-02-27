import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:q_common_utils/index.dart';

enum QPlayerState { completed, error, idle, playing, paused, preparing, prepareComplete }

class QPlayerSource {
  String? url, filePath, assetPath;

  QPlayerSource({this.url, this.filePath, this.assetPath});

  factory QPlayerSource.create(Uri uri) {
    if (CommonUtils.uriIsAssets(uri)) {
      return QPlayerSource(assetPath: uri.toString());
    }
    if (CommonUtils.uriIsFile(uri)) {
      return QPlayerSource(filePath: uri.toString());
    }
    if (CommonUtils.uriIsUrl(uri)) {
      return QPlayerSource(url: uri.toString());
    }
    throw UnimplementedError("Error URI: $uri");
  }

  AudioSource getAudioSouce(){
    if (url != null) {
      return AudioSource.uri(Uri.parse(url!));
    } else if (filePath != null) {
      return AudioSource.file(filePath!);
    } else if (assetPath != null) {
      return AudioSource.asset(assetPath!);
    }
    throw UnsupportedError("url ?? filePath ?? assetPath NULL ALL");
  }
  @override
  String toString() {
    // String type = this.url != null ? "url" : (this.filePath != null ? "file" : "asset");
    return (url ?? filePath ?? assetPath ?? "");
  }
}

class QAudioPlayer {
  late AudioPlayer _player;
  late QPlayerState _state;
  String? _currentSourcePath;
  Function(QPlayerState state)? onPlayerStateChanged;

  StreamSubscription<PlayerState>? _onPlayerStateChangedSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventStream;

  QAudioPlayer() {
    _initPlayer();
  }

  QPlayerState getState() => _state;

  AudioPlayer getPlayer() => _player;

  void _initPlayer() {
    _currentSourcePath = null;
    _player = AudioPlayer();
    _onPlayerStateChangedSubscription = _player.playerStateStream.listen((playerState) async {
      final playing = playerState.playing;
      // L.d("playerStateStream: playing: $playing, processingState ${playerState.processingState}");
      switch (playerState.processingState) {
        case ProcessingState.idle:
          setPlayerState(QPlayerState.idle);
          break;
        case ProcessingState.loading:
        case ProcessingState.buffering:
          setPlayerState(QPlayerState.preparing);
          break;
        case ProcessingState.ready:
          setPlayerState(playing ? QPlayerState.playing : QPlayerState.prepareComplete);
          break;
        case ProcessingState.completed:
          setPlayerState(QPlayerState.completed);
          // await _player.pause();
          // _player.seek(Duration.zero);
          break;
      }
      _playbackEventStream = _player.playbackEventStream.listen((event) {}, onError: (Object e, StackTrace st) {
        if (e is PlatformException) {
          L.e('Error code: ${e.code}');
          L.e('Error message: ${e.message}');
          L.e('AudioSource index: ${e.details?["index"]}');
        } else {
          L.e('An error occurred: $e');
        }
        raiseError(e);
      });
    });

    _state = QPlayerState.idle;
  }

  _releaseAndInitAgain() async {
    await dispose();
    _initPlayer();
  }

  setPlayerState(QPlayerState s) {
    // L.d("setPlayerState: $s");
    if ((_state == QPlayerState.error &&
            s == QPlayerState.idle) || // Đang error, mà nhận được thiết lập stop ==> bỏ qua, ko thay đổi state
        (_state == QPlayerState.playing && s == QPlayerState.prepareComplete)) {
      return;
    }

    if (_state != s) {
      L.d("change state: $s");
      _state = s;
      onPlayerStateChanged?.call(_state);
    }
  }
  QPlayerSource? currentSource;
  Future<Duration?> setSource(QPlayerSource qPlayerSource, {bool preload = true}) async {
    currentSource = qPlayerSource;
    if (_currentSourcePath != null && qPlayerSource.toString() == _currentSourcePath) {
      if (_state == QPlayerState.error || _state == QPlayerState.idle) {
        await _releaseAndInitAgain();
      } else {
        L.d("seekto 0 and Play again");
        await _player.seek(Duration.zero);
        return null;
      }
    }
    try {
      L.d("setSource: ${qPlayerSource.toString()}");
      setPlayerState(QPlayerState.idle);
      _currentSourcePath = qPlayerSource.toString();

      if (qPlayerSource.url != null) {
        return _player.setUrl(qPlayerSource.url!, preload: preload);
      } else if (qPlayerSource.filePath != null) {
        return _player.setFilePath(qPlayerSource.filePath!, preload: preload);
      } else if (qPlayerSource.assetPath != null) {
        return _player.setAsset(qPlayerSource.assetPath!, preload: preload);
      }
    } catch (err) {
      raiseError(err);
    }
    return null;
  }

  raiseError(Object err) {
    L.e("Player Error LOG: $err");
    setPlayerState(QPlayerState.error);
  }

  Future<void> play() async {
    try {
      await _player.play();
    } on Exception catch (e) {
      raiseError(e);
    }
  }

  playWithSource(QPlayerSource qPlayerSource) async {
    await setSource(qPlayerSource);
    await play();
  }

  // Future<void> play(AudioSource source) async {
  //   // if (_isSameSource(source, _currentSource)) {
  //   //   if (_player.state == PlayerState.completed || _player.state == PlayerState.paused) {
  //   //     L.d("Play again");
  //   //     _player.seek(Duration.zero);
  //   //     _player.resume();
  //   //     return;
  //   //   }
  //   //   if (_player.state == PlayerState.playing) {
  //   //     return;
  //   //   }
  //   // }
  //   if (_currentSource != null && source != _currentSource) {
  //     _releaseAndInitAgain();
  //   }
  //   _currentSource = source;
  //   try {
  //     setPlayerState(QPlayerState.preparing);
  //     await setSource(source);
  //     await _player.play();
  //   } catch (err) {
  //     raiseError(err);
  //   }
  // }

  Future<void> pause() {
    return _player.pause();
  }

  Future<void> stop() {
    return _player.stop();
  }

  Future<void> resume() {
    return _player.play();
  }

  Future<void> seek(Duration position) {
    return _player.seek(position);
  }

  Future<void> dispose() {
    setPlayerState(QPlayerState.idle);
    _onPlayerStateChangedSubscription?.cancel();
    _playbackEventStream?.cancel();
    return _player.dispose();
  }

  Future<void> release() {
    return dispose();
  }
}
