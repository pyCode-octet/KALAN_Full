import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../data/local/database_helper.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            _scanResults = results.where((r) => r.device.platformName.isNotEmpty).toList();
          });
        }
      });
    } catch (e) {
      _showSnackBar('Erreur Bluetooth : $e');
    }

    await Future.delayed(const Duration(seconds: 15));
    if (mounted) setState(() => _isScanning = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendDeck(BluetoothDevice device) async {
    try {
      final decks = await DatabaseHelper.instance.getDecks('current_user');
      if (decks.isEmpty) {
        _showSnackBar('Aucun deck à envoyer');
        return;
      }

      final deck = decks.first;
      final flashcards = await DatabaseHelper.instance.getFlashcards(deck['uuid']);
      
      final payload = jsonEncode({
        'type': 'KALAN_DECK',
        'deck': deck,
        'flashcards': flashcards,
      });

      await device.connect();
      _showSnackBar('Connecté à ${device.platformName}');

      final services = await device.discoverServices();
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            await char.write(utf8.encode(payload));
            _showSnackBar('Deck envoyé avec succès !');
            return;
          }
        }
      }
      _showSnackBar('Erreur : Aucune caractéristique d\'écriture trouvée');
    } catch (e) {
      _showSnackBar('Erreur d\'envoi : $e');
    } finally {
      await device.disconnect();
    }
  }

  Future<void> _receiveDeck() async {
    _showSnackBar('Mode réception activé. En attente de données...');
    if (_connectedDevice == null) {
      _showSnackBar('Veuillez vous connecter à un appareil pour recevoir');
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Partager un Deck'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.onBackground,
        actions: [
          if (_isScanning)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appareils à proximité', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _scanResults.isEmpty 
                        ? Center(child: Text(_isScanning ? 'Recherche d\'appareils...' : 'Aucun appareil trouvé'))
                        : ListView.builder(
                            itemCount: _scanResults.length,
                            itemBuilder: (context, index) {
                              final result = _scanResults[index];
                              final name = result.device.platformName;
                              return InkWell(
                                onTap: () => _sendDeck(result.device),
                                child: _deviceItem(name, 'Appuyer pour envoyer', result.rssi),
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _receiveDeck, child: const Text('RECEVOIR'))),
                const SizedBox(width: 16),
                Expanded(child: ElevatedButton(onPressed: () => _showSnackBar('Choisissez un appareil dans la liste pour envoyer'), child: const Text('ENVOYER'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.bluetooth_searching_rounded, color: AppColors.primary, size: 40),
        ),
        const SizedBox(height: 16),
        const Text('Partage sans fil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('Échange tes decks avec tes amis à côté de toi', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _deviceItem(String name, String status, int rssi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.1), child: const Icon(Icons.phone_android_rounded, color: Colors.blue)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(status, style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Icon(Icons.signal_cellular_alt_rounded, color: rssi > -60 ? Colors.green : (rssi > -80 ? Colors.orange : Colors.red)),
        ],
      ),
    );
  }
}
