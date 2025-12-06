import 'dart:io';
import 'package:mdns_dart/mdns_dart.dart';

/// Simple mDNS client example
void main() async {
  // Check for debug flag from environment or args
  final debug =
      Platform.environment['MDNS_DEBUG'] == '1' ||
      Platform.executableArguments.contains('--debug');

  print('Discovering mDNS services...');
  print('Platform: ${Platform.operatingSystem}');

  // List network interfaces for debugging
  final interfaces = await NetworkInterface.list();
  print('Network interfaces:');
  for (final iface in interfaces) {
    for (final addr in iface.addresses) {
      if (!addr.isLoopback) {
        print('  ${iface.name}: ${addr.address} (${addr.type.name})');
      }
    }
  }
  print('');

  final results = await MDNSClient.discover(
    '_puupee._tcp',
    timeout: Duration(seconds: 5),
    reuseAddress: true,
    reusePort: !Platform.isWindows, // Windows doesn't support SO_REUSEPORT
    joinMulticastOnAllInterfaces: true, // Enable cross-platform discovery
    logger: debug ? (msg) => print(msg) : null,
  );

  if (results.isEmpty) {
    print('No services found');
    print('\nTroubleshooting tips:');
    print('  1. Ensure the server is running on the same network');
    print('  2. Check firewall settings (allow UDP port 5353)');
    print('  3. Run with MDNS_DEBUG=1 for detailed logs');
  } else {
    print('Found ${results.length} service(s):');
    for (final service in results) {
      print('Service: ${service.name}');
      print('  Host: ${service.host}');
      print('  IPv4: ${service.addrV4?.address ?? 'none'}');
      print('  IPv6: ${service.addrV6?.address ?? 'none'}');
      print('  Port: ${service.port}');
      print('  Info: ${service.info}');
      if (service.infoFields.isNotEmpty) {
        print('  TXT: ${service.infoFields.join(', ')}');
      }
      print('');
    }
  }
}
