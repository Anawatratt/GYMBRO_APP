import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart';
import '../providers/auth_provider.dart';
import '../providers/friend_provider.dart';

class QRScreen extends ConsumerStatefulWidget {
  const QRScreen({super.key});

  @override
  ConsumerState<QRScreen> createState() => _QRScreenState();
}

class _QRScreenState extends ConsumerState<QRScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MobileScannerController? _scannerController;
  bool _isProcessing = false;
  bool _scanned = false;
  bool _isSavingQR = false;
  _CameraPermState _permState = _CameraPermState.unknown;

  final GlobalKey _qrRepaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      _checkAndRequestCamera();
    } else {
      _stopScanner();
    }
  }

  Future<void> _checkAndRequestCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      _startScanner();
    } else if (status.isPermanentlyDenied) {
      if (mounted) setState(() => _permState = _CameraPermState.permanentlyDenied);
    } else {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _startScanner();
      } else if (result.isPermanentlyDenied) {
        if (mounted) setState(() => _permState = _CameraPermState.permanentlyDenied);
      } else {
        if (mounted) setState(() => _permState = _CameraPermState.denied);
      }
    }
  }

  void _startScanner() {
    if (!mounted) return;
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    setState(() {
      _permState = _CameraPermState.granted;
      _scanned = false;
    });
  }

  void _stopScanner() {
    _scannerController?.stop();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  // ── Scan from gallery image ─────────────────────────────

  Future<void> _scanFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    if (mounted) setState(() => _isProcessing = true);

    try {
      // Use a temporary controller just for analysis (no camera)
      final analyzeController = MobileScannerController();
      final capture = await analyzeController.analyzeImage(picked.path);
      analyzeController.dispose();

      if (capture == null || capture.barcodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ไม่พบ QR Code ในรูปนี้'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      final value = capture.barcodes.first.rawValue;
      if (value == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('อ่าน QR Code ไม่ได้'), backgroundColor: Colors.orange),
          );
          setState(() => _isProcessing = false);
        }
        return;
      }

      // Processing flag will be cleared inside _handleScan
      await _handleScan(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  // ── Save QR to gallery ──────────────────────────────────

  Future<void> _saveQRToGallery() async {
    if (_isSavingQR) return;
    setState(() => _isSavingQR = true);
    try {
      final boundary = _qrRepaintKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      await Gal.putImageBytes(
        byteData.buffer.asUint8List(),
        name: 'gymbro_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึก QR Code ลงแกลเลอรีแล้ว!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่ได้: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingQR = false);
    }
  }

  // ── Handle QR scan result ───────────────────────────────

  Future<void> _handleScan(String scannedUid) async {
    if (_scanned) return;
    final me = ref.read(currentUserDocProvider).value;
    if (me == null) return;

    if (scannedUid == me.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('นั่นคือ QR Code ของคุณเอง!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() { _scanned = true; _isProcessing = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _scanned = false);
      return;
    }

    setState(() {
      _isProcessing = true;
      _scanned = true;
    });

    try {
      final target = await ref.read(userServiceProvider).getUserOnce(scannedUid);
      if (target == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบผู้ใช้นี้'), backgroundColor: Colors.red),
          );
        }
        setState(() { _isProcessing = false; _scanned = false; });
        return;
      }

      final existing =
          await ref.read(friendServiceProvider).getFriendDoc(me.uid, target.uid);
      if (existing != null) {
        String msg;
        if (existing.status == 'accepted') {
          msg = 'คุณเป็นเพื่อนกับ ${target.displayName} อยู่แล้ว!';
        } else if (existing.status == 'pending_sent') {
          msg = 'ส่งคำขอเป็นเพื่อนไปยัง ${target.displayName} แล้ว';
        } else {
          msg = 'มีคำขอเป็นเพื่อนจาก ${target.displayName} รออยู่';
        }
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
        }
        setState(() => _isProcessing = false);
        return;
      }

      await ref.read(friendServiceProvider).sendRequest(me, target);
      if (mounted) {
        final name = target.displayName.isNotEmpty
            ? target.displayName
            : target.email.split('@').first;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ส่งคำขอเป็นเพื่อนไปยัง $name แล้ว! 🎉'),
          backgroundColor: const Color(0xFFE53935),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
        setState(() { _isProcessing = false; _scanned = false; });
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserDocProvider).value;
    final myUid = me?.uid ?? '';
    final myName = (me?.displayName.isNotEmpty == true)
        ? me!.displayName
        : (me?.email.split('@').first ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFE53935),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_2), text: 'QR ของฉัน'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'สแกน'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildMyQRTab(myUid, myName),
          _buildScanTab(),
        ],
      ),
    );
  }

  // ── My QR Tab ───────────────────────────────────────────

  Widget _buildMyQRTab(String uid, String name) {
    if (uid.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('QR Code ของฉัน',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 8),
              Text('ให้เพื่อนสแกน QR นี้เพื่อแอดเพื่อน',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              const SizedBox(height: 32),

              // QR wrapped in RepaintBoundary for screenshot
              RepaintBoundary(
                key: _qrRepaintKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: uid,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1A1A1A),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Download button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSavingQR ? null : _saveQRToGallery,
                  icon: _isSavingQR
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isSavingQR ? 'กำลังบันทึก...' : 'บันทึก QR ลงเครื่อง',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Name card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2C2C2E)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person,
                          color: Color(0xFFE53935), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('GymBro ID: ${uid.substring(0, 8)}...',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text('QR Code นี้ไม่มีวันหมดอายุ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Scan Tab ────────────────────────────────────────────

  Widget _buildScanTab() {
    switch (_permState) {
      case _CameraPermState.unknown:
        return _buildRequestPermView();
      case _CameraPermState.denied:
        return _buildPermDeniedView(permanent: false);
      case _CameraPermState.permanentlyDenied:
        return _buildPermDeniedView(permanent: true);
      case _CameraPermState.granted:
        return _buildCameraView();
    }
  }

  Widget _buildRequestPermView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.camera_alt_outlined,
                  size: 56, color: Color(0xFFE53935)),
            ),
            const SizedBox(height: 24),
            const Text('ต้องการสิทธิ์กล้อง',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'แอปต้องการสิทธิ์เข้าถึงกล้องเพื่อสแกน QR Code',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkAndRequestCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('อนุญาตการใช้กล้อง',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildGalleryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermDeniedView({required bool permanent}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 24),
            Text(
              permanent ? 'กล้องถูกปิดกั้น' : 'ไม่ได้รับสิทธิ์กล้อง',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              permanent
                  ? 'กรุณาไปที่การตั้งค่า > แอป > GymBro แล้วเปิดสิทธิ์กล้อง'
                  : 'จำเป็นต้องอนุญาตกล้องเพื่อสแกน QR Code',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: permanent ? openAppSettings : _checkAndRequestCamera,
                icon: Icon(permanent ? Icons.settings : Icons.refresh),
                label: Text(permanent ? 'ไปที่การตั้งค่า' : 'ลองใหม่',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildGalleryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isProcessing ? null : _scanFromGallery,
        icon: _isProcessing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    color: Color(0xFFE53935), strokeWidth: 2),
              )
            : const Icon(Icons.photo_library_outlined, color: Color(0xFFE53935)),
        label: Text(
          _isProcessing ? 'กำลังสแกน...' : 'สแกนจากรูปในแกลเลอรี',
          style: const TextStyle(
              color: Color(0xFFE53935), fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE53935)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    final controller = _scannerController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        MobileScanner(
          controller: controller,
          errorBuilder: (context, error, child) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'กล้องเกิดข้อผิดพลาด\n${error.errorCode.name}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startScanner,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935)),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          },
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              final value = barcode.rawValue;
              if (value != null && !_scanned) {
                _handleScan(value);
              }
            }
          },
        ),
        // Dimmed overlay
        IgnorePointer(
          child: CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
        ),
        // Scan frame
        Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE53935), width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(children: _buildCorners()),
        ),
        // Bottom: gallery button + hint text
        Positioned(
          bottom: 32,
          left: 24,
          right: 24,
          child: _isProcessing
              ? const Column(children: [
                  CircularProgressIndicator(color: Color(0xFFE53935)),
                  SizedBox(height: 12),
                  Text('กำลังค้นหาผู้ใช้...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center),
                ])
              : Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'จ่อกล้องไปที่ QR Code ของเพื่อน',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Gallery scan button
                    GestureDetector(
                      onTap: _scanFromGallery,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFFE53935).withOpacity(0.6)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_library_outlined,
                                color: Color(0xFFE53935), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'เลือกจากรูปในแกลเลอรี',
                              style: TextStyle(
                                  color: Color(0xFFE53935),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  List<Widget> _buildCorners() {
    const size = 20.0;
    const thickness = 3.0;
    const color = Color(0xFFE53935);
    return [
      Positioned(
          top: 0,
          left: 0,
          child: _corner(size, thickness, color, top: true, left: true)),
      Positioned(
          top: 0,
          right: 0,
          child: _corner(size, thickness, color, top: true, left: false)),
      Positioned(
          bottom: 0,
          left: 0,
          child: _corner(size, thickness, color, top: false, left: true)),
      Positioned(
          bottom: 0,
          right: 0,
          child: _corner(size, thickness, color, top: false, left: false)),
    ];
  }

  Widget _corner(double size, double thickness, Color color,
      {required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(color, thickness, top: top, left: left),
      ),
    );
  }
}

enum _CameraPermState { unknown, denied, permanentlyDenied, granted }

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutSize = 240.0;
    const cornerRadius = 16.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: cutoutSize,
      height: cutoutSize,
    );
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullPath = Path()..addRect(Offset.zero & size);
    final cutout = Path()
      ..addRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(cornerRadius)));
    final overlayPath =
        Path.combine(PathOperation.difference, fullPath, cutout);
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool top;
  final bool left;

  _CornerPainter(this.color, this.thickness,
      {required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
