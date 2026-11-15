import 'package:flutter/material.dart';

/// Lumulutang na AgriBot na button (parang chat head). Puwedeng i-drag at
/// kusang dumidikit sa kaliwa o kanang gilid. Pindutin para buksan ang chat.
class AgriBotBubble extends StatefulWidget {
  final VoidCallback onTap;
  const AgriBotBubble({super.key, required this.onTap});

  @override
  State<AgriBotBubble> createState() => _AgriBotBubbleState();
}

class _AgriBotBubbleState extends State<AgriBotBubble> {
  static const double _size = 64;
  static const double _margin = 8;
  Offset? _pos; // kaliwang-itaas na posisyon ng bubble
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final maxX =
          (box.maxWidth - _size - _margin).clamp(_margin, double.infinity);
      final maxY =
          (box.maxHeight - _size - _margin).clamp(_margin, double.infinity);
      // simula: kanang gilid, nasa ibabang bahagi
      final pos = _pos ?? Offset(maxX, maxY * 0.78);
      final clamped =
          Offset(pos.dx.clamp(_margin, maxX), pos.dy.clamp(_margin, maxY));

      return Stack(children: [
        AnimatedPositioned(
          duration:
              _dragging ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          left: clamped.dx,
          top: clamped.dy,
          child: GestureDetector(
            onTap: widget.onTap,
            onPanStart: (_) => setState(() => _dragging = true),
            onPanUpdate: (d) => setState(() {
              _pos = Offset((clamped.dx + d.delta.dx).clamp(_margin, maxX),
                  (clamped.dy + d.delta.dy).clamp(_margin, maxY));
            }),
            onPanEnd: (_) => setState(() {
              _dragging = false;
              final p = _pos ?? clamped;
              // dumikit sa pinakamalapit na gilid
              _pos = Offset(
                  p.dx + _size / 2 < box.maxWidth / 2 ? _margin : maxX, p.dy);
            }),
            // AgriBot logo mismo (transparent), walang bilog o puting background
            child: Image.asset('assets/images/agribot_logo.png',
                width: _size, height: _size, fit: BoxFit.contain),
          ),
        ),
      ]);
    });
  }
}
