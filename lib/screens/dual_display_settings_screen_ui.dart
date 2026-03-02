part of 'dual_display_settings_screen.dart';

extension _DualDisplaySettingsUIBuilders
    on _DualDisplaySettingsScreenState {
  Widget buildNotSupportedView() {
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

  Widget buildSettingsView() {
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
                  buildDisplayOption(
                    'Welcome Message',
                    'Show business name when idle',
                    _showWelcomeMessage,
                    (value) {
                      setState(() => _showWelcomeMessage = value);
                      _saveSetting('dual_display_show_welcome', value);
                    },
                  ),
                  buildDisplayOption(
                    'Order Total',
                    'Show total amount during checkout',
                    _showOrderTotal,
                    (value) {
                      setState(() => _showOrderTotal = value);
                      _saveSetting('dual_display_show_total', value);
                    },
                  ),
                  buildDisplayOption(
                    'Payment Amount',
                    'Show payment amount when processing',
                    _showPaymentAmount,
                    (value) {
                      setState(() => _showPaymentAmount = value);
                      _saveSetting('dual_display_show_payment', value);
                    },
                  ),
                  buildDisplayOption(
                    'Change Amount',
                    'Show change amount after payment',
                    _showChangeAmount,
                    (value) {
                      setState(() => _showChangeAmount = value);
                      _saveSetting('dual_display_show_change', value);
                    },
                  ),
                  buildDisplayOption(
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
                            hintText:'URL or local path',
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
                                onPressed: () =>
                                    _removeSlideshowImage(index),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(height: 24),
                  buildDisplayOption(
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
                buildInfoItem(
                  'Welcome',
                  'Displays business name when POS is idle',
                ),
                buildInfoItem(
                  'Order Total',
                  'Shows the total amount during checkout process',
                ),
                buildInfoItem(
                  'Payment',
                  'Displays the payment amount being processed',
                ),
                buildInfoItem(
                  'Change',
                  'Shows the change amount to be returned to customer',
                ),
                buildInfoItem(
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

  Widget buildDisplayOption(
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

  Widget buildInfoItem(String title, String description) {
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
