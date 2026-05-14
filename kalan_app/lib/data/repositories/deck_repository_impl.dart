import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/deck.dart';
import '../../domain/repositories/deck_repository.dart';
import '../local/database_helper.dart';
import '../models/deck_model.dart';
import '../remote/supabase_service.dart';
import '../../services/connectivity_service.dart';
import 'package:uuid/uuid.dart';

class DeckRepositoryImpl implements DeckRepository {
  final DatabaseHelper _dbHelper;
  final ConnectivityService _connectivity;
  static const _uuid = Uuid();

  DeckRepositoryImpl(this._dbHelper, this._connectivity);

  @override
  Future<List<Deck>> getDecks() async {
    final db = await _dbHelper.database;
    
    // 1. Récupère d'abord les decks locaux
    final localMaps = await db.query('decks', orderBy: 'created_at DESC');
    final localDecks = localMaps.map((m) => DeckModel.fromMap(m)).toList();
    
    final Map<String, DeckModel> mergedDecks = {};
    for (var deck in localDecks) {
      mergedDecks[deck.uuid] = deck;
    }

    // 2. Si online, récupère de Supabase
    if (await _connectivity.isOnline()) {
      final user = SupabaseService.currentUser;
      try {
        // Decks publics
        final publicData = await SupabaseService.client
            .from('decks')
            .select()
            .eq('is_public', true);
        
        final List<DeckModel> remoteDecks = (publicData as List)
            .map((json) => DeckModel.fromSupabaseJson(json))
            .toList();

        // Decks personnels
        if (user != null) {
          final personalData = await SupabaseService.client
              .from('decks')
              .select()
              .eq('user_id', user.id);
          
          remoteDecks.addAll((personalData as List)
              .map((json) => DeckModel.fromSupabaseJson(json)));
        }

        // Merge sans doublons
        for (var remoteDeck in remoteDecks) {
          if (!mergedDecks.containsKey(remoteDeck.uuid)) {
            mergedDecks[remoteDeck.uuid] = remoteDeck;
            // Insérer en local avec is_synced = 1
            await db.insert('decks', remoteDeck.toMap(), 
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        } catch (e) {
          // log error or handle it
        }
    }

    final sortedDecks = mergedDecks.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sortedDecks.map((model) => Deck(
      uuid: model.uuid,
      title: model.title,
      description: model.description,
      subject: model.subject,
      level: model.level,
      isPublic: model.isPublic,
      downloadCount: model.downloadCount,
      createdAt: model.createdAt,
    )).toList();
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
      
      final List<DeckModel> remoteDecks = (publicData as List)
          .map((json) => DeckModel.fromSupabaseJson(json))
          .toList();

      return remoteDecks.map((model) => Deck(
        uuid: model.uuid,
        title: model.title,
        description: model.description,
        subject: model.subject,
        level: model.level,
        isPublic: model.isPublic,
        downloadCount: model.downloadCount,
        createdAt: model.createdAt,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> createDeck(String title, String subject, String? level) async {
    final db = await _dbHelper.database;
    final user = SupabaseService.currentUser;
    final String uuid = _uuid.v4();
    
    final model = DeckModel(
      uuid: uuid,
      userId: user?.id ?? 'guest',
      title: title,
      subject: subject,
      level: level,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    // 1. Insère IMMÉDIATEMENT dans SQLite
    await db.insert('decks', model.toMap());

    // 2. Sync Supabase si online
    if (await _connectivity.isOnline() && user != null) {
      try {
        await SupabaseService.client.from('decks').insert(model.toSupabaseJson());
        await db.update('decks', {'is_synced': 1}, where: 'uuid = ?', whereArgs: [uuid]);
      } catch (e) {
        await _addToSyncQueue('CREATE_DECK', model.toSupabaseJson());
      }
    } else {
      await _addToSyncQueue('CREATE_DECK', model.toSupabaseJson());
    }
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
