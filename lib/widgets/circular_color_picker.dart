import 'dart:math';
import 'package:flutter/material.dart';

class CircularColorPicker extends StatefulWidget {
  final String selectedColorName;
  final Function(String name, int hue) onColorSelected;

  const CircularColorPicker({
    Key? key,
    required this.selectedColorName,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<CircularColorPicker> createState() => _CircularColorPickerState();
}

class _CircularColorPickerState extends State<CircularColorPicker> {
  final List<Triple> _colors = [
    Triple("Red", 0, const Color(0xFFFF0000)),
    Triple("Orange-Red", 10, const Color(0xFFFF2B00)),
    Triple("Orange", 21, const Color(0xFFFF5500)),
    Triple("Amber", 32, const Color(0xFFFF8200)),
    Triple("Yellow", 42, const Color(0xFFFFAB00)),
    Triple("Yellow-Green", 64, const Color(0xFFAAFF00)),
    Triple("Green", 85, const Color(0xFF55FF00)),
    Triple("Spring Green", 106, const Color(0xFF00FF55)),
    Triple("Cyan", 128, const Color(0xFF00FFAA)),
    Triple("Sky Blue", 149, const Color(0xFF0095FF)),
    Triple("Blue", 170, const Color(0xFF0055FF)),
    Triple("Indigo", 191, const Color(0xFF2B00FF)),
    Triple("Purple", 212, const Color(0xFF5500FF)),
    Triple("Magenta", 225, const Color(0xFF9500FF)),
    Triple("Hot Pink", 235, const Color(0xFFD500FF)),
    Triple("Pink", 245, const Color(0xFFFF00D5)),
    Triple("Deep Pink", 254, const Color(0xFFFF0082)),
  ];

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _colors.indexWhere((c) => c.name == widget.selectedColorName);
    if (_selectedIndex == -1) _selectedIndex = 0;
  }

  void _handlePan(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final angle = atan2(dy, dx); // -pi to pi

    // Convert to 0 to 2pi, starting from -90 degrees (top)
    double adjustedAngle = angle + pi / 2;
    if (adjustedAngle < 0) adjustedAngle += 2 * pi;

    // Calculate index
    final segmentAngle = 2 * pi / _colors.length;
    int index = (adjustedAngle / segmentAngle).round() % _colors.length;

    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      final colorData = _colors[index];
      widget.onColorSelected(colorData.name, colorData.hue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: GestureDetector(
        onPanUpdate: (details) {
          _handlePan(details.localPosition, const Size(300, 300));
        },
        onTapDown: (details) {
          _handlePan(details.localPosition, const Size(300, 300));
        },
        child: CustomPaint(
          painter: _ColorWheelPainter(
            colors: _colors,
            selectedIndex: _selectedIndex,
          ),
          child: Center(
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                border: Border.all(color: Colors.grey, width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                _colors[_selectedIndex].name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Triple {
  final String name;
  final int hue;
  final Color color;

  Triple(this.name, this.hue, this.color);
}

class _ColorWheelPainter extends CustomPainter {
  final List<Triple> colors;
  final int selectedIndex;

  _ColorWheelPainter({required this.colors, required this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final strokeWidth = 70.0;
    final wheelRadius = radius - strokeWidth / 2;

    final segmentAngle = 2 * pi / colors.length;

    for (int i = 0; i < colors.length; i++) {
      final paint = Paint()
        ..color = colors[i].color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      // Start from top (-pi/2)
      final startAngle = (i * segmentAngle) - (pi / 2) - (segmentAngle / 2);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: wheelRadius),
        startAngle,
        segmentAngle,
        false,
        paint,
      );
    }

    // Draw selection indicator
    final selectionAngle = (selectedIndex * segmentAngle) - (pi / 2);
    final indicatorDistance = wheelRadius+5; 
    final indicatorX = center.dx + indicatorDistance * cos(selectionAngle);
    final indicatorY = center.dy + indicatorDistance * sin(selectionAngle);

    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final indicatorFill = Paint()
      ..color = Colors.transparent // Or theme primary
      ..strokeWidth = 5
      ..style = PaintingStyle.fill;
    
    // Draw a ring around the selected color segment logic?
    // Actually, following the Kotlin implementation:
    // "Offset = distance * cos(rad)... Box ... border white ... border primary"
    
    canvas.drawCircle(Offset(indicatorX, indicatorY), 15, indicatorFill);
    canvas.drawCircle(Offset(indicatorX, indicatorY), 15, indicatorPaint);
    
    // Inner primary border
    final primaryPaint = Paint()
      ..color = Colors.blue // Or pass context color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
     canvas.drawCircle(Offset(indicatorX, indicatorY), 15, primaryPaint);

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
