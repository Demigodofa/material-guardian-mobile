import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<Uint8List?> showSignatureCaptureDialog(
  BuildContext context, {
  required String title,
}) {
  return showDialog<Uint8List>(
    context: context,
    builder: (_) => _SignatureCaptureDialog(title: title),
  );
}

class _SignatureCaptureDialog extends StatefulWidget {
  const _SignatureCaptureDialog({required this.title});

  final String title;

  @override
  State<_SignatureCaptureDialog> createState() =>
      _SignatureCaptureDialogState();
}

class _SignatureCaptureDialogState extends State<_SignatureCaptureDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  final List<List<Offset>> _strokes = <List<Offset>>[];
  final GlobalKey _canvasKey = GlobalKey();

  bool get _hasSignature => _strokes.any((stroke) => stroke.isNotEmpty);

  Offset? _localOffsetFromGlobal(Offset globalPosition) {
    final renderBox =
        _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return null;
    }
    return renderBox.globalToLocal(globalPosition);
  }

  void _startStroke(Offset? offset) {
    if (offset == null) {
      return;
    }
    setState(() {
      _strokes.add(<Offset>[offset]);
    });
  }

  void _extendStroke(Offset? offset) {
    if (offset == null) {
      return;
    }
    if (_strokes.isEmpty) {
      _startStroke(offset);
      return;
    }
    setState(() {
      _strokes.last.add(offset);
    });
  }

  Future<void> _save() async {
    if (!_hasSignature) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a signature before saving.')),
      );
      return;
    }

    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null || !mounted) {
      return;
    }

    Navigator.pop(context, byteData.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Draw directly in the box below. This stays in shared Flutter so Android and Apple use the same signature flow.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (event) =>
                        _startStroke(_localOffsetFromGlobal(event.position)),
                    onPointerMove: (event) =>
                        _extendStroke(_localOffsetFromGlobal(event.position)),
                    child: CustomPaint(
                      key: _canvasKey,
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        color: Colors.black87,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _hasSignature
                        ? () {
                            setState(_strokes.clear);
                          }
                        : null,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: const Text('Clear'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Signature'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) {
        continue;
      }
      if (stroke.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke, paint);
        continue;
      }

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var index = 1; index < stroke.length; index++) {
        final point = stroke[index];
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.color != color;
  }
}
