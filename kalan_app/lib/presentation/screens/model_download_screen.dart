import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../ai/model_downloader.dart';

class ModelDownloadScreen extends StatefulWidget {
  const ModelDownloadScreen({super.key});

  @override
  State<ModelDownloadScreen> createState() => _ModelDownloadScreenState();
}

class _ModelDownloadScreenState extends State<ModelDownloadScreen> {
  double _progress = 0;
  bool _isDownloading = false;
  String _status = "Prêt à télécharger";

  void _startDownload() {
    setState(() {
      _isDownloading = true;
      _status = "Téléchargement en cours...";
    });

    ModelDownloader.downloadModel().listen(
      (progress) {
        setState(() {
          _progress = progress;
        });
      },
      onDone: () {
        setState(() {
          _isDownloading = false;
          _status = "Téléchargement terminé !";
        });
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      },
      onError: (error) {
        setState(() {
          _isDownloading = false;
          _status = "Erreur : $error";
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F2EA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF2D6A2D)),
                const SizedBox(height: 30),
                const Text(
                  'Bienvenue dans KALAN !',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pour fonctionner sans internet, l\'IA locale nécessite un téléchargement unique de 1.5 GB.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF555555)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  '(Utilisez une connexion WiFi pour éviter les frais mobiles)',
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                if (_isDownloading || _progress > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 12,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2D6A2D)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(_status, style: const TextStyle(color: Colors.grey)),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D6A2D),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('Télécharger l\'IA (1.5 GB)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Plus tard (création manuelle)', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
