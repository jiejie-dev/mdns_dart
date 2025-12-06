import 'dart:async';
import 'dart:io';
import 'package:mdns_dart/mdns_dart.dart';

/// Simple mDNS server example
void main() async {
  // Check for debug flag from environment or args
  final debug = Platform.environment['MDNS_DEBUG'] == '1' ||
      Platform.executableArguments.contains('--debug');

  print('Starting mDNS server...');
  print('Platform: ${Platform.operatingSystem}');

  // Get all local IPs for service advertisement
  final interfaces = await NetworkInterface.list();
  final List<InternetAddress> localIPs = [];

  print('Network interfaces:');
  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        localIPs.add(addr);
        print('  ${interface.name}: ${addr.address}');
      }
    }
  }

  if (localIPs.isEmpty) {
    print('Could not find any network interface');
    return;
  }

  // Create service with all local IPs
  final service = await MDNSService.create(
    instance: 'Dart Test Server ${Platform.localHostname}',
    service: '_puupee._tcp',
    port: 12056,
    ips: localIPs,
    txt: ['path=/api'],
  );

  print('');
  print('Service: ${service.instance}');
  print('Addresses: ${localIPs.map((ip) => ip.address).join(', ')}');
  print('Port: ${service.port}');
  print('');

  // Start server with reusePort enabled to allow sharing port 5353 with system mDNS service
  final server = MDNSServer(
    MDNSServerConfig(
      zone: service,
      reusePort: !Platform.isWindows, // Windows doesn't support SO_REUSEPORT
      reuseAddress: true,
      joinMulticastOnAllInterfaces: true, // Enable cross-platform discovery
      logger: debug ? (msg) => print(msg) : null,
    ),
  );

  try {
    await server.start();
    print('Server started - advertising service!');
    print('');
    print('Tips:');
    print('  - Run with MDNS_DEBUG=1 for detailed logs');
    print('  - Ensure firewall allows UDP port 5353');
    print('  - Press Ctrl+C to stop');

    Completer<void> completer = Completer();
    await completer.future; // 程序将一直等待，永不退出
  } finally {
    await server.stop();
    print('Server stopped');
  }
}
