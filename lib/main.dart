
import 'dart:html';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter just Audio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AudioPlayerScreen(),
    );
  }
}

class PositionData {
  const PositionData(
    this.position,
    this.bufferedPosition,
    this.duration,
  );

  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late AudioPlayer _audioPlayer;

  final _playlist = ConcatenatingAudioSource(
    children: [
      AudioSource.uri(
        Uri.parse(
          'https://traffic.megaphone.fm/OSC7872038736.mp3'
        ),
        tag: MediaItem(
          id: '1',
          title: 'Prueba 1',
          artist: 'Gwen Hassan',
          artUri: Uri.parse('https://megaphone.imgix.net/podcasts/3b0f9746-1584-11ec-86b5-7f2680654cff/image/HTPArt.jpg?ixlib=rails-4.3.1&w=450&h=450'),
          )
        ),
      AudioSource.uri(
        Uri.parse(
          'https://anchor.fm/s/5721c94/podcast/play/65884032/https%3A%2F%2Fd3ctxlq1ktw2nl.cloudfront.net%2Fstaging%2F2023-2-2%2F315785883-44100-2-8dc099d9ad08c.mp3'
        ),
        tag: MediaItem(
          id: '2',
          title: 'Escuela de nada',
          artist: 'Escuela de nada',
          artUri: Uri.parse('https://encrypted-tbn2.gstatic.com/images?q=tbn:ANd9GcSxxBIHHJWWh7AZxl9f2uVHeKPd0586GKKDz6NwnuLJlRClOY4'),
          )
        ),
      ],
    );

  Stream<PositionData> get _positionDataStream =>
    Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
      _audioPlayer.positionStream,
      _audioPlayer.bufferedPositionStream,
      _audioPlayer.durationStream,
      (position, bufferedPosition, duration) => PositionData(
        position,
        bufferedPosition,
        duration ?? Duration.zero,
      )
    );

  @override
  void initState () {
    super.initState();
    _audioPlayer = AudioPlayer();
    _init();
  }

  Future<void>_init() async {
    await _audioPlayer.setLoopMode(LoopMode.all);
    await _audioPlayer.setAudioSource(_playlist);
  }

  @override
  void dispose () {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: (){},
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        actions: [
          IconButton(
            onPressed: (){},
            icon: const Icon(Icons.more_horiz),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        height: double.infinity,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white],
          )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<SequenceState?>(
              stream: _audioPlayer.sequenceStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data;
                if (state?.sequence.isEmpty ?? true) {
                  return const SizedBox();
                }
                final metadata = state!.currentSource!.tag as MediaItem;
                return MediaMetadata(
                  imageUrl: metadata.artUri.toString(),
                  artist: metadata.artist ?? '',
                  title: metadata.title,
                );
              },
            ),
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return  ProgressBar(
                  barHeight: 8,
                   baseBarColor: Colors.grey[600],
                  bufferedBarColor: Colors.grey,
                  progressBarColor: Color.fromARGB(255, 0, 72, 255),
                  thumbColor: const Color.fromARGB(255, 0, 73, 255),
                  timeLabelTextStyle: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.w600
                  ),
                  progress: positionData?.position ?? Duration.zero,
                  buffered: positionData?.bufferedPosition ?? Duration.zero,
                  total: positionData?.duration ?? Duration.zero,
                  onSeek: _audioPlayer.seek,
                );
              },
            ),
            const SizedBox(height: 20),
            Controls(audioPlayer: _audioPlayer),
          ],
        ),
      ),
    );
  }
}

class MediaMetadata extends StatelessWidget {
  const MediaMetadata({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.artist,
    });

    final String imageUrl;

    final String title;

    final String artist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
       DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(2, 4),
              blurRadius: 4,
            )
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            height: 300,
            width: 300,
            fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20,),
        Text(
          title,
          style: const TextStyle(
            color: Color.fromARGB(255, 51, 71, 109),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          artist,
          style: const TextStyle(
            color: Color.fromARGB(255, 51, 71, 109),
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        )
    ],);
  }
}

class Controls extends StatelessWidget {
  const Controls({
    super.key,
    required this.audioPlayer,
    });

    final AudioPlayer audioPlayer;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: audioPlayer.seekToPrevious,
          iconSize: 60,
          color: Color.fromARGB(255, 51, 71, 109),
          icon: const Icon(Icons.skip_previous_rounded)
          ),
        StreamBuilder<PlayerState>(
          stream: audioPlayer.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (!(playing ?? false)) {
              return IconButton(
                onPressed: audioPlayer.play,
                iconSize: 80,
                color: Color.fromARGB(255, 51, 71, 109),
                icon: const Icon(Icons.play_arrow_rounded),
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                onPressed: audioPlayer.pause,
                iconSize: 80,
                color: Color.fromARGB(255, 51, 71, 109),
                icon: const Icon(Icons.pause_rounded),
              );
            }
            return const Icon(
              Icons.play_arrow_rounded,
              size: 80,
              color: Color.fromARGB(255, 51, 71, 109),
            );
          },
        ),
        IconButton(
          onPressed: audioPlayer.seekToNext,
          iconSize: 60,
          color: Color.fromARGB(255, 51, 71, 109),
          icon: const Icon(Icons.skip_next_rounded),
        ),
      ],
    );
  }
}