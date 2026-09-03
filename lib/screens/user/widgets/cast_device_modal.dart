import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/cast/cast_device_model.dart';
import '../../../services/cast/smart_tv_cast_service.dart';

/// Modal dialog pemilihan perangkat Smart TV (Ultra-Minimalis, Bersih, Tanpa Subteks).
class CastDeviceModal extends StatefulWidget {
  final SmartTvCastService castService;
  final String? currentVideoId;
  final VoidCallback? onDeviceChanged;

  const CastDeviceModal({
    super.key,
    required this.castService,
    this.currentVideoId,
    this.onDeviceChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required SmartTvCastService castService,
    String? currentVideoId,
    VoidCallback? onDeviceChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CastDeviceModal(
        castService: castService,
        currentVideoId: currentVideoId,
        onDeviceChanged: onDeviceChanged,
      ),
    );
  }

  @override
  State<CastDeviceModal> createState() => _CastDeviceModalState();
}

class _CastDeviceModalState extends State<CastDeviceModal> {
  final TextEditingController _codeController = TextEditingController();
  List<CastDevice> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _devices = widget.castService.discoveredDevices;
    _startScan();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() {
      _isLoading = true;
    });
    final devices = await widget.castService.scanDevices();
    if (mounted) {
      setState(() {
        _devices = devices;
        _isLoading = false;
      });
    }
  }

  Future<void> _connect(CastDevice device) async {
    await widget.castService.connect(device);
    if (widget.currentVideoId != null) {
      await widget.castService.castVideo(widget.currentVideoId!);
    }
    widget.onDeviceChanged?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _disconnect() async {
    await widget.castService.disconnect();
    widget.onDeviceChanged?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _connectWithCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    await widget.castService.connectWithTvCode(code);
    if (widget.currentVideoId != null) {
      await widget.castService.castVideo(widget.currentVideoId!);
    }
    widget.onDeviceChanged?.call();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedDevice = widget.castService.connectedDevice;

    return Material(
      color: const Color(0xFF0F172A),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 14,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header Bar Minimalis (Judul + Tombol Tutup, Tanpa Subteks)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.cast_rounded,
                    color: AppColors.accentCyan,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Cast ke TV',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          // Status Perangkat Aktif (Jika Terhubung)
          if (connectedDevice != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accentCyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tv_rounded,
                    color: AppColors.accentLight,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      connectedDevice.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: _disconnect,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Putus',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Loading Progress jika sedang memindai
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                minHeight: 2,
              ),
            ),

          // Daftar Perangkat TV (Ultra-Minimalis: Ikon + Nama TV)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: _devices.isEmpty && !_isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Perangkat tidak ditemukan',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _devices.length,
                    separatorBuilder: (_, _) => const Divider(
                      height: 1,
                      color: Colors.white10,
                    ),
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isCurrent = connectedDevice?.id == device.id;

                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: Icon(
                          device.type == CastDeviceType.chromecast
                              ? Icons.cast_rounded
                              : Icons.tv_rounded,
                          color: isCurrent ? AppColors.accentCyan : AppColors.accentSky,
                          size: 22,
                        ),
                        title: Text(
                          device.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        trailing: isCurrent
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.accentCyan,
                                size: 18,
                              )
                            : const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                        onTap: () => _connect(device),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),

          // Input Kode TV (1 Baris Ringkas & Rapi)
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _codeController,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Kode TV',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.dialpad_rounded, size: 16, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.accentCyan),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _connectWithCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryElectric,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Hubungkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
