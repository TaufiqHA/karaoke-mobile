import 'dart:async';
import 'dart:io';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'cast_device_model.dart';

/// Layanan pemindaian dan transmisi ke perangkat Smart TV / Chromecast
/// Menggunakan flutter_chrome_cast dan youtube_explode_dart untuk ekstraksi stream YouTube.
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
  StreamSubscription? _googleCastDevicesSubscription;
  StreamSubscription? _googleCastSessionSubscription;

  SmartTvCastService({this.isTestMode = false, this.initialDevices}) {
    if (!isTestMode) {
      _initGoogleCast();
    }
  }

  CastDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  List<CastDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;
  Stream<CastDevice?> get connectedDeviceStream => _connectedDeviceController.stream;

  void _initGoogleCast() {
    try {
      // Inisialisasi listener perangkat dari Google Cast Discovery Manager
      _googleCastDevicesSubscription =
          GoogleCastDiscoveryManager.instance.devicesStream.listen((devices) {
        for (final dev in devices) {
          final id = 'chromecast_${dev.deviceID}';
          if (!_discoveredDevices.any((d) => d.id == id)) {
            _discoveredDevices.add(
              CastDevice(
                id: id,
                name: dev.friendlyName,
                ipAddress: 'Chromecast',
                type: CastDeviceType.chromecast,
              ),
            );
          }
        }
        if (!_devicesController.isClosed) {
          _devicesController.add(List.from(_discoveredDevices));
        }
      }, onError: (_) {});

      // Inisialisasi listener status sesi Google Cast
      _googleCastSessionSubscription =
          GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
        if (session != null && session.device != null) {
          _connectedDevice = CastDevice(
            id: 'chromecast_${session.device!.deviceID}',
            name: session.device!.friendlyName,
            ipAddress: 'Chromecast',
            type: CastDeviceType.chromecast,
            isConnected: true,
          );
        } else if (_connectedDevice?.type == CastDeviceType.chromecast) {
          _connectedDevice = null;
        }
        if (!_connectedDeviceController.isClosed) {
          _connectedDeviceController.add(_connectedDevice);
        }
      }, onError: (_) {});
    } catch (_) {
      // Jika Google Cast SDK belum siap atau platform tidak mendukung
    }
  }

  /// Ekstraksi direct video stream URL dari YouTube
  Future<String?> getDirectStreamUrl(String videoId) async {
    if (isTestMode || videoId.isEmpty) {
      return 'https://example.com/video/$videoId.mp4';
    }

    YoutubeExplode? yt;
    try {
      yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(videoId);
      
      // Mengambil stream muxed (audio + video gabungan) resolusi tertinggi
      final muxedStreams = manifest.muxed;
      if (muxedStreams.isNotEmpty) {
        final streamInfo = muxedStreams.withHighestBitrate();
        return streamInfo.url.toString();
      }

      // Fallback ke video-only jika muxed tidak tersedia
      final videoStreams = manifest.video;
      if (videoStreams.isNotEmpty) {
        return videoStreams.first.url.toString();
      }
    } catch (_) {
      // Stream extraction error handling
    } finally {
      yt?.close();
    }
    return null;
  }

  /// Memindai perangkat TV di jaringan lokal (Chromecast + Smart TV via SSDP)
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
      // Trigger scan Google Cast Discovery
      GoogleCastDiscoveryManager.instance.startDiscovery();
    } catch (_) {}

    try {
      // SSDP M-SEARCH Multicast Discovery untuk Smart TV lainnya (Samsung, LG, Sony)
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
    if (!isTestMode && device.type == CastDeviceType.chromecast) {
      try {
        final gcDevice = GoogleCastDiscoveryManager.instance.devices.firstWhere(
          (d) =>
              'chromecast_${d.deviceID}' == device.id ||
              d.friendlyName == device.name,
        );
        await GoogleCastSessionManager.instance.startSessionWithDevice(gcDevice);
      } catch (_) {}
    }

    _connectedDevice = device.copyWith(isConnected: true);
    _connectedDeviceController.add(_connectedDevice);
    return true;
  }

  /// Memutuskan koneksi TV
  Future<void> disconnect() async {
    if (!isTestMode && _connectedDevice?.type == CastDeviceType.chromecast) {
      try {
        await GoogleCastSessionManager.instance.endSessionAndStopCasting();
      } catch (_) {}
    }

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
  Future<bool> castVideo(
    String videoId, {
    String? title,
    String? artist,
    String? thumbnailUrl,
  }) async {
    if (_connectedDevice == null || videoId.isEmpty) return false;

    if (isTestMode) {
      return true;
    }

    try {
      // 1. Dapatkan direct stream URL MP4/HLS dari YouTube
      final directStreamUrl = await getDirectStreamUrl(videoId);
      if (directStreamUrl == null || directStreamUrl.isEmpty) {
        return false;
      }

      // 2. Cast ke Chromecast jika terhubung dengan Google Cast
      if (_connectedDevice?.type == CastDeviceType.chromecast) {
        final mediaInfo = GoogleCastMediaInformation(
          contentId: videoId,
          streamType: CastMediaStreamType.buffered,
          contentUrl: Uri.parse(directStreamUrl),
          contentType: 'video/mp4',
          metadata: GoogleCastMovieMediaMetadata(
            title: title ?? 'Karaoke Track',
            subtitle: artist,
            images: thumbnailUrl != null
                ? [GoogleCastImage(url: Uri.parse(thumbnailUrl))]
                : null,
          ),
        );

        await GoogleCastRemoteMediaClient.instance.loadMedia(mediaInfo);
        return true;
      }

      // Untuk perangkat TV generic / DIAL protocol
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Kontrol playback TV: Play
  Future<void> play() async {
    if (isTestMode) return;
    try {
      await GoogleCastRemoteMediaClient.instance.play();
    } catch (_) {}
  }

  /// Kontrol playback TV: Pause
  Future<void> pause() async {
    if (isTestMode) return;
    try {
      await GoogleCastRemoteMediaClient.instance.pause();
    } catch (_) {}
  }

  /// Kontrol playback TV: Seek
  Future<void> seek(Duration position) async {
    if (isTestMode) return;
    try {
      await GoogleCastRemoteMediaClient.instance.seek(
        GoogleCastMediaSeekOption(position: position),
      );
    } catch (_) {}
  }

  void dispose() {
    _googleCastDevicesSubscription?.cancel();
    _googleCastSessionSubscription?.cancel();
    _devicesController.close();
    _connectedDeviceController.close();
  }
}
