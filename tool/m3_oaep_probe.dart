import 'dart:convert';
import 'dart:io';

import 'package:pointycastle/export.dart';
import 'package:mambatv/data/services/auth/web_auth_service.dart';

// Synthetic public key received on stdin; the independent verifier retains the
// private key in its own process. No Bilibili credentials are used here.
Future<void> main() async {
  final input = jsonDecode(await stdin.transform(utf8.decoder).join()) as Map;
  BigInt number(String text) => BigInt.parse(
    base64Url
        .decode(base64Url.normalize(text))
        .map((v) => v.toRadixString(16).padLeft(2, '0'))
        .join(),
    radix: 16,
  );
  stdout.write(
    correspondPath(
      1700000000000,
      publicKey: RSAPublicKey(
        number(input['n'] as String),
        number(input['e'] as String),
      ),
    ),
  );
}
