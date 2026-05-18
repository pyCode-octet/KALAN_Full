import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/flashcard.dart';
import '../../domain/repositories/flashcard_repository.dart';
import '../local/database_helper.dart';
import '../models/flashcard_model.dart';
import '../remote/supabase_service.dart';
import '../../services/connectivity_service.dart';

class FlashcardRepositoryImpl implements FlashcardRepository {
  final DatabaseHelper _dbHelper;
  final ConnectivityService _connectivity;
  static const _uuid = Uuid();

  FlashcardRepositoryImpl(this._dbHelper, this._connectivity);

  @override
  Future<List<Flashcard>> getFlashcardsByDeck(String deckUuid) async {
    final db = await _dbHelper.database;
    
    // 1. Local Query - Simple and direct using UUID
    final localMaps = await db.query(
      'flashcards',
      where: 'deck_id = ?',
      whereArgs: [deckUuid],
    );
    final localCards = localMaps.map((m) => FlashcardModel.fromMap(m)).toList();
    
    final Map<String, FlashcardModel> mergedCards = {};
    for (var card in localCards) {
      mergedCards[card.uuid] = card;
    }

    // 2. Supabase Query
    if (await _connectivity.isOnline()) {
      try {
        final remoteData = await SupabaseService.client
            .from('flashcards')
            .select()
            .eq('deck_id', deckUuid);
        
        final remoteCards = (remoteData as List)
            .map((json) => FlashcardModel.fromSupabaseJson(json))
            .toList();

        for (var remoteCard in remoteCards) {
          if (!mergedCards.containsKey(remoteCard.uuid)) {
            // Use UUID for deck_id locally as well
            final modelToSave = FlashcardModel(
              uuid: remoteCard.uuid,
              deckId: deckUuid,
              question: remoteCard.question,
              answer: remoteCard.answer,
              difficulty: remoteCard.difficulty,
              nextReview: remoteCard.nextReview,
              interval: remoteCard.interval,
              repetitions: remoteCard.repetitions,
              createdAt: remoteCard.createdAt,
              isSynced: true,
            );
            mergedCards[remoteCard.uuid] = modelToSave;
            await db.insert('flashcards', modelToSave.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      } catch (e) {
        // Silent error
      }
    }

    return mergedCards.values.map((model) => Flashcard(
      uuid: model.uuid,
      question: model.question,
      answer: model.answer,
      difficulty: model.difficulty,
      nextReview: model.nextReview,
      interval: model.interval,
      repetitions: model.repetitions,
    )).toList();
  }

  @override
  Future<void> createFlashcard(String deckUuid, String question, String answer) async {
    final db = await _dbHelper.database;
    final String uuid = _uuid.v4();
    
    final model = FlashcardModel(
      uuid: uuid,
      deckId: deckUuid, // Use UUID instead of local integer ID
      question: question,
      answer: answer,
      createdAt: DateTime.now(),
      isSynced: false,
    );

    // 1. Local
    await db.insert('flashcards', model.toMap());

    // 2. Sync
    final supabasePayload = model.toSupabaseJson();
    // For Supabase, deck_id is already the deckUuid in our model

    if (await _connectivity.isOnline()) {
      try {
        await SupabaseService.client.from('flashcards').insert(supabasePayload);
        await db.update('flashcards', {'is_synced': 1}, where: 'uuid = ?', whereArgs: [uuid]);
      } catch (e) {
        await _addToSyncQueue('CREATE_FLASHCARD', supabasePayload);
      }
    } else {
      await _addToSyncQueue('CREATE_FLASHCARD', supabasePayload);
    }
  }

  @override
  Future<void> deleteFlashcard(String uuid) async {
    final db = await _dbHelper.database;
    await db.delete('flashcards', where: 'uuid = ?', whereArgs: [uuid]);

    if (await _connectivity.isOnline()) {
      try {
        await SupabaseService.client.from('flashcards').delete().eq('uuid', uuid);
      } catch (e) {
        await _addToSyncQueue('DELETE_FLASHCARD', {'uuid': uuid});
      }
    } else {
      await _addToSyncQueue('DELETE_FLASHCARD', {'uuid': uuid});
    }
  }

  @override
  Future<void> updateFlashcardReview(String uuid, int difficulty) async {
    final db = await _dbHelper.database;
    
    // Fetch current card to update SRS fields
    final maps = await db.query('flashcards', where: 'uuid = ?', whereArgs: [uuid]);
    if (maps.isEmpty) return;
    
    final current = FlashcardModel.fromMap(maps.first);
    
    // Basic SRS Logic
    int repetitions = current.repetitions + 1;
    int interval = current.interval;
    
    if (difficulty >= 2) { // Moyen ou Facile
      if (repetitions == 1) {
        interval = 1;
      } else if (repetitions == 2) {
        interval = 6;
      } else {
        interval = (interval * 2.5).round();
      }
    } else { // Difficile
      repetitions = 0;
      interval = 1;
    }
    
    // Adjust based on exact difficulty
    if (difficulty == 3) interval = (interval * 1.2).round(); // Facile: increase a bit more
    if (difficulty == 1) interval = 1; // Difficile: always 1 day
    
    final nextReview = DateTime.now().add(Duration(days: interval));
    
    final Map<String, dynamic> updateData = {
      'difficulty': difficulty,
      'next_review': nextReview.toIso8601String(),
      'interval': interval,
      'repetitions': repetitions,
      'is_synced': 0,
    };

    // 1. Local
    await db.update('flashcards', updateData, where: 'uuid = ?', whereArgs: [uuid]);

    // 2. Sync
    final syncData = {
      'difficulty': difficulty,
      'next_review': nextReview.toIso8601String(),
      'interval': interval,
      'repetitions': repetitions,
    };

    if (await _connectivity.isOnline()) {
      try {
        await SupabaseService.client
            .from('flashcards')
            .update(syncData)
            .eq('uuid', uuid);
        await db.update('flashcards', {'is_synced': 1}, where: 'uuid = ?', whereArgs: [uuid]);
      } catch (e) {
        await _addToSyncQueue('UPDATE_FLASHCARD', {'uuid': uuid, ...syncData});
      }
    } else {
      await _addToSyncQueue('UPDATE_FLASHCARD', {'uuid': uuid, ...syncData});
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
