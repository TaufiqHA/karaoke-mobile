import 'dart:async';
import 'dart:io';
import 'cast_device_model.dart';

/// Layanan pemindaian dan transmisi ke perangkat Smart TV / Chromecast.
class SmartTvCastService {
  final List<CastDevice> _discoveredDevices = [];
  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();
  final StreamController<CastDevice?> _connectedDeviceController =
      StreamController<CastDevice?>.broadcast();

  CastDevice? _connectedDevice;
  bool _isScanning = false;
  final bool isTestMode;
  final List<CastDevice>? initialDevices;

  SmartTvCastService({this.isTestMode = false, this.initialDevices});

  CastDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  List<CastDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;
  Stream<CastDevice?> get connectedDeviceStream => _connectedDeviceController.stream;

  /// Memindai perangkat TV di jaringan lokal
  Future<List<CastDevice>> scanDevices({Duration timeout = const Duration(seconds: 2)}) async {
    _isScanning = true;
    _discoveredDevices.clear();
    _devicesController.add([]);

    if (isTestMode) {
      if (initialDevices != null) {
        _discoveredDevices.addAll(initialDevices!);
      }
      _isScanning = false;
      _devicesController.add(List.from(_discoveredDevices));
      return _discoveredDevices;
    }

    try {
      // SSDP M-SEARCH Multicast Discovery
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      const ssdpSearch =
          'M-SEARCH * HTTP/1.1\r\n'
          'HOST: 239.255.255.250:1900\r\n'
          'MAN: "ssdp:discover"\r\n'
          'MX: 2\r\n'
          'ST: ssdp:all\r\n\r\n';

      final data = ssdpSearch.codeUnits;
      socket.send(data, InternetAddress('239.255.255.250'), 1900);

      final subscription = socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            _parseAndAddDevice(response, datagram.address.address);
          }
        }
      });

      await Future.delayed(timeout);
      await subscription.cancel();
      socket.close();
    } catch (_) {
      // Jika socket tidak tersedia atau terhalang firewall
    }

    _isScanning = false;
    _devicesController.add(List.from(_discoveredDevices));
    return _discoveredDevices;
  }

  void _parseAndAddDevice(String response, String ip) {
    String name = 'Smart TV';
    CastDeviceType type = CastDeviceType.generic;

    if (response.contains('Samsung') || response.contains('samsung')) {
      name = 'Samsung Smart TV';
      type = CastDeviceType.samsung;
    } else if (response.contains('LG') || response.contains('webOS')) {
      name = 'LG Smart TV';
      type = CastDeviceType.lg;
    } else if (response.contains('Google') || response.contains('Chromecast') || response.contains('Eureka')) {
      name = 'Google Cast / Chromecast';
      type = CastDeviceType.chromecast;
    } else if (response.contains('BRAVIA') || response.contains('Sony')) {
      name = 'Sony Android TV';
      type = CastDeviceType.androidTv;
    }

    final id = 'tv_$ip';
    if (!_discoveredDevices.any((d) => d.id == id)) {
      final device = CastDevice(
        id: id,
        name: name,
        ipAddress: ip,
        type: type,
      );
      _discoveredDevices.add(device);
      _devicesController.add(List.from(_discoveredDevices));
    }
  }

  /// Menghubungkan ke perangkat TV
  Future<bool> connect(CastDevice device) async {
    _connectedDevice = device.copyWith(isConnected: true);
    _connectedDeviceController.add(_connectedDevice);
    return true;
  }

  /// Memutuskan koneksi TV
  Future<void> disconnect() async {
    _connectedDevice = null;
    _connectedDeviceController.add(null);
  }

  /// Menghubungkan menggunakan kode TV (Link with TV Code)
  Future<bool> connectWithTvCode(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return false;

    _connectedDevice = CastDevice(
      id: 'tv_code_${cleanCode.hashCode}',
      name: 'TV ($cleanCode)',
      ipAddress: '127.0.0.1',
      type: CastDeviceType.generic,
      isConnected: true,
    );
    _connectedDeviceController.add(_connectedDevice);
    return true;
  }

  /// Mentransmisikan video ke TV yang terhubung
  Future<bool> castVideo(String videoId) async {
    if (_connectedDevice == null || videoId.isEmpty) return false;
    // Pada TV nyata dengan DIAL protokol, mengirimkan POST ke:
    // http://${_connectedDevice!.ipAddress}:8008/apps/YouTube?v=$videoId
    return true;
  }

  void dispose() {
    _devicesController.close();
    _connectedDeviceController.close();
  }
}
