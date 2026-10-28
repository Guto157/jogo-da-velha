import 'dart:io';
import 'dart:convert';
class WifiService {
  ServerSocket? server; Socket? socket; Function(String)? onData; Function()? onConnected;
  Future<String> host() async {
    server = await ServerSocket.bind(InternetAddress.anyIPv4, 4040);
    var ip = await _getIp();
    server!.listen((client) { socket = client; onConnected?.call(); client.listen((data) { onData?.call(utf8.decode(data)); }); });
    return ip;
  }
  Future<void> connect(String ip) async { socket = await Socket.connect(ip, 4040); onConnected?.call(); socket!.listen((data) { onData?.call(utf8.decode(data)); }); }
  void send(String msg) { socket?.write(msg); }
  Future<String> _getIp() async {
    for (var interface in await NetworkInterface.list()) { for (var addr in interface.addresses) { if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) { return addr.address; } } }
    return '192.168.0.??';
  }
  void dispose() { socket?.close(); server?.close(); }
}
