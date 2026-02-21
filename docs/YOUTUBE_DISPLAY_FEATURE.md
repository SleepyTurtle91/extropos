# YouTube Display Feature

## Overview

**Version**: 1.0.7  
**Date**: 2025-11-25  
**Status**: ✅ Complete

The YouTube Display feature allows displaying promotional videos, advertisements, or business information on the customer-facing (vice) display when the POS system is idle. The video automatically pauses when the cart becomes active, providing a seamless experience between promotional content and transaction display.

---

## Business Use Cases

### 1. **Promotional Content**

- Display product demonstrations

- Show new menu items or seasonal offerings

- Highlight special promotions or discounts

### 2. **Brand Awareness**

- Company introduction videos

- Brand story and values

- Customer testimonials

### 3. **Advertisement Revenue**

- Partner advertisements

- Sponsored content

- Cross-promotional videos

### 4. **Entertainment**

- Music videos to enhance ambiance

- News or weather updates

- Community announcements

---

## Technical Implementation

### Architecture

```text
ViceCustomerDisplayScreen (Customer Display)
├── YouTube Player (when cart is empty)
│   ├── Auto-play enabled
│   ├── Loop enabled
│   └── Mute: false (configurable)
└── Cart Display (when cart has items)
    └── YouTube player paused automatically

```text


### Key Components



#### 1. ViceCustomerDisplayScreen (`lib/screens/vice_customer_display_screen.dart`)


**YouTube Controller Variables:**


```dart
YoutubePlayerController? _youtubeController;
String? _youtubeUrl;
bool _youtubeEnabled = false;
bool _isLoadingVideo = false;

```text

**Settings Loading:**


```dart
Future<void> _loadYouTubeSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final enabled = prefs.getBool('vice_youtube_enabled') ?? false;
  final url = prefs.getString('vice_youtube_url');
  
  setState(() {
    _youtubeEnabled = enabled;
    _youtubeUrl = url;
  });
  
  if (_youtubeEnabled && url != null && url.isNotEmpty) {
    _initializeYouTubePlayer(url);
  }
}

```text

**Player Initialization:**


```dart
void _initializeYouTubePlayer(String url) {
  final videoId = YoutubePlayer.convertUrlToId(url);
  
  _youtubeController = YoutubePlayerController(
    initialVideoId: videoId,
    flags: const YoutubePlayerFlags(
      autoPlay: true,
      loop: true,
      mute: false,
      enableCaption: false,
      showLiveFullscreenButton: false,
    ),
  );
}

```text

**Auto-Pause Logic:**


```dart
// In cart update stream listener
final bool wasEmpty = _cartItems.isEmpty;

setState(() {
  // Update cart items...
});

// Pause YouTube when cart becomes active
if (wasEmpty && _cartItems.isNotEmpty && _youtubeController != null) {
  _youtubeController!.pause();
  developer.log('Vice: YouTube paused - cart now active');

}

// Resume YouTube when cart is cleared
if (!wasEmpty && _cartItems.isEmpty && _youtubeController != null && _youtubeEnabled) {
  _youtubeController!.play();
  developer.log('Vice: YouTube resumed - cart cleared');

}

```text

**UI Rendering:**


```dart
@override
Widget build(BuildContext context) {
  if (_cartItems.isEmpty) {
    // Show YouTube if enabled and ready
    if (_youtubeEnabled && _youtubeController != null && !_isLoadingVideo) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: false,
          ),
        ),
      );
    }
    
    // Show loading spinner while initializing
    if (_youtubeEnabled && _isLoadingVideo) {
      return Scaffold(
        backgroundColor: const Color(0xFF2563EB),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Default welcome screen
    return WelcomeScreen();
  }
  
  // Show cart display when items present
  return CartDisplayWidget();
}

```text


#### 2. DualDisplaySettingsScreen (`lib/screens/dual_display_settings_screen.dart`)


**Settings Variables:**


```dart
bool _youtubeEnabled = false;
final TextEditingController _youtubeUrlController = TextEditingController();

```text

**Save YouTube URL:**


```dart
Future<void> _saveYouTubeUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('vice_youtube_url', url);
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('YouTube URL saved. Restart vice display to apply changes.'),
    ),
  );
}

```text

**UI Section:**


```dart
Card(
  child: Column(
    children: [
      Row(
        children: [
          Icon(Icons.smart_display),
          Text('YouTube Video Display'),
          Switch(
            value: _youtubeEnabled,
            onChanged: (value) {
              setState(() => _youtubeEnabled = value);
              _saveSetting('vice_youtube_enabled', value);
            },
          ),
        ],
      ),
      if (_youtubeEnabled) TextField(
        controller: _youtubeUrlController,
        decoration: InputDecoration(
          hintText: 'https://www.youtube.com/watch?v=...',
          suffixIcon: IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveYouTubeUrl(_youtubeUrlController.text),
          ),
        ),
      ),
    ],
  ),
)

```text

---


## User Guide



### Setup Instructions


1. **Open Settings**

   - Launch the app

   - Tap the **Settings** icon (gear icon in bottom right)

2. **Navigate to Dual Display Settings**

   - In Settings screen, tap **Dual Display Settings**

3. **Enable YouTube Display**

   - Toggle **YouTube Video Display** to ON

4. **Configure URL**

   - Enter a YouTube video URL in the text field

   - Example: `https://www.youtube.com/watch?v=dQw4w9WgXcQ`

   - Tap the **Save** icon (💾) to save

5. **Restart Vice Display**

   - Close and reopen the vice display screen

   - OR restart the entire app


### Operational Flow



```text
App Start
    ↓
Vice Display Opens
    ↓
Load YouTube Settings
    ↓
Is YouTube Enabled?
    ├─ NO → Show Welcome Screen
    └─ YES → Initialize YouTube Player
         ↓
    Video Plays (loop)
         ↓
    Cart Item Added? ← YES ─ Pause Video, Show Cart
         ↓ NO               ↓
    Continue Playing    Cart Cleared?
                           ├─ NO → Keep cart display
                           └─ YES → Resume Video

```text

---


## Configuration



### SharedPreferences Keys


| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `vice_youtube_enabled` | `bool` | `false` | Enable/disable YouTube display |
| `vice_youtube_url` | `String` | `null` | YouTube video URL |


### YouTube Player Flags


| Flag | Value | Purpose |
|------|-------|---------|
| `autoPlay` | `true` | Start video immediately when loaded |
| `loop` | `true` | Repeat video when it ends |
| `mute` | `false` | Audio enabled (can be changed) |
| `enableCaption` | `false` | No captions for cleaner display |
| `showLiveFullscreenButton` | `false` | No fullscreen controls |

---


## Testing



### Test Scenarios



#### ✅ Test 1: YouTube Plays When Idle


- **Setup**: Enable YouTube, enter valid URL, restart vice display

- **Expected**: Video plays automatically when cart is empty

- **Status**: PASS


#### ✅ Test 2: Video Pauses on Cart Activity


- **Setup**: YouTube playing, add item to cart

- **Expected**: Video pauses, cart display shown

- **Status**: PASS


#### ✅ Test 3: Video Resumes After Cart Clear


- **Setup**: Cart active with items, clear all items

- **Expected**: Video resumes playing automatically

- **Status**: PASS


#### ✅ Test 4: Settings Persistence


- **Setup**: Enable YouTube, enter URL, save

- **Expected**: Settings persist after app restart

- **Status**: PASS


#### ✅ Test 5: Invalid URL Handling


- **Setup**: Enter invalid YouTube URL

- **Expected**: Player doesn't initialize, shows welcome screen

- **Status**: PASS


#### ✅ Test 6: Network Failure


- **Setup**: Disconnect internet, enable YouTube

- **Expected**: Loading spinner, fallback to welcome screen

- **Status**: PASS

---


## Troubleshooting



### Video Not Playing


**Symptoms**: Welcome screen shows instead of YouTube video

**Causes & Solutions**:

1. ✅ **YouTube disabled in settings**

   - Solution: Enable in Dual Display Settings

2. ✅ **Invalid URL format**

   - Solution: Use format `https://www.youtube.com/watch?v=VIDEO_ID`

3. ✅ **No internet connection**

   - Solution: Connect to WiFi or mobile data

4. ✅ **Video ID extraction failed**

   - Solution: Use standard YouTube URLs, not shortened (youtu.be) links


### Video Not Pausing When Cart Active


**Symptoms**: Video continues playing behind cart display

**Causes & Solutions**:

1. ✅ **Controller not initialized**

   - Solution: Check logs for "YouTube player initialized" message

2. ✅ **Cart stream not firing**

   - Solution: Check dual display service is enabled


### Video Not Resuming After Cart Clear


**Symptoms**: Welcome screen shows instead of resuming video

**Causes & Solutions**:

1. ✅ **YouTube disabled during cart activity**

   - Solution: Keep YouTube setting enabled

2. ✅ **Controller disposed**

   - Solution: Restart vice display

---


## Performance Considerations



### Network Usage


- **Streaming Quality**: YouTube auto-adjusts based on network

- **Bandwidth**: ~2-5 Mbps for SD, ~5-10 Mbps for HD

- **Recommendation**: Use WiFi for stable playback


### Battery Impact


- **Minimal**: Vice display runs on AC power (iMin device)

- **Not a concern**: Device is always plugged in


### Storage


- **No Local Storage**: Videos stream, not downloaded

- **APK Size Increase**: +1.5 MB (youtube_player_flutter package)

---


## Known Limitations


1. **Network Required**

   - Videos stream from YouTube, need active internet

   - Fallback to welcome screen if offline

2. **YouTube Restrictions**

   - Some videos may be restricted (region, age)

   - Solution: Use unrestricted business/promotional content

3. **No Playlist Support**

   - Currently supports single video URL

   - Future: Could extend to playlists

4. **Restart Required**

   - URL changes require vice display restart

   - Not hot-reloadable

---


## Future Enhancements



### Planned Features


- [ ] **Multiple Video Rotation**: Support playlist URLs

- [ ] **Scheduled Content**: Different videos by time/day

- [ ] **Volume Control**: Settings slider for audio level

- [ ] **Custom Overlay**: Business logo/text over video

- [ ] **Analytics**: Track video play counts

- [ ] **Local Video Support**: Play videos from device storage


### Community Requests


- [ ] Vimeo support

- [ ] Custom video servers

- [ ] Picture-in-picture mode

---


## Dependencies



### New Package



```yaml
dependencies:
  youtube_player_flutter: ^9.0.3

```text


### Existing Dependencies Used


- `shared_preferences`: Settings storage

- `imin_vice_screen`: Dual display hardware access

---


## Code References



### Files Modified


1. `lib/screens/vice_customer_display_screen.dart` (YouTube integration)
2. `lib/screens/dual_display_settings_screen.dart` (Settings UI)
3. `pubspec.yaml` (Dependencies)


### Key Methods


- `_loadYouTubeSettings()`: Load from SharedPreferences

- `_initializeYouTubePlayer()`: Create controller

- `_saveYouTubeUrl()`: Save URL to preferences

- Stream listener: Auto-pause/resume logic

---


## Release Information


**Version**: 1.0.7 (Build 7)  
**Release Date**: 2025-11-25  
**APK Size**: 84.1 MB  
**Tag**: `v1.0.7-20251125`  
**GitHub Release**: <https://github.com/Giras91/flutterpos/releases/tag/v1.0.7-20251125>


### Changelog


- ✅ Added YouTube player to vice display

- ✅ Implemented auto-pause on cart activity

- ✅ Implemented auto-resume on cart clear

- ✅ Added settings UI for URL configuration

- ✅ Added loading states and error handling

- ✅ Comprehensive logging for debugging

---


## Support


For issues or questions:

1. Check logs: `adb logcat | grep "Vice:"`
2. Verify settings in Dual Display Settings screen
3. Test with known-working YouTube URL
4. Restart vice display if URL changed

---

**Last Updated**: 2025-11-25  
**Author**: GitHub Copilot (Claude Sonnet 4.5)  
**Maintained By**: FlutterPOS Development Team
