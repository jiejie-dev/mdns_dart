import 'dart:io';
import 'package:args/args.dart';
import 'package:mdns_dart/mdns_dart.dart';

/// Simple mDNS client example
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('debug', abbr: 'd', help: 'Enable debug logging', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show this help message', negatable: false)
    ..addOption('service', abbr: 's', help: 'Service type to discover', defaultsTo: '_puupee._tcp')
    ..addOption('timeout', abbr: 't', help: 'Discovery timeout in seconds', defaultsTo: '5');

  late ArgResults args;
  try {
    args = parser.parse(arguments);
  } catch (e) {
    print('Error: $e');
    print('Usage: dart run example/client.dart [options]');
    print(parser.usage);
    exit(1);
  }

  if (args.flag('help')) {
    print('mDNS Client Example');
    print('');
    print('Usage: dart run example/client.dart [options]');
    print('');
    print('Options:');
    print(parser.usage);
    exit(0);
  }

  final debug = args.flag('debug') || Platform.environment['MDNS_DEBUG'] == '1';
  final serviceType = args.option('service')!;
  final timeout = int.tryParse(args.option('timeout')!) ?? 5;

  print('Discovering mDNS services...');
  print('Platform: ${Platform.operatingSystem}');
  print('Service type: $serviceType');
  print('Timeout: ${timeout}s');

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
    serviceType,
    timeout: Duration(seconds: timeout),
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
    print('  3. Run with --debug or MDNS_DEBUG=1 for detailed logs');
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
