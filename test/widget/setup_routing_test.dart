import 'package:extropos/main.dart' show ExtroPOSApp;
import 'package:extropos/services/config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Setup routing', () {
    testWidgets('shows SetupScreen when first-run (isSetupDone = false)', (
      tester,
    ) async {
      // Start with pref saying setup not done
      SharedPreferences.setMockInitialValues({
        'app_is_setup_done': false,
        // Prevent tutorial timer in ModeSelectionScreen during tests
        'has_seen_tutorial': true,
      });

      await ConfigService.instance.init();

      await tester.pumpWidget(const ExtroPOSApp());
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Welcome to ExtroPOS'), findsOneWidget);
      expect(find.textContaining('setting up your business profile'), findsOneWidget);
    });

    testWidgets('shows home when setup already done (isSetupDone = true)', (
      tester,
    ) async {
      // Mark setup as completed in prefs
      SharedPreferences.setMockInitialValues({
        'app_is_setup_done': true,
        // Prevent tutorial timer in ModeSelectionScreen during tests
        'has_seen_tutorial': true,
      });

      await ConfigService.instance.init();

      await tester.pumpWidget(const ExtroPOSApp());
      await tester.pump(const Duration(milliseconds: 500));

      // When setup is done the app now presents a lock screen first
      expect(find.textContaining('Enter your PIN to unlock'), findsOneWidget);
    });
  });
}
