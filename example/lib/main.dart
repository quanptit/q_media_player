import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_common_utils/index.dart';
import 'package:q_media_player/q_media_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var url = "https://f002.backblazeb2.com/file/learnlanguage/data/sound/win.mp3";
  QAudioPlayer player = QAudioPlayer();
  QAudioPlayer player1 = QAudioPlayer();
  QAudioPlayer playerBtnTap = QAudioPlayer();

  @override
  void initState() {
    super.initState();
    playerBtnTap.setSource(QPlayerSource(assetPath: "assets/sfx/click_correct.mp3"));
    // playerBtnTap.getPlayer().load();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(url),
            FilledButton(onPressed: () async {
              playerBtnTap.setSource(QPlayerSource(assetPath: "assets/sfx/click_correct.mp3"));
              playerBtnTap.play();
            }, child: const Text('Play Btn Tap Asset')),
            FilledButton(
                onPressed: () async {
                  L.d("Play Click");
                  await player.setSource(QPlayerSource(url: url));
                  await player.play();
                },
                child: const Text('Play Win audio')),
            FilledButton(
                onPressed: () {
                  var url1 = "https://f002.backblazeb2.com/file/learnlanguage/data/sound/gameover.mp3";
                  player1.setSource(QPlayerSource(url: url));
                  player1.play();
                },
                child: const Text('Play GameOver audio')),
            FilledButton(
                onPressed: () {
                  RouteUtils.push(
                      context: context,
                      screen: Column(
                        children: [Text("New Screen")],
                      ));
                },
                child: const Text('New Screen')),
          ],
        ),
      ),
    );
  }
}
