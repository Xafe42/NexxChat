import 'package:flutter/material.dart';
import '../material/briks.dart';
import '../material/images.dart';
import '../gamer/gamer.dart';

const playerPanelPadding = 6;

Size getBrikSizeForScreenWidth(double width) {
  return Size.square((width - playerPanelPadding) / gamePadMatrixW);
}

class PlayerPanel extends StatelessWidget {
  final Size size;

  PlayerPanel({
    super.key,
    required double width,
  })  : assert(width != 0),
        size = Size(width, width * 2);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: Stack(
          children: const [
            _PlayerPad(),
            _GameUninitialized(),
          ],
        ),
      ),
    );
  }
}

class _PlayerPad extends StatelessWidget {
  const _PlayerPad();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: GameState.of(context).data.map((row) {
        return Row(
          children: row.map((b) {
            return b == 1
                ? const Brick.normal()
                : b == 2
                    ? const Brick.highlight()
                    : const Brick.empty();
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _GameUninitialized extends StatelessWidget {
  const _GameUninitialized();

  @override
  Widget build(BuildContext context) {
    if (GameState.of(context).states == GameStates.none) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconDragon(animate: true),
            SizedBox(height: 16),
            Text("Tetris", style: TextStyle(fontSize: 20)),
          ],
        ),
      );
    }
    return Container();
  }
}