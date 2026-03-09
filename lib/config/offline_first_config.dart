class OfflineFirstConfig {
  const OfflineFirstConfig._();

  // Launch default: fully offline POS with hidden cloud dependencies.
  static const bool offlineFirstMode = bool.fromEnvironment(
    'POS_OFFLINE',
    defaultValue: true,
  );

  // Keep cloud/backend UI hidden until infrastructure is ready.
  static const bool hideCloudFeatures = bool.fromEnvironment(
    'HIDE_CLOUD_FEATURES',
    defaultValue: true,
  );

  // Future switch for enabling cloud backend when server is ready.
  static const bool enableCloudBackend = bool.fromEnvironment(
    'ENABLE_CLOUD_BACKEND',
    defaultValue: false,
  );

  static bool get cloudFeaturesEnabled {
    return enableCloudBackend && !offlineFirstMode && !hideCloudFeatures;
  }

  static bool get tenantActivationEnabled => cloudFeaturesEnabled;
  static bool get cloudSubscriptionEnabled => cloudFeaturesEnabled;
}
