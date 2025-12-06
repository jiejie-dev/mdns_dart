import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:mdns_dart/mdns_dart.dart';

/// Simple mDNS server example
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('debug',
        abbr: 'd', help: 'Enable debug logging', negatable: false)
    ..addFlag('help',
        abbr: 'h', help: 'Show this help message', negatable: false)
    ..addOption('service',
        abbr: 's', help: 'Service type', defaultsTo: '_puupee._tcp')
    ..addOption('port', abbr: 'p', help: 'Service port', defaultsTo: '12056')
    ..addOption('name',
        abbr: 'n', help: 'Instance name', defaultsTo: 'Dart Test Server');

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e');
    print('Usage: dart run example/server.dart [options]');
    print(parser.usage);
    exit(1);
  }

  if (args.flag('help')) {
    print('mDNS Server Example');
    print('');
    print('Usage: dart run example/server.dart [options]');
    print('');
    print('Options:');
    print(parser.usage);
    exit(0);
  }

  final debug = args.flag('debug') || Platform.environment['MDNS_DEBUG'] == '1';
  final serviceType = args.option('service')!;
  final port = int.tryParse(args.option('port')!) ?? 12056;
  final instanceName = '${args.option('name')} ${Platform.localHostname}';

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
    instance: instanceName,
    service: serviceType,
    port: port,
    ips: localIPs,
    txt: ['path=/api'],
  );

  print('');
  print('Service: ${service.instance}');
  print('Type: $serviceType');
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
    print('  - Run with --debug or MDNS_DEBUG=1 for detailed logs');
    print('  - Ensure firewall allows UDP port 5353');
    print('  - Press Ctrl+C to stop');

    Completer<void> completer = Completer();
    await completer.future; // 程序将一直等待，永不退出
  } finally {
    await server.stop();
    print('Server stopped');
  }
}
