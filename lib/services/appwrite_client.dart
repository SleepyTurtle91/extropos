import 'package:appwrite/appwrite.dart';
import 'package:extropos/config/environment.dart';

/// Global Appwrite client pre-configured with the project's public endpoint
/// and project id. This can be used directly in lightweight contexts.
final Client appwriteClient = Client()
    .setProject(Environment.appwriteProjectId)
    .setEndpoint(Environment.appwritePublicEndpoint);

/// Helper for a safe ping call that returns true when Appwrite responds.
Future<bool> pingAppwrite() async {
  try {
    await appwriteClient.ping();
    return true;
  } catch (_) {
    return false;
  }
}
