import 'package:flutter/material.dart';

/// A drawing canvas widget that captures touch/pointer input and renders
/// white strokes on a black background (MNIST convention).
class DrawingCanvas extends StatefulWidget {
  final GlobalKey repaintKey;

  const DrawingCanvas({super.key, required this.repaintKey});

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];

  void clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  bool get hasStrokes => _strokes.isNotEmpty || _currentStroke.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: widget.repaintKey,
      child: GestureDetector(
        onPanStart: (details) {
          setState(() {
            _currentStroke = [details.localPosition];
            _strokes.add(_currentStroke);
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _currentStroke.add(details.localPosition);
          });
        },
        onPanEnd: (details) {
          _currentStroke = [];
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: _CanvasPainter(strokes: _strokes),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _CanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Black background (MNIST convention)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black,
    );

    // White strokes
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 18.0
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        // Draw a dot for single-point strokes
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 9.0, Paint()..color = Colors.white);
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        // Smooth lines using quadratic bezier
        final mid = Offset(
          (stroke[i - 1].dx + stroke[i].dx) / 2,
          (stroke[i - 1].dy + stroke[i].dy) / 2,
        );
        path.quadraticBezierTo(stroke[i - 1].dx, stroke[i - 1].dy, mid.dx, mid.dy);
      }
      path.lineTo(stroke.last.dx, stroke.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
