import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_saver/file_saver.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  bool _isDownloading = false;
  String _statusMessage = "Klik tombol di bawah untuk mengunduh APK dari Asset.";

  Future<void> _downloadApkFromAsset() async {
    setState(() {
      _isDownloading = true;
      _statusMessage = "Mengambil file APK dari Asset...";
    });

    try {
      // 1. Muat file APK dari folder assets proyek
      final ByteData byteData = await rootBundle.load('assets/app/cripcheck.apk');
      
      // 2. Ubah ByteData menjadi Uint8List agar kompatibel dengan file_saver
      Uint8List bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      setState(() {
        _statusMessage = "Menyimpan file APK...";
      });

      // 3. Simpan file menggunakan file_saver (memunculkan dialog penyimpanan / direct download)
      String path = await FileSaver.instance.saveFile(
        name: 'cripcheck.apk',
        bytes: bytes,
        mimeType: MimeType.other,
      );

      setState(() {
        if (path.isNotEmpty) {
          _statusMessage = "APK berhasil diunduh dan disimpan!";
        } else {
          _statusMessage = "Pengunduhan dibatalkan.";
        }
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Terjadi kesalahan: $e";
      });
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Download APK dari Asset'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.android_rounded,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              _isDownloading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _downloadApkFromAsset,
                      icon: const Icon(Icons.download),
                      label: const Text('Unduh APK Sekarang'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}