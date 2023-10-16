import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tetris/config/app_constants.dart';
import 'package:provider/provider.dart';
import '../provider/data.dart';
import 'sub_block.dart';
import 'block.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_tetris/Ad_mob_service.dart';

enum Collision {
  landed,
  landedBlock,
  hitWall,
  hitBlock,
  none
}
int score=0;
const GAME_AREA_BORDER_WIDTH=2.0;

class Game extends StatefulWidget {
  Game({Key? key}) : super(key: key);

  @override
  State<Game> createState() => GameState();
}

class GameState extends State<Game> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _createRewardedAd();
  }
  RewardedAd? _rewardedAd;
  void _createRewardedAd()
  {
    RewardedAd.load(
        adUnitId: AdMobService.rewardAdUnitId!,
        request: const AdRequest(),
    rewardedAdLoadCallback: RewardedAdLoadCallback(
    onAdLoaded: (ad)=> setState(() => _rewardedAd=ad),
      onAdFailedToLoad: (error) => setState(()=> _rewardedAd=null),
  ),
    );
  }
  void showRewardedAd(){
    if(_rewardedAd!=null){
      _rewardedAd!.fullScreenContentCallback=FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad){
        ad.dispose();
        _createRewardedAd();
      },
    onAdFailedToShowFullScreenContent: (ad,error){
        ad.dispose();
        _createRewardedAd();
    }
    );
      _rewardedAd!.show(
        onUserEarnedReward: (ad,reward) =>setState(() =>score++),
      );
     _rewardedAd=null;
    }
  }
  // @override
  // void initState() {
  //   super.initState();
  //   initBannerAd();
  // }
  // late BannerAd bannerAd;
  // bool isAdLoaded=false;
  // var adUnit= "ca-app-pub-1661934709027267/1949976183";
  // initBannerAd(){
  //   bannerAd = BannerAd(
  //     size: AdSize.banner,
  //     adUnitId: adUnit,
  //     listener: BannerAdListener(
  //       onAdLoaded: (ad){
  //         setState(() {
  //           isAdLoaded=true;
  //         });
  //       },
  //       onAdFailedToLoad: (ad,error){
  //         ad.dispose();
  //         print(error);
  //       },
  //     ),
  //     request: const AdRequest(),
  //   );
  //   bannerAd.load();
  // }
  void showAwesomeDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.indigo,
          content: Text(
            message,
            style: TextStyle(
              fontSize: 40,
              color: Colors.white,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10.0,20,15.0,0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.white),
                ),

                onPressed: () {
                  endGame();
                  Navigator.pop(context);
                },
                child: Text(
                  "cancel",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(width: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(97.0,0,10.0,0),
              child: ElevatedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.white),
                  ),
                  onPressed: (){
                    showRewardedAd();
                    // Navigator.pop(context);
                  },
                  icon:Icon(
                      Icons.play_circle_outline,
                    color: Colors.black,
                  ),
                  label: Text(
                    'play ad',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                    ),
                  )
              ),
            )
          ],
        );
      },
    );
  }
  GlobalKey _keyGameArea = GlobalKey();
  Duration duration = const Duration(milliseconds: 300);
  double? subBlockWidth;
  Block? block;
  Timer? timer;
  // bool isPlaying = false;
  // int? score;
  bool isGameOver = false;

  BlockMovement? action;

  List<SubBlock> oldSubBlocks = [];

  Block getNewBlock() {
    int blockType = Random().nextInt(7);
    int orientationIndex = Random().nextInt(4);

    switch (blockType) {
      case 0:
        return IBlock(orientationIndex);
      case 1:
        return JBlock(orientationIndex);
      case 2:
        return LBlock(orientationIndex);
      case 3:
        return IBlock(orientationIndex);
      case 4:
        return TBlock(orientationIndex);
      case 5:
        return SBlock(orientationIndex);
      case 6:
        return ZBlock(orientationIndex);
      default:
        return IBlock(orientationIndex);
    }

  }

  void startGame() {
    Provider.of<Data>(context, listen: false).setIsPlaying(true);
    Provider.of<Data>(context, listen: false).setScore(0);

    isGameOver = false;
    oldSubBlocks = <SubBlock>[];
    RenderBox? renderBoxGame = _keyGameArea.currentContext?.findRenderObject()! as RenderBox;
    subBlockWidth = ((renderBoxGame.size.width - gameAreaBorderWidth * 2) / blocksX);
    Provider.of<Data>(context, listen: false).setNextBlock(getNewBlock());
    block = getNewBlock();
    timer = Timer.periodic(duration, onPlay);
  }

  void updateScore() {
    var combo = 1;
    Map<int, int> rows = Map();
    List<int> rowsToBeRemoved = <int>[];

    oldSubBlocks?.forEach((subBlock) {
      rows.update(subBlock!.y!, (value) => ++value, ifAbsent: () => 1);
    });

    rows.forEach((rowNum, count) {
      if (count == blocksX) {
        Provider.of<Data>(context, listen: false).addScore(combo++);

        rowsToBeRemoved.add(rowNum);
      }
    });

    if(rowsToBeRemoved.length > 0){
      removeRows(rowsToBeRemoved);
    }
  }

  void removeRows(List<int> rowsTobeRemoved) {
    rowsTobeRemoved.sort();
    rowsTobeRemoved.forEach((rowNum) {
      oldSubBlocks.removeWhere((subBlock) => subBlock.y == rowNum);
      oldSubBlocks.forEach((subBlock) {
        if(subBlock!.y! < rowNum){
          subBlock!.y! + 1;
        }
      });
    });
  }

  void onPlay(Timer timer) {
    var status = Collision.none;

    setState(() {
        if(action != null) {
          if(!checkOnEdge(action!)) {
            block!.move(action!);
          }
        }

        for(var oldSubBlock in oldSubBlocks) {
          for(var subBlock in block!.subBlocks){
            var x = block!.x! + subBlock!.x;
            var y = block!.y! + subBlock!.y;
            if(x == oldSubBlock!.x && y == oldSubBlock!.y) {
              switch(action) {
                case BlockMovement.left:
                  block!.move(BlockMovement.right);
                  break;
                case BlockMovement.right:
                  block!.move(BlockMovement.left);
                  break;
                case BlockMovement.rotateClockwise:
                  block!.move(BlockMovement.rotateCounterClockwise);
                  break;
              }
            }

          }
        }

        if(!checkAtBottom()) {
          if(!checkAboveBlock()){
            block!.move(BlockMovement.down);
          } else {
            status = Collision.landedBlock;
          }

        } else {
          status = Collision.landed;
        }

        if(status == Collision.landedBlock && block!.y! < 0){
          isGameOver = true;
          // showAwesomeDialog('Watch Ad');
          endGame();
          showRewardedAd();
        } else if(status == Collision.landed || status == Collision.landedBlock) {
          block!.subBlocks!.forEach((subBlock) {
            subBlock!.x = subBlock!.x! + block!.x!;
            subBlock!.y = subBlock!.y! + block!.y!;
            oldSubBlocks.add(subBlock);
          });

          block = Provider.of<Data>(context, listen: false).nextBlock;
          Provider.of<Data>(context, listen: false).setNextBlock(getNewBlock());
        }

        action = null;
        updateScore();
    });
  }

  bool checkAtBottom() {
    return block!.y! + block!.height == blocksY;
  }

  Positioned getPositionedSquareContainer(Color color, int x, int y) {
    return Positioned(
      left: x * subBlockWidth!,
      top:  y * subBlockWidth!,
      child: Container(
        width: subBlockWidth! - subBlockEdgeWidth,
        height: subBlockWidth! - subBlockEdgeWidth,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(3))
        ),
      ),
    );
  }

  void endGame() {
    Provider.of<Data>(context, listen: false).setIsPlaying(false);
    timer!.cancel();
  }

  Widget drawBlocks() {
    if(block == null) return SizedBox();
    List<Positioned> subBlocks = <Positioned>[];

    block!.subBlocks.forEach((subBlock) {
      subBlocks.add(getPositionedSquareContainer(subBlock.color, subBlock.x + block!.x, subBlock.y + block!.y));
    });

    oldSubBlocks?.forEach((element) {
      subBlocks.add(getPositionedSquareContainer(element.color!, element.x!, element.y!));
    });

    if(isGameOver) {
      subBlocks.add(getGameOverRect());
    }

    return Stack(children: subBlocks);
  }

  Positioned getGameOverRect() {
    return Positioned(
        child: Container(
          width: subBlockWidth! * 15,
          height: subBlockWidth! * 5,
          alignment:  Alignment.center,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: Colors.red
          ),
          child: const Text('Game Over',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
        ),
      left: subBlockWidth! * 8,
        top: subBlockWidth! * 6,
    );
  }

  bool checkAboveBlock() {
    for(var oldSubBlock in oldSubBlocks) {
      for(var subBlock in block!.subBlocks){
        var x = block!.x! + subBlock.x;
        var y = block!.y! + subBlock.y;
        if(x == oldSubBlock.x && y + 1 == oldSubBlock.y) {
          return true;
        }
      }
    }
    return false;
  }

  bool checkOnEdge(BlockMovement action) {
    return (action == BlockMovement.left && block!.x! <= 0) ||
        (action == BlockMovement.right && block!.x! + block!.width >= blocksX);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if(details.delta.dx > 0) {
            action = BlockMovement.right;
          } else {
            action = BlockMovement.left;
          }
        },
        onTap: () {
          action = BlockMovement.rotateClockwise;
        },
        child: AspectRatio(
          aspectRatio: blocksX / blocksY,
          child: Container(
            key: _keyGameArea,
            decoration: BoxDecoration(
                color: Colors.indigo.shade800,
                border: Border.all(
                    width: GAME_AREA_BORDER_WIDTH,
                    color: Colors.indigoAccent
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10))
            ),
            child: drawBlocks(),
          ),
        ),
      ),
      // bottomNavigationBar: isAdLoaded
      //     ? SizedBox(
      //   height: bannerAd.size.height.toDouble(),
      //   width: bannerAd.size.height.toDouble(),
      //   child: AdWidget(ad: bannerAd),
      // )
      //     : SizedBox(),
    );
  }
}
