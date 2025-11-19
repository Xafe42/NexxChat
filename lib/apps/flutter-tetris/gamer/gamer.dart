import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexxchat_firebase/apps/flutter-tetris/material/main.dart';
import '../gamer/block.dart';
import '../material/audios.dart';

/// the height of game pad
const gamePadMatrixH = 20;

/// the width of game pad
const gamePadMatrixW = 10;

/// state of [GameControl]
enum GameStates {
  none,
  paused,
  running,
  reset,
  mixing,
  clear,
  drop,
}

class Game extends StatefulWidget {
  final Widget child;

  const Game({super.key, required this.child});

  @override
  State<Game> createState() => GameControl();

  static GameControl of(BuildContext context) {
    final state = context.findAncestorStateOfType<GameControl>();
     if (state == null) {
    print("ERROR: Game.of(context) found NO GameControl");
  } else {
    print(" Game.of(context) RETURNED GameControl");
  }
  return state!;
  }
}

/// duration for show a line when reset
const restLineDuration = Duration(milliseconds: 50);

const levelMax = 6;
const levelMin = 1;

const speed = <Duration>[
  Duration(milliseconds: 800),
  Duration(milliseconds: 650),
  Duration(milliseconds: 500),
  Duration(milliseconds: 370),
  Duration(milliseconds: 250),
  Duration(milliseconds: 160),
];

class GameControl extends State<Game> with RouteAware {
  GameControl();

  BuildContext? _currentContext;

  void refreshContext(BuildContext context) {
    _currentContext = context;
  }

@override
void initState() {
  super.initState();

  print("GameControl:initState() STARTED");

  for (int i = 0; i < gamePadMatrixH; i++) {
    _data.add(List.filled(gamePadMatrixW, 0));
    _mask.add(List.filled(gamePadMatrixW, 0));
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    print(" GameControl calling _startGame()");
    _startGame();
  });
}
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }
 
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _autoFall(false);
    super.dispose();
  }

  @override
  void didPushNext() {
    
    pause();
  }

  /// the gamer data
  final List<List<int>> _data = [];

  
  final List<List<int>> _mask = [];

  /// from 1-6
  int _level = 1;

  int _points = 0;
  int _cleared = 0;

  Block? _current;
  Block _next = Block.getRandom();

  GameStates _states = GameStates.none;

  Block _getNext() {
    final next = _next;
    _next = Block.getRandom();
    return next;
  }

  SoundState get _sound => Sound.of(context);

  // =========================
  //   CONTROLS
  // =========================

  void rotate() {
    if (_states == GameStates.running) {
      final next = _current?.rotate();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        _sound.rotate();
      }
      setState(() {});
    }
  }

  void right() {
    if (_states == GameStates.none && _level < levelMax) {
      _level++;
      setState(() {});
      return;
    }

    if (_states == GameStates.running) {
      final next = _current?.right();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        _sound.move();
      }
      setState(() {});
    }
  }

  void left() {
    if (_states == GameStates.none && _level > levelMin) {
      _level--;
      setState(() {});
      return;
    }

    if (_states == GameStates.running) {
      final next = _current?.left();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        _sound.move();
      }
      setState(() {});
    }
  }

  Future<void> drop() async {
    if (_states == GameStates.running) {
      for (int i = 0; i < gamePadMatrixH; i++) {
        final fall = _current?.fall(step: i + 1);
        if (fall != null && !fall.isValidInMatrix(_data)) {
          _current = _current?.fall(step: i);
          _states = GameStates.drop;
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 100));
          await _mixCurrentIntoData(mixSound: _sound.fall);
          break;
        }
      }
      setState(() {});
    } else if (_states == GameStates.paused || _states == GameStates.none) {
      _startGame();
    }
  }

  void down({bool enableSounds = true}) {
    if (_states == GameStates.running) {
      final next = _current?.fall();
      if (next != null && next.isValidInMatrix(_data)) {
        _current = next;
        if (enableSounds) _sound.move();
      } else {
        _mixCurrentIntoData();
      }
      setState(() {});
    }
  }

  Timer? _autoFallTimer;

  void _autoFall(bool enable) {
    if (!enable) {
      _autoFallTimer?.cancel();
      _autoFallTimer = null;
      return;
    }

    _autoFallTimer?.cancel();
    _current = _current ?? _getNext();
    _autoFallTimer = Timer.periodic(speed[_level - 1], (_) {
      down(enableSounds: false);
    });
  }

  // =========================
  //   MIX / CLEAR
  // =========================

  Future<void> _mixCurrentIntoData({VoidCallback? mixSound}) async {
    if (_current == null) return;

    
    _autoFall(false);

 
    _forTable(
      (i, j) => _data[i][j] = _current?.get(j, i) ?? _data[i][j],
    );


    final clearLines = <int>[];
    for (int i = 0; i < gamePadMatrixH; i++) {
      if (_data[i].every((d) => d == 1)) {
        clearLines.add(i);
      }
    }

    if (clearLines.isNotEmpty) {
      setState(() => _states = GameStates.clear);
      _sound.clear();

      // أنيميشين اللمعان قبل المسح
      for (int count = 0; count < 5; count++) {
        for (var line in clearLines) {
          _mask[line].fillRange(0, gamePadMatrixW, count.isEven ? -1 : 1);
        }
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 100));
      }

      for (var line in clearLines) {
        _mask[line].fillRange(0, gamePadMatrixW, 0);
      }

      // نحذف الأسطر
      for (var line in clearLines) {
        _data.setRange(1, line + 1, _data);
        _data[0] = List.filled(gamePadMatrixW, 0);
      }

      _cleared += clearLines.length;
      _points += clearLines.length * _level * 5;

      // نزيد المستوى حسب عدد الأسطر
      final level = (_cleared ~/ 50) + levelMin;
      if (level <= levelMax && level > _level) {
        _level = level;
      }
    } else {
      _states = GameStates.mixing;
      mixSound?.call();

      _forTable(
        (i, j) => _mask[i][j] = _current?.get(j, i) ?? _mask[i][j],
      );
      setState(() {});
      await Future.delayed(const Duration(milliseconds: 200));
      _forTable((i, j) => _mask[i][j] = 0);
      setState(() {});
    }

    _current = null;

    
    if (_data[0].contains(1)) {
      reset();
    } else {
      _startGame();
    }
  }

  static void _forTable(dynamic Function(int row, int column) callback) {
    for (int i = 0; i < gamePadMatrixH; i++) {
      for (int j = 0; j < gamePadMatrixW; j++) {
        final b = callback(i, j);
        if (b is bool && b) return;
      }
    }
  }

  // =========================
  //   STATE CONTROL
  // =========================

  void pause() {
    if (_states == GameStates.running) {
      _states = GameStates.paused;
      _autoFall(false);
      setState(() {});
    }
  }

  void pauseOrResume() {
    if (_states == GameStates.running) {
      pause();
    } else if (_states == GameStates.paused || _states == GameStates.none) {
      _startGame();
    }
  }

  void reset() {
    if (_states == GameStates.none) {
      _startGame();
      return;
    }
    if (_states == GameStates.reset) return;

    _sound.start();
    _states = GameStates.reset;

    () async {
      int line = gamePadMatrixH;

      
      await Future.doWhile(() async {
        line--;
        for (int i = 0; i < gamePadMatrixW; i++) {
          _data[line][i] = 1;
        }
        setState(() {});
        await Future.delayed(restLineDuration);
        return line != 0;
      });

      _current = null;
      _getNext();
      _points = 0;
      _cleared = 0;

      
      await Future.doWhile(() async {
        for (int i = 0; i < gamePadMatrixW; i++) {
          _data[line][i] = 0;
        }
        setState(() {});
        line++;
        await Future.delayed(restLineDuration);
        return line != gamePadMatrixH;
      });

      setState(() {
        _states = GameStates.none;
      });

     
      _startGame();
    }();
  }

  void _startGame() {
    
    if (_states == GameStates.running && _autoFallTimer?.isActive == true) {
      return;
    }

    _states = GameStates.running;
    _autoFall(true);
    setState(() {});
  }

  // =========================
  //   BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    final mixed = <List<int>>[];

    for (var i = 0; i < gamePadMatrixH; i++) {
      mixed.add(List.filled(gamePadMatrixW, 0));
      for (var j = 0; j < gamePadMatrixW; j++) {
        int value = _current?.get(j, i) ?? _data[i][j];
        if (_mask[i][j] == -1) {
          value = 0;
        } else if (_mask[i][j] == 1) {
          value = 2;
        }
        mixed[i][j] = value;
      }
    }

    debugPrint('game states : $_states');

    return GameState(
      mixed,
      _states,
      _level,
      _sound.mute,
      _points,
      _cleared,
      _next,
      child: widget.child,
    );
  }

  void soundSwitch() {
    setState(() {
      _sound.mute = !_sound.mute;
    });
  }
}

class GameState extends InheritedWidget {
  const GameState(
    this.data,
    this.states,
    this.level,
    this.muted,
    this.points,
    this.cleared,
    this.next, {
    super.key,
    required super.child,
  });

  /// Brick data
  /// 0: empty
  /// 1: normal
  /// 2: highlight
  final List<List<int>> data;

  final GameStates states;
  final int level;
  final bool muted;
  final int points;
  final int cleared;
  final Block next;

  static GameState of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GameState>()!;
  }

  @override
  bool updateShouldNotify(GameState oldWidget) => true;
}