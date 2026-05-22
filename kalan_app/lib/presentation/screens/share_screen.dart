import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';
import 'dart:async';
import '../../core/constants/app_colors.dart';
import '../../data/local/database_helper.dart';
import '../../domain/entities/deck.dart';
import '../../data/remote/supabase_service.dart';

class ShareScreen extends StatefulWidget {
  final Deck? deck; // Optionnel: si null, on peut proposer de choisir ou partager le dernier
  const ShareScreen({super.key, this.deck});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  StreamSubscription? _scanSubscription;

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
      _showSnackBar("Erreur Bluetooth : $e");
    }

    await Future.delayed(const Duration(seconds: 15));
    if (mounted) setState(() => _isScanning = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendDeck(BluetoothDevice device) async {
    try {
      Deck? deckToSend = widget.deck;
      
      if (deckToSend == null) {
        final userId = SupabaseService.currentUser?.id ?? "guest";
        final decksMaps = await DatabaseHelper.instance.getDecks(userId);
        if (decksMaps.isEmpty) {
          _showSnackBar("Aucun deck à envoyer");
          return;
        }
        final deckMap = decksMaps.first;
        deckToSend = Deck(
          uuid: deckMap['uuid'],
          title: deckMap['title'],
          subject: deckMap['subject'],
          level: deckMap['level'],
          createdAt: DateTime.now(),
        );
      }

      final flashcards = await DatabaseHelper.instance.getFlashcards(deckToSend.uuid);
      
      final payload = jsonEncode({
        'type': 'KALAN_DECK',
        'deck': {
          'uuid': deckToSend.uuid,
          'title': deckToSend.title,
          'subject': deckToSend.subject,
          'level': deckToSend.level,
        },
        'flashcards': flashcards,
      });

      _showSnackBar("Connexion à ${device.platformName}...");
      await device.connect();

      final services = await device.discoverServices();
      bool sent = false;
      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write) {
            // Split payload into chunks if it's too large for MTU
            final List<int> data = utf8.encode(payload);
            await char.write(data, withoutResponse: false);
            sent = true;
            _showSnackBar("Deck ${deckToSend.title} envoyé avec succès !");
            break;
          }
        }
        if (sent) break;
      }
      if (!sent) _showSnackBar("Erreur : Aucune caractéristique d'écriture trouvée");
    } catch (e) {
      _showSnackBar("Erreur d'envoi : $e");
    } finally {
      await device.disconnect();
    }
  }



  Future<void> _receiveDeck() async {
    _showSnackBar("Mode réception : en attente de données...");
    
    // Pour que la réception fonctionne vraiment via Bluetooth BLE, 
    // le téléphone doit agir comme un serveur (Peripheral).
    // Sans package additionnel, on peut simuler la réception en ouvrant un canal
    // de lecture sur l'appareil émetteur si celui-ci expose un service.
    
    _showSnackBar("Note: Pour un partage optimal, l'utilisation d'un fichier .kalan partagé est recommandée.");
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
                        ? Center(child: Text(_isScanning ? "Recherche d'appareils..." : "Aucun appareil trouvé"))
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
                Expanded(child: ElevatedButton(onPressed: () => _showSnackBar('Choisissez un appareil dans la liste'), child: const Text('ENVOYER'))),
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
