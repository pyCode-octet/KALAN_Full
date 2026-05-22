import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../data/local/database_helper.dart';
import '../domain/entities/deck.dart';

class BluetoothShareService {
  static final BluetoothShareService _instance = BluetoothShareService._internal();
  factory BluetoothShareService() => _instance;
  BluetoothShareService._internal();

  // UUIDs pour le service de partage KALAN
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String characteristicUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  /// Prépare les données d'un deck pour l'envoi
  Future<String> prepareDeckPayload(Deck deck) async {
    final flashcards = await DatabaseHelper.instance.getFlashcards(deck.uuid);
    
    return jsonEncode({
      'type': 'KALAN_DECK',
      'version': '1.0',
      'deck': {
        'title': deck.title,
        'subject': deck.subject,
        'level': deck.level,
        'description': deck.description,
      },
      'flashcards': flashcards.map((f) => {
        'question': f['question'],
        'answer': f['answer'],
      }).toList(),
    });
  }

  /// Envoie le payload par morceaux (chunks) pour respecter le MTU Bluetooth
  Future<void> sendPayload(BluetoothDevice device, String payload) async {
    await device.connect();
    try {
      final services = await device.discoverServices();
      BluetoothCharacteristic? targetChar;

      for (var service in services) {
        for (var char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            targetChar = char;
            break;
          }
        }
        if (targetChar != null) break;
      }

      if (targetChar == null) throw Exception("Aucune caractéristique d'écriture trouvée");

      final List<int> data = utf8.encode(payload);
      final int mtu = device.mtuNow;
      // On garde une marge de sécurité sur le MTU (3 octets de header BLE)
      final int chunkSize = mtu - 3; 

      for (var i = 0; i < data.length; i += chunkSize) {
        final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);
        await targetChar.write(chunk, withoutResponse: false);
        // Petit délai pour laisser le temps au récepteur de traiter
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Envoyer un signal de fin (EOF)
      await targetChar.write(utf8.encode("KALAN_EOF"), withoutResponse: false);
      
    } finally {
      await device.disconnect();
    }
  }

  /// Importe un deck reçu dans la base de données locale
  Future<void> importReceivedDeck(String jsonPayload) async {
    final data = jsonDecode(jsonPayload);
    if (data['type'] != 'KALAN_DECK') return;

    final deckData = data['deck'];
    final List<dynamic> flashcardsData = data['flashcards'];

    final List<Map<String, String>> cards = flashcardsData.map((f) => {
      'question': f['question'].toString(),
      'answer': f['answer'].toString(),
    }).toList();

    // On utilise le DatabaseHelper directement ou un repository
    // Ici on simule l'ajout via un repo si possible, sinon direct SQL
    await DatabaseHelper.instance.insertDeckWithCards(
      title: "${deckData['title']} (Reçu)",
      subject: deckData['subject'],
      level: deckData['level'],
      cards: cards,
    );
  }
}
