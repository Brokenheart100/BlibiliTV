import 'package:flutter_driver/driver_extension.dart';
import 'package:mambatv/main.dart' as app;

// Isolated, read-only entry point for Flutter MCP UI inspection.
void main() {
  if (!const bool.fromEnvironment('MAMBA_VALIDATION_APP') ||
      !const bool.fromEnvironment('MAMBA_READ_ONLY_VALIDATION')) {
    throw StateError('M9 UI inspection requires the isolated read-only build');
  }
  enableFlutterDriverExtension();
  app.main();
}
