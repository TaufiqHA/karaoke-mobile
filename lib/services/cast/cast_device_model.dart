enum CastDeviceType {
  chromecast,
  samsung,
  lg,
  androidTv,
  generic,
}

class CastDevice {
  final String id;
  final String name;
  final String ipAddress;
  final CastDeviceType type;
  final bool isConnected;

  const CastDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.type = CastDeviceType.generic,
    this.isConnected = false,
  });

  CastDevice copyWith({
    String? id,
    String? name,
    String? ipAddress,
    CastDeviceType? type,
    bool? isConnected,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      type: type ?? this.type,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
