import 'package:flutter_driver/driver_extension.dart';
import 'package:mambatv/m0_main.dart' as probe;

/// Development-only entry point for MCP exploration; never a release target.
void main() {
  enableFlutterDriverExtension();
  probe.main();
}
