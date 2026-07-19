import 'dart:io';

import 'package:mdns_dart/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('isUsableUnicastTarget', () {
    test('rejects unspecified IPv4 and IPv6 addresses', () {
      expect(isUsableUnicastTarget(InternetAddress.anyIPv4, 5353), isFalse);
      expect(isUsableUnicastTarget(InternetAddress.anyIPv6, 5353), isFalse);
    });

    test('rejects invalid ports and multicast destinations', () {
      final address = InternetAddress.loopbackIPv4;

      expect(isUsableUnicastTarget(address, 0), isFalse);
      expect(isUsableUnicastTarget(address, 65536), isFalse);
      expect(
        isUsableUnicastTarget(InternetAddress('224.0.0.251'), 5353),
        isFalse,
      );
      expect(isUsableUnicastTarget(InternetAddress('ff02::fb'), 5353), isFalse);
    });

    test('accepts routable IPv4 and IPv6 destinations', () {
      expect(isUsableUnicastTarget(InternetAddress.loopbackIPv4, 5353), isTrue);
      expect(isUsableUnicastTarget(InternetAddress.loopbackIPv6, 5353), isTrue);
      expect(isUsableUnicastTarget(InternetAddress('192.0.2.1'), 5353), isTrue);
    });
  });
}
