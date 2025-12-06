import 'dart:async';
import 'dart:io';
import 'package:mdns_dart/mdns_dart.dart';

/// Simple mDNS server example
void main() async {
  print('Starting mDNS server...');

  // Get local IP
  final interfaces = await NetworkInterface.list();
  InternetAddress? localIP;

  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        localIP = addr;
        break;
      }
    }
    if (localIP != null) break;
  }

  if (localIP == null) {
    print('Could not find network interface');
    return;
  }

  // Create service
  final service = await MDNSService.create(
    instance: 'Dart Test Server',
    service: '_puupee._tcp',
    port: 12056,
    ips: [localIP],
    txt: ['path=/api'],
  );

  print('Service: ${service.instance} at ${localIP.address}:${service.port}');

  // Start server with reusePort enabled to allow sharing port 5353 with system mDNS service
  final server = MDNSServer(
    MDNSServerConfig(
      zone: service,
      reusePort: !Platform
          .isWindows, // Allow multiple processes to bind to port 5353 (needed on macOS)
      reuseAddress: true,
    ),
  );

  try {
    await server.start();
    print('Server started - advertising service!');

    Completer<void> completer = Completer();
    await completer.future; // 程序将一直等待，永不退出
  } finally {
    await server.stop();
    print('Server stopped');
  }
}
