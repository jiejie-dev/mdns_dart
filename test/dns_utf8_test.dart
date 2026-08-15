import 'dart:io';

import 'package:mdns_dart/src/dns.dart';
import 'package:mdns_dart/src/zone.dart';
import 'package:test/test.dart';

void main() {
  group('UTF-8 DNS 编解码', () {
    test('服务实例标签与 TXT 字段支持中文、日文和 Emoji 往返', () {
      final message = DNSMessage.response(
        id: 1,
        answers: [
          TXTRecord(
            name: '客厅电视._felorx._tcp.local',
            strings: const ['name=客厅电视 📺', 'location=リビング', 'status=在线'],
          ),
        ],
      );

      final parsed = DNSMessage.parse(message.pack());
      final record = parsed?.answers.single as TXTRecord?;

      expect(record, isNotNull);
      expect(record!.name, '客厅电视._felorx._tcp.local');
      expect(record.strings, const [
        'name=客厅电视 📺',
        'location=リビング',
        'status=在线',
      ]);
    });

    test('DNS 标签按 UTF-8 字节数执行 63 字节限制', () {
      final overlongLabel = List.filled(22, '界').join();
      final message = DNSMessage.query(
        id: 1,
        name: '$overlongLabel.local',
        type: DNSType.PTR,
      );

      expect(message.pack, throwsArgumentError);
    });

    test('服务实例名在创建时按 UTF-8 字节数校验', () async {
      final overlongInstance = List.filled(22, '界').join();

      await expectLater(
        MDNSService.create(
          instance: overlongInstance,
          service: '_felorx._tcp',
          hostName: 'node.local.',
          port: 8080,
          ips: [InternetAddress.loopbackIPv4],
        ),
        throwsArgumentError,
      );
    });

    test('TXT 字符串按 UTF-8 字节数执行 255 字节限制', () {
      final overlongValue = List.filled(86, '界').join();
      final record = TXTRecord(
        name: 'node._felorx._tcp.local',
        strings: ['name=$overlongValue'],
      );

      expect(() => record.rdata, throwsArgumentError);
    });
  });
}
