import 'package:encrypt/encrypt.dart' as ec;

import 'ecs.dart';

final key = ec.Key.fromUtf8(ecs);
final iv = ec.IV.fromLength(16);
final encrypter = ec.Encrypter(ec.AES(key));

ec.Encrypted encrypt(String input) {
  return encrypter.encrypt(input, iv: iv);
}

String decrypt(String input) {
  return encrypter.decrypt16(input, iv: iv);
}
