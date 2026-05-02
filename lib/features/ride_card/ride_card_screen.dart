import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/image_utils.dart';
import '../../data/local/local_ride_storage.dart';
import '../../data/models/ride_model.dart';
import '../../shared/widgets/rydar_button.dart';
import 'ride_card_widget.dart';

class RideCardScreen extends StatefulWidget {
  const RideCardScreen({super.key, required this.ride});

  final RideModel ride;

  @override
  State<RideCardScreen> createState() => _RideCardScreenState();
}

class _RideCardScreenState extends State<RideCardScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();
  late RideModel _ride;
  RideCardColorTheme _colorTheme = RideCardColorTheme.orangeBlack;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Card')),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Navigator.of(context).pop(_ride);
          }
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Screenshot(
                      controller: _screenshotController,
                      child: RideCardWidget(
                        ride: _ride,
                        colorTheme: _colorTheme,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _RideCardThemeSelector(
                value: _colorTheme,
                onChanged: (value) => setState(() => _colorTheme = value),
              ),
              const SizedBox(height: 18),
              RydarButton(
                label: 'Take Photo',
                icon: Icons.photo_camera_rounded,
                secondary: true,
                onPressed: _busy ? null : () => _pickPhoto(ImageSource.camera),
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Pick From Gallery',
                icon: Icons.photo_library_rounded,
                secondary: true,
                onPressed: _busy ? null : () => _pickPhoto(ImageSource.gallery),
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Save Ride Card',
                icon: Icons.save_alt_rounded,
                onPressed: _busy ? null : _generateCard,
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Save To Gallery',
                icon: Icons.photo_library_rounded,
                secondary: true,
                onPressed: _busy ? null : _saveToGallery,
              ),
              const SizedBox(height: 12),
              RydarButton(
                label: 'Share Ride Card',
                icon: Icons.ios_share_rounded,
                secondary: true,
                onPressed: _busy ? null : _shareCard,
              ),
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final allowed = await _requestPhotoPermission(source);
    if (!allowed) {
      _showMessage('Photo permission is needed for this action.');
      return;
    }

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (picked == null) {
      return;
    }
    final savedPhotoPath = await ImageUtils.copyPhotoToRydarDirectory(
      picked.path,
      _ride.id,
    );
    setState(() {
      _ride = _ride.copyWith(photoPath: savedPhotoPath);
    });
  }

  Future<void> _generateCard() async {
    setState(() => _busy = true);
    try {
      final bytes = await _captureRideCardBytes();
      if (bytes == null) {
        _showMessage('Could not create the ride card image.');
        return;
      }
      final path = await ImageUtils.saveRideCardBytes(bytes, _ride.id);
      final updatedRide = _ride.copyWith(rideCardImagePath: path);
      if (updatedRide.hasMeaningfulDistance) {
        await LocalRideStorage.instance.saveRide(updatedRide);
      }
      setState(() => _ride = updatedRide);
      _showMessage('Ride card saved locally.');
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final bytes = await _captureRideCardBytes();
      if (bytes == null) {
        _showMessage('Could not create the ride card image.');
        return;
      }

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      final allowed = hasAccess || await Gal.requestAccess(toAlbum: true);
      if (!allowed) {
        _showMessage('Gallery permission is needed to save the ride card.');
        return;
      }

      await Gal.putImageBytes(
        bytes,
        album: 'Rydar',
        name: 'rydar_card_${_ride.id}',
      );
      _showMessage('Ride card saved to gallery.');
    } on GalException catch (error) {
      _showMessage(error.type.message);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _shareCard() async {
    var path = _ride.rideCardImagePath;
    if (path == null || !File(path).existsSync()) {
      await _generateCard();
      path = _ride.rideCardImagePath;
    }
    if (path == null || !File(path).existsSync()) {
      return;
    }
    await SharePlus.instance.share(
      ShareParams(text: 'Rydar ride card', files: [XFile(path)]),
    );
  }

  Future<bool> _requestPhotoPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted || status.isLimited;
    }

    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }
    final storage = await Permission.storage.request();
    return storage.isGranted || storage.isLimited;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<Uint8List?> _captureRideCardBytes() {
    return _screenshotController.capture(pixelRatio: 2);
  }
}

class _RideCardThemeSelector extends StatelessWidget {
  const _RideCardThemeSelector({required this.value, required this.onChanged});

  final RideCardColorTheme value;
  final ValueChanged<RideCardColorTheme> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<RideCardColorTheme>(
      showSelectedIcon: false,
      segments: [
        for (final theme in RideCardColorTheme.values)
          ButtonSegment<RideCardColorTheme>(
            value: theme,
            label: Text(theme.label),
          ),
      ],
      selected: {value},
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return value.accent;
          }
          return AppColors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black;
          }
          return AppColors.text;
        }),
        side: WidgetStatePropertyAll(
          BorderSide(color: value.accent.withValues(alpha: 0.68)),
        ),
      ),
      onSelectionChanged: (selected) {
        if (selected.isNotEmpty) {
          onChanged(selected.first);
        }
      },
    );
  }
}
