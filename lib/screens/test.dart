import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AppBar APK Method',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isProcessing = false;

  Future<void> _extractAndInstallApk() async {
    setState(() {
      _isProcessing = true;
    });

    _showSnackBar("Mengekstrak file APK dari aset...");

    try {
      // 1. Ambil file APK dari folder assets proyek
      final byteData = await rootBundle.load('assets/app.apk');

      // 2. Siapkan lokasi penyimpanan sementara di HP
      Directory? tempDir = await getTemporaryDirectory();
      String apkPath = "${tempDir.path}/local_update.apk";
      File localFile = File(apkPath);

      // 3. Tulis data byte ke penyimpanan lokal
      await localFile.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
        flush: true,
      );

      if (!mounted) return;
      _showSnackBar("Membuka file instalasi...");

      // 4. Buka file APK lokal untuk mulai menginstal
      final result = await OpenFilex.open(apkPath);

      if (!mounted) return;
      if (result.type != ResultType.done) {
        _showSnackBar("Gagal menginstal: ${result.message}", isError: true);
      } else {
        _showSnackBar("Proses instalasi dimulai.");
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("Terjadi kesalahan: $e", isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Fungsi pembantu untuk memunculkan snackbar pemberitahuan
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── WIDGET METHOD YANG ANDA MAKSUD ───
  Widget _apkInstaller() {
    if (_isProcessing) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.install_mobile),
      tooltip: 'Instal APK Baru',
      onPressed: _extractAndInstallApk, // Memanggil fungsi instalasi
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aplikasi Utama"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // ─── MEMANGGIL WIDGET METHOD DI SINI ───
          _apkInstaller(),
        ],
      ),
      body: const Center(
        child: Text(
          "Konten Utama Aplikasi Anda Ada di Sini",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}
