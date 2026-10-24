const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const {publicKey, privateKey} = crypto.generateKeyPairSync('rsa', {modulusLength: 1024, publicExponent: 65537});
const dartPath = process.argv[2] || (process.platform === 'win32'
  ? path.resolve(path.dirname(execFileSync('where.exe', ['dart'], {encoding: 'utf8'}).split(/\r?\n/).find(line => /dart\.bat$/i.test(line))), 'cache/dart-sdk/bin/dart.exe')
  : 'dart');
const output = execFileSync(dartPath, ['run', 'tool/m3_oaep_probe.dart'], {input: JSON.stringify(publicKey.export({format: 'jwk'})), encoding: 'utf8'});
const match = output.match(/[0-9a-f]{256}$/);
if (!match) throw new Error('Synthetic encryption did not return the expected ciphertext length');
const plaintext = crypto.privateDecrypt({key: privateKey, padding: crypto.constants.RSA_PKCS1_OAEP_PADDING, oaepHash: 'sha256'}, Buffer.from(match[0], 'hex')).toString('utf8');
if (plaintext !== 'refresh_1700000000000') throw new Error('Independent OAEP verification failed');
const report = {recordedAtUtc: new Date().toISOString(), algorithm: 'RSA-1024 OAEP SHA-256', encryptor: 'PointyCastle 4.0.0', independentDecryptor: `Node ${process.version} OpenSSL`, syntheticKeyOnly: true, passed: true};
fs.mkdirSync('docs/m3-evidence', {recursive: true});
fs.writeFileSync('docs/m3-evidence/crypto-interoperability.json', JSON.stringify(report, null, 2) + '\n');
process.stdout.write(JSON.stringify(report));
