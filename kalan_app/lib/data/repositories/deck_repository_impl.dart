import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/deck.dart';
import '../../domain/repositories/deck_repository.dart';
import '../local/database_helper.dart';
import '../models/deck_model.dart';
import '../remote/supabase_service.dart';
import '../../services/connectivity_service.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DeckRepositoryImpl implements DeckRepository {
  final DatabaseHelper _dbHelper;
  final ConnectivityService _connectivity;
  static const _uuid = Uuid();

  DeckRepositoryImpl(this._dbHelper, this._connectivity);

  @override
  Future<List<Deck>> getDecks() async {
    final db = await _dbHelper.database;
    
    // 1. Récupère d'abord les decks locaux avec leurs compteurs
    final localMaps = await db.rawQuery('''
      SELECT d.*, 
             (SELECT COUNT(*) FROM flashcards WHERE deck_id = d.uuid) as cardCount,
             (SELECT COUNT(*) FROM flashcards WHERE deck_id = d.uuid AND difficulty >= 2) as masteredCount
      FROM decks d
      ORDER BY d.created_at DESC
    ''');
    
    final Map<String, Map<String, dynamic>> mergedData = {};
    for (var m in localMaps) {
      mergedData[m['uuid'] as String] = Map<String, dynamic>.from(m);
    }

    // 2. Si online, récupère de Supabase
    if (await _connectivity.isOnline()) {
      final user = SupabaseService.currentUser;
      try {
        // Decks personnels
        if (user != null) {
          final personalData = await SupabaseService.client
              .from('decks')
              .select()
              .eq('user_id', user.id);
          
          for (var remoteDeck in personalData as List) {
            final uuid = remoteDeck['uuid'] as String;
            if (!mergedData.containsKey(uuid)) {
              final model = DeckModel.fromSupabaseJson(remoteDeck);
              await db.insert('decks', model.toMap(), 
                  conflictAlgorithm: ConflictAlgorithm.replace);
              
              mergedData[uuid] = {
                ...remoteDeck,
                'cardCount': 0,
                'masteredCount': 0,
              };
            }
          }
        }
      } catch (e) {
        // log error
      }
    }

    final sortedData = mergedData.values.toList()
      ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));

    return sortedData.map((data) {
      final model = DeckModel.fromMap(data);
      return Deck(
        uuid: model.uuid,
        title: model.title,
        description: model.description,
        subject: model.subject,
        level: model.level,
        isPublic: model.isPublic,
        downloadCount: model.downloadCount,
        createdAt: model.createdAt,
        cardCount: data['cardCount'] ?? 0,
        masteredCount: data['masteredCount'] ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<Deck>> getPublicDecks() async {
    if (!(await _connectivity.isOnline())) return [];

    try {
      final publicData = await SupabaseService.client
          .from('decks')
          .select()
          .eq('is_public', true)
          .order('download_count', ascending: false);
      
      return (publicData as List).map((json) {
        final model = DeckModel.fromSupabaseJson(json);
        return Deck(
          uuid: model.uuid,
          title: model.title,
          description: model.description,
          subject: model.subject,
          level: model.level,
          isPublic: model.isPublic,
          downloadCount: model.downloadCount,
          createdAt: model.createdAt,
          cardCount: 0, // Compte inconnu pour les decks publics distants sans fetch additionnel
          masteredCount: 0,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> createDeck(String title, String subject, String? level, {List<Map<String, String>>? cards, String? uuid}) async {
    final db = await _dbHelper.database;
    final user = SupabaseService.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final String currentUserId = prefs.getString('current_user_uuid') ?? user?.id ?? 'guest';
    final String deckUuid = uuid ?? _uuid.v4();
    
    final model = DeckModel(
      uuid: deckUuid,
      userId: currentUserId,
      title: title,
      subject: subject,
      level: level,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    // 1. Insère le deck
    await db.insert('decks', model.toMap());

    // 2. Insère les cartes si présentes
    if (cards != null && cards.isNotEmpty) {
      for (var card in cards) {
        final cardUuid = _uuid.v4();
        await db.insert('flashcards', {
          'uuid': cardUuid,
          'deck_id': deckUuid,
          'question': card['question'],
          'answer': card['answer'],
          'difficulty': 0,
          'created_at': DateTime.now().toIso8601String(),
        });

        // Sync carte en arrière-plan (non-bloquant)
        _connectivity.isOnline().then((isOnline) {
          if (isOnline && user != null) {
            SupabaseService.client.from('flashcards').insert({
              'uuid': cardUuid,
              'deck_id': deckUuid,
              'question': card['question'],
              'answer': card['answer'],
              'difficulty': 0,
            }).catchError((e) {
              _addToSyncQueue('CREATE_FLASHCARD', {'uuid': cardUuid, 'deck_id': deckUuid, 'question': card['question'], 'answer': card['answer']});
            });
          } else {
            _addToSyncQueue('CREATE_FLASHCARD', {'uuid': cardUuid, 'deck_id': deckUuid, 'question': card['question'], 'answer': card['answer']});
          }
        });
      }

      // Première génération de fiches : débloquer le badge chercheur
      await _dbHelper.awardFlashcardBadgeIfFirst(currentUserId);
    }

    // 3. Sync Deck Supabase en arrière-plan (non-bloquant)
    _connectivity.isOnline().then((isOnline) {
      if (isOnline && user != null) {
        SupabaseService.client.from('decks').insert(model.toSupabaseJson()).then((_) {
          db.update('decks', {'is_synced': 1}, where: 'uuid = ?', whereArgs: [deckUuid]);
        }).catchError((e) {
          _addToSyncQueue('CREATE_DECK', model.toSupabaseJson());
        });
      } else {
        _addToSyncQueue('CREATE_DECK', model.toSupabaseJson());
      }
    });
  }

  @override
  Future<void> deleteDeck(String uuid) async {
    final db = await _dbHelper.database;
    
    // 1. Delete local
    await db.delete('decks', where: 'uuid = ?', whereArgs: [uuid]);

    // 2. Sync Supabase
    if (await _connectivity.isOnline()) {
      try {
        await SupabaseService.client.from('decks').delete().eq('uuid', uuid);
      } catch (e) {
        await _addToSyncQueue('DELETE_DECK', {'uuid': uuid});
      }
    } else {
      await _addToSyncQueue('DELETE_DECK', {'uuid': uuid});
    }
  }

  @override
  Future<void> togglePublic(String uuid) async {
    final db = await _dbHelper.database;
    final maps = await db.query('decks', where: 'uuid = ?', whereArgs: [uuid]);
    
    if (maps.isNotEmpty) {
      final current = DeckModel.fromMap(maps.first);
      final newIsPublic = !current.isPublic;
      
      // 1. Update local
      await db.update('decks', 
          {'is_public': newIsPublic ? 1 : 0, 'is_synced': 0},
          where: 'uuid = ?', whereArgs: [uuid]);

      // 2. Sync Supabase
      if (await _connectivity.isOnline()) {
        try {
          await SupabaseService.client.from('decks')
              .update({'is_public': newIsPublic})
              .eq('uuid', uuid);
          await db.update('decks', {'is_synced': 1}, where: 'uuid = ?', whereArgs: [uuid]);
        } catch (e) {
          await _addToSyncQueue('UPDATE_DECK', {'uuid': uuid, 'is_public': newIsPublic});
        }
      } else {
        await _addToSyncQueue('UPDATE_DECK', {'uuid': uuid, 'is_public': newIsPublic});
      }
    }
  }

  Future<void> _addToSyncQueue(String action, Map<String, dynamic> payload) async {
    final db = await _dbHelper.database;
    await db.insert('sync_queue', {
      'action': action,
      'payload': jsonEncode(payload),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
