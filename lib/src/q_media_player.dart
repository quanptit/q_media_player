import 'dart:async';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:q_common_utils/l.dart';

enum QPlayerState { completed, error, idle, playing, paused, preparing, prepareComplete }

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

  void _initPlayer() {
    _currentSourcePath = null;
    _player = AudioPlayer();
    _onPlayerStateChangedSubscription = _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
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

  void _releaseAndInitAgain() {
    dispose();
    _initPlayer();
  }

  setPlayerState(QPlayerState s) {
    L.d("setPlayerState: " + s.toString());
    if ((_state == QPlayerState.error && s == QPlayerState.idle) || // Đang error, mà nhận được thiết lập stop ==> bỏ qua, ko thay đổi state
        (_state == QPlayerState.playing && s == QPlayerState.prepareComplete)) {
      return;
    }

    if (_state != s) {
      L.d("change state: " + s.toString());
      _state = s;
      onPlayerStateChanged?.call(_state);
    }
  }

  Future<Duration?> setSource({String? url, String? filePath, String? assetPath, bool preload = true}) async {
    if (_currentSourcePath != null && (url == _currentSourcePath || filePath == _currentSourcePath || assetPath == _currentSourcePath)) {
      if (_state == QPlayerState.error || _state == QPlayerState.idle) {
        _releaseAndInitAgain();
      } else {
        L.d("seekto 0 and Play again");
        _player.seek(Duration.zero);
        return null;
      }
    }
    try {
      L.d("setSource: " + (url ?? filePath ?? assetPath ?? ""));
      setPlayerState(QPlayerState.idle);
      if (url != null) {
        _currentSourcePath = url;
        return _player.setUrl(url, preload: preload);
      } else if (filePath != null) {
        _currentSourcePath = filePath;
        return _player.setFilePath(filePath, preload: preload);
      } else if (assetPath != null) {
        _currentSourcePath = assetPath;
        return _player.setAsset(assetPath, preload: preload);
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

  Future<void> playUrl(String url) async {
    try {
      await setSource(url: url);
      await _player.play();
    } on Exception catch (e) {
      raiseError(e);
    }
  }

  // Future<void> play(AudioSource source) async {
  //   //TODO
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
