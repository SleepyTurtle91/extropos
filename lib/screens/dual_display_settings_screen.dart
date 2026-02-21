import 'package:extropos/services/imin_printer_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_io/io.dart';

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
          ? _buildNotSupportedView()
          : _buildSettingsView(),
    );
  }

  Widget _buildNotSupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Dual Display Not Supported',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your device does not support dual display functionality. '
              'This feature requires IMIN hardware with customer display capabilities.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dual Display',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Show information on customer display',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _dualDisplayEnabled,
                      onChanged: (value) {
                        setState(() => _dualDisplayEnabled = value);
                        _saveSetting('dual_display_enabled', value);
                      },
                    ),
                  ],
                ),
                if (_dualDisplayEnabled) ...[
                  const Divider(height: 24),
                  const Text(
                    'Display Options',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildDisplayOption(
                    'Welcome Message',
                    'Show business name when idle',
                    _showWelcomeMessage,
                    (value) {
                      setState(() => _showWelcomeMessage = value);
                      _saveSetting('dual_display_show_welcome', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Order Total',
                    'Show total amount during checkout',
                    _showOrderTotal,
                    (value) {
                      setState(() => _showOrderTotal = value);
                      _saveSetting('dual_display_show_total', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Payment Amount',
                    'Show payment amount when processing',
                    _showPaymentAmount,
                    (value) {
                      setState(() => _showPaymentAmount = value);
                      _saveSetting('dual_display_show_payment', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Change Amount',
                    'Show change amount after payment',
                    _showChangeAmount,
                    (value) {
                      setState(() => _showChangeAmount = value);
                      _saveSetting('dual_display_show_change', value);
                    },
                  ),
                  _buildDisplayOption(
                    'Thank You Message',
                    'Show thank you after transaction',
                    _showThankYouMessage,
                    (value) {
                      setState(() => _showThankYouMessage = value);
                      _saveSetting('dual_display_show_thank_you', value);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.smart_display,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'YouTube Video Display',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Show YouTube ads/videos when display is idle',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _youtubeEnabled,
                      onChanged: (value) {
                        setState(() => _youtubeEnabled = value);
                        _saveSetting('vice_youtube_enabled', value);
                      },
                    ),
                  ],
                ),
                if (_youtubeEnabled) ...[
                  const Divider(height: 24),
                  const Text(
                    'YouTube URL',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _youtubeUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://www.youtube.com/watch?v=...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () =>
                            _saveYouTubeUrl(_youtubeUrlController.text),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a YouTube video URL. The video will loop when display is idle.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Promotional Image/Video',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoImageController,
                          decoration: InputDecoration(
                            hintText: 'URL or local path',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.image),
                          ),
                          keyboardType: TextInputType.url,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () =>
                            _savePromoImageUrl(_promoImageController.text),
                        tooltip: 'Save URL',
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: _pickPromoImage,
                        tooltip: 'Pick local file',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter a URL or pick a local image/video file. This will show on the customer display when the cart has items.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.slideshow,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Slideshow',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Show product images in a slideshow when display is idle',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _slideshowEnabled,
                        onChanged: (value) {
                          setState(() => _slideshowEnabled = value);
                          _saveSetting('vice_slideshow_enabled', value);
                        },
                      ),
                    ],
                  ),
                  if (_slideshowEnabled) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Slideshow Images:'),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Image'),
                          onPressed: _addSlideshowImage,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_slideshowImages.isEmpty)
                      const Text(
                        'No images added yet. Click "Add Image" to get started.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    else
                      Column(
                        children: _slideshowImages.asMap().entries.map((entry) {
                          final index = entry.key;
                          final imagePath = entry.value;
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.image),
                              title: Text(path.basename(imagePath)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeSlideshowImage(index),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                  _buildDisplayOption(
                    'Show Product Images in Cart',
                    'Display product images alongside names and prices when showing cart',
                    _showProductImagesInCart,
                    (value) {
                      setState(() => _showProductImagesInCart = value);
                      _saveSetting('vice_show_product_images', value);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How it works',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  'Welcome',
                  'Displays business name when POS is idle',
                ),
                _buildInfoItem(
                  'Order Total',
                  'Shows the total amount during checkout process',
                ),
                _buildInfoItem(
                  'Payment',
                  'Displays the payment amount being processed',
                ),
                _buildInfoItem(
                  'Change',
                  'Shows the change amount to be returned to customer',
                ),
                _buildInfoItem(
                  'Thank You',
                  'Displays appreciation message after transaction',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
