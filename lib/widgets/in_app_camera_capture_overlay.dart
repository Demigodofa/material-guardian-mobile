import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CapturedMediaItem {
  const CapturedMediaItem({required this.tempPath, required this.index});

  final String tempPath;
  final int index;
}

class InAppCameraCaptureOverlay extends StatefulWidget {
  const InAppCameraCaptureOverlay({
    required this.title,
    required this.maxCount,
    required this.currentCount,
    required this.acceptLabel,
    super.key,
    this.replaceIndex,
  });

  final String title;
  final int maxCount;
  final int currentCount;
  final int? replaceIndex;
  final String acceptLabel;

  @override
  State<InAppCameraCaptureOverlay> createState() =>
      _InAppCameraCaptureOverlayState();
}

class _InAppCameraCaptureOverlayState extends State<InAppCameraCaptureOverlay> {
  CameraController? _controller;
  String? _errorMessage;
  bool _initializing = true;
  bool _capturing = false;
  CapturedMediaItem? _pendingCapture;
  final List<CapturedMediaItem> _acceptedCaptures = <CapturedMediaItem>[];

  bool get _isReplacement => widget.replaceIndex != null;

  int get _activeIndex =>
      widget.replaceIndex ??
      (widget.currentCount + _acceptedCaptures.length + 1);

  int get _displayCount => _isReplacement ? _activeIndex : _activeIndex;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _deletePendingCapture();
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException(
          'no-camera',
          'No camera was found on this device.',
        );
      }
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _errorMessage = null;
        _initializing = false;
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _cameraErrorMessage(error);
        _initializing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'The camera could not be started on this device.';
        _initializing = false;
      });
    }
  }

  Future<void> _handleShutter() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() {
      _capturing = true;
      _errorMessage = null;
    });
    try {
      final capture = await controller.takePicture();
      if (!mounted) {
        return;
      }
      setState(() {
        _pendingCapture = CapturedMediaItem(
          tempPath: capture.path,
          index: _activeIndex,
        );
      });
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = _cameraErrorMessage(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _capturing = false;
        });
      }
    }
  }

  Future<void> _handleAccept() async {
    final pendingCapture = _pendingCapture;
    if (pendingCapture == null) {
      return;
    }
    _acceptedCaptures.add(pendingCapture);
    final reachedLimit =
        _isReplacement ||
        widget.currentCount + _acceptedCaptures.length >= widget.maxCount;
    if (reachedLimit) {
      _closeOverlay();
      return;
    }
    setState(() {
      _pendingCapture = null;
    });
  }

  Future<void> _handleRetake() async {
    await _deletePendingCapture();
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingCapture = null;
      _errorMessage = null;
    });
  }

  Future<void> _deletePendingCapture() async {
    final pendingCapture = _pendingCapture;
    if (pendingCapture == null) {
      return;
    }
    _pendingCapture = null;
    final file = File(pendingCapture.tempPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  void _closeOverlay() {
    Navigator.of(context).pop<List<CapturedMediaItem>>(
      List<CapturedMediaItem>.unmodifiable(_acceptedCaptures),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        _closeOverlay();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _buildBody(theme)),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: _closeOverlay,
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              widget.title,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$_displayCount / ${widget.maxCount}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: _buildControls(theme),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Camera unavailable',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _initializing = true;
                    _errorMessage = null;
                  });
                  _initializeCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final pendingCapture = _pendingCapture;
    if (pendingCapture != null) {
      return Center(
        child: Image.file(
          File(pendingCapture.tempPath),
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text(
                'Preview unavailable',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
              ),
            );
          },
        ),
      );
    }

    final controller = _controller;
    if (_initializing ||
        controller == null ||
        !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    final pendingCapture = _pendingCapture;
    if (pendingCapture != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _handleRetake,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Retake'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _handleAccept,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(widget.acceptLabel),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: IconButton(
            onPressed: _capturing ? null : _handleShutter,
            iconSize: 48,
            color: Colors.white,
            icon: _capturing
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  )
                : const Icon(Icons.camera_alt_rounded),
          ),
        ),
      ],
    );
  }
}

String _cameraErrorMessage(CameraException error) {
  switch (error.code) {
    case 'CameraAccessDenied':
    case 'CameraAccessDeniedWithoutPrompt':
      return 'Camera permission was denied for Material Guardian.';
    case 'CameraAccessRestricted':
      return 'Camera access is restricted on this device.';
    case 'AudioAccessDenied':
    case 'AudioAccessDeniedWithoutPrompt':
      return 'Audio permission is not available, but camera capture should not require it.';
    default:
      return error.description?.trim().isNotEmpty == true
          ? error.description!.trim()
          : 'The camera could not be started on this device.';
  }
}
