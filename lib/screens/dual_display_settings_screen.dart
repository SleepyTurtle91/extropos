import 'package:extropos/services/imin_printer_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

part 'dual_display_settings_screen_ui.dart';

class DualDisplaySettingsScreen extends StatefulWidget {
  const DualDisplaySettingsScreen({super.key});

  @override
  State<DualDisplaySettingsScreen> createState() =>
      _DualDisplaySettingsScreenState();
}

class _DualDisplaySettingsScreenState extends State<DualDisplaySettingsScreen> {
  bool _dualDisplayEnabled = false;
  bool _showWelcomeMessage = true;
  bool _showOrderTotal = true;
  bool _showPaymentAmount = true;
  bool _showChangeAmount = true;
  bool _showThankYouMessage = true;
  bool _isIminSupported = false;
  bool _isLoading = true;

  // YouTube settings
  bool _youtubeEnabled = false;
  final TextEditingController _youtubeUrlController = TextEditingController();
  // Promotional image
  final TextEditingController _promoImageController = TextEditingController();
  // Slideshow settings
  bool _slideshowEnabled = false;
  List<String> _slideshowImages = [];
  bool _showProductImagesInCart = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkIminSupport();
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    _promoImageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _dualDisplayEnabled = prefs.getBool('dual_display_enabled') ?? false;
        _showWelcomeMessage =
            prefs.getBool('dual_display_show_welcome') ?? true;
        _showOrderTotal = prefs.getBool('dual_display_show_total') ?? true;
        _showPaymentAmount = prefs.getBool('dual_display_show_payment') ?? true;
        _showChangeAmount = prefs.getBool('dual_display_show_change') ?? true;
        _showThankYouMessage =
            prefs.getBool('dual_display_show_thank_you') ?? true;

        // YouTube settings
        _youtubeEnabled = prefs.getBool('vice_youtube_enabled') ?? false;
        _youtubeUrlController.text = prefs.getString('vice_youtube_url') ?? '';
        _promoImageController.text =
            prefs.getString('vice_promo_image_url') ?? '';
        // Slideshow settings
        _slideshowEnabled = prefs.getBool('vice_slideshow_enabled') ?? false;
        _slideshowImages = prefs.getStringList('vice_slideshow_images') ?? [];
        _showProductImagesInCart =
            prefs.getBool('vice_show_product_images') ?? false;
      });
    } catch (e) {
      // Use defaults
    }
  }

  Future<void> _checkIminSupport() async {
    try {
      final iminService = IminPrinterService();
      await iminService.initialize();
      final isSupported = await iminService.isDualDisplaySupported();
      setState(() {
        _isIminSupported = isSupported;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isIminSupported = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Ignore save errors
    }
  }

  Future<void> _saveYouTubeUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vice_youtube_url', url);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'YouTube URL saved. Restart vice display to apply changes.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _savePromoImageUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vice_promo_image_url', url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Promotional image URL saved.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save URL: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickPromoImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(sourcePath);
        final destPath = path.join(appDir.path, 'promo_images', fileName);

        // Create promo_images directory if it doesn't exist
        final promoDir = Directory(path.dirname(destPath));
        if (!await promoDir.exists()) {
          await promoDir.create(recursive: true);
        }

        // Copy file to app directory
        await File(sourcePath).copy(destPath);

        // Save the local path
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('vice_promo_image_url', destPath);

        setState(() {
          _promoImageController.text = destPath;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotional image saved locally.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addSlideshowImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(sourcePath);
        final destPath = path.join(appDir.path, 'slideshow_images', fileName);

        // Create slideshow_images directory if it doesn't exist
        final slideshowDir = Directory(path.dirname(destPath));
        if (!await slideshowDir.exists()) {
          await slideshowDir.create(recursive: true);
        }

        // Copy file to app directory
        await File(sourcePath).copy(destPath);

        // Add to slideshow images list
        setState(() {
          _slideshowImages.add(destPath);
        });

        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('vice_slideshow_images', _slideshowImages);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${path.basename(destPath)} to slideshow.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeSlideshowImage(int index) async {
    setState(() {
      _slideshowImages.removeAt(index);
    });

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('vice_slideshow_images', _slideshowImages);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed from slideshow.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual Display Settings'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isIminSupported
          ? buildNotSupportedView()
          : buildSettingsView(),
    );
  }
}
