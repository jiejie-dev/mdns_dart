library;

import 'dart:io';

/// Whether [address] can be used as the destination of a unicast response.
///
/// Datagram source addresses should normally be concrete unicast addresses,
/// but some platforms can surface packets received by a wildcard-bound socket
/// with an unspecified source address (`0.0.0.0` or `::`). Sending to such an
/// address fails asynchronously at the socket level.
bool isUsableUnicastTarget(InternetAddress address, int port) {
  final isUnspecified = address.rawAddress.every((byte) => byte == 0);
  return port > 0 && port <= 65535 && !isUnspecified && !address.isMulticast;
}

extension RawDatagramSocketExtensions on RawDatagramSocket {
  /// Helper function to set the multicast interface.
  ///
  /// Throws a [OSError] on failure.
  void setMulticastInterface(NetworkInterface iface) {
    final level = address.type == InternetAddressType.IPv4
        ? RawSocketOption.levelIPv4
        : RawSocketOption.levelIPv6;
    final option = address.type == InternetAddressType.IPv4
        ? RawSocketOption.IPv4MulticastInterface
        : RawSocketOption.IPv6MulticastInterface;

    if (address.type == InternetAddressType.IPv4) {
      final interfaceAddress = iface.addresses.firstWhere(
        (addr) => addr.type == InternetAddressType.IPv4,
      );
      setRawOption(RawSocketOption(level, option, interfaceAddress.rawAddress));
      return;
    }

    // IPV6_MULTICAST_IF expects an interface index, not an IPv6 address.
    setRawOption(RawSocketOption.fromInt(level, option, iface.index));
  }
}
