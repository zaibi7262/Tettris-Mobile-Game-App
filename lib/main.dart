import 'package:flutter_tetris/provider/data.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tetris/modules/game.dart';
import 'package:flutter_tetris/modules/next_block.dart';
import 'package:flutter/services.dart';
import 'modules/score_bar.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flame_audio/flame_audio.dart';
void main() {

  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(ChangeNotifierProvider(
      create: (context) => Data(),
      child: const TetrisApp(),
  ));
}

class TetrisApp extends StatefulWidget {
  const TetrisApp({Key? key}) : super(key: key);

  @override
  State<TetrisApp> createState() => _TetrisAppState();
}

class _TetrisAppState extends State<TetrisApp> {
  GlobalKey<GameState> _keyGame = GlobalKey();
  @override
  void initState() {
    super.initState();
    initBannerAd();
    FlameAudio.loop('assets/audio1.ogg');
  }
  late BannerAd bannerAd;
  bool isAdLoaded=false;
  var adUnit= "ca-app-pub-3940256099942544/6300978111";
  initBannerAd(){
    bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: adUnit,
      listener: BannerAdListener(
        onAdLoaded: (ad){
          setState(() {
            isAdLoaded=true;
          });
        },
        onAdFailedToLoad: (ad,error){
          ad.dispose();
          print(error);
        },
      ),
      request: const AdRequest(),
    );
    bannerAd.load();
  }

  @override
  Widget build(BuildContext context) {
    final _dataProvider = Provider.of<Data>(context, listen: true);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TETRIS'),
          centerTitle: true,
          backgroundColor: Colors.indigoAccent,
        ),
        bottomNavigationBar: isAdLoaded
            ? SizedBox(
          height: bannerAd.size.height.toDouble(),
          width: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        )
            : SizedBox(),
        backgroundColor: Colors.indigo,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              const ScoreBar(),
              const SizedBox(height: 3),
              Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Flexible(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                          child: Game(key: _keyGame),
                        ),
                      ),
                      Flexible(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 10, 210, 5),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              NextBlock(),
                              SizedBox(height: 20),
                              ElevatedButton(
                                  child: Text(
                                    _dataProvider.isPlaying ? 'End'
                                    : 'Start',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade200
                                    ),
                                  ),
                                  onPressed: (){
                                    FlameAudio.bgm.play('assets/audio1.ogg',volume: 0.5);
                                    // await player.setSourceUrl('audio.mp3');
                                    //   player.play(AssetSource('audio.mp3'));
                                      _dataProvider.isPlaying
                                          ? _keyGame.currentState!.endGame()
                                          : _keyGame.currentState!.startGame();

                                  },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:  Colors.indigo.shade700,
                                )
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  )
              )
            ],
          ),
        ),
      ),
    );
  }
}


