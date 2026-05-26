# État du Projet KALAN - Résumé pour l'IA (Mis à jour)

Ce document récapitule les modifications majeures effectuées pour permettre une continuité parfaite entre les modèles.

## 1. Interface Utilisateur (UI/UX)
- **Dashboard & Profil** : Header uniformisé (Logo circulaire à gauche), navigation par onglets (Profil/Progression/Amis). Blocs de stats Profil (XP/Niveau) avec icônes agrandies (80px).
- **Roadmap** : Design en zigzag corrigé (Séparation Niveaux 1 "Graines" et Niveau 2 "Baobab").
- **L'Arène (Nouveau)** : Intégration complète du mode Battle dynamique. Accès via l'onglet Classement -> BattleLobbyScreen.

## 2. Fonctionnalités de Défi (Arène)
- **Arena Lobby** : Affichage en temps réel des joueurs connectés et des défis reçus.
- **Création de Défi** : Double mode (Thème ou Maître Kalan IA). Mise d'XP (50-500) avec vérification du solde.
- **Recherche d'Adversaires** : Système dynamique avec avatars et statuts en ligne/hors ligne.
- **Battle Flow** : Salle d'attente animée, révision de 10 flashcards, duel de 10 quiz QCM chronométrés.

## 3. Services & IA
- **PresenceService** : Heartbeat de 5 minutes pour le statut "En ligne".
- **BattleService** : Gestion Realtime des duels via Supabase.
- **LocalAIService** : Nouveau `generateBattleContent` utilisant les modèles HuggingFace (Qwen) pour créer des défis uniques (Flashcards + Quiz) basés sur le thème.
- **IA Locale (Gemma)** : Génération de cartes via Gemma-2b avec limite de 2000 caractères.
- **Partage Social** : Intégration Bluetooth (BLE) et Deep Linking pour WhatsApp.

## 4. Architecture Technique
- **Frontend** : Flutter (Clean Architecture).
- **Backend** : Node.js API + Supabase (Realtime & Auth).
- **Stockage** : SQLite (Local) & Supabase (Cloud Sync).

## 5. Corrections Module Défis (Battle) — Session 2026-05-26

### Bug Critique 1 résolu : Heartbeat de présence activé
**Fichier modifié** : `lib/presentation/screens/home_screen.dart`
- Ajout de l'import `../../services/presence_service.dart`
- `PresenceService.startHeartbeat()` appelé dans `initState()` de `_HomeScreenState`
- `PresenceService.stopHeartbeat()` appelé dans `dispose()` de `_HomeScreenState`
- **Effet** : Les utilisateurs apparaissent maintenant "EN LIGNE" dans le lobby de l'Arène (colonne `last_active` mise à jour toutes les 5 minutes).

### Bug 2 résolu : Parsing du modèle `Battle` corrigé
**Fichier modifié** : `lib/domain/models/battle_model.dart`
- `Battle.fromJson` extrait maintenant `flashcards` depuis `json['content']['flashcards']`
- `quizQuestions` extrait depuis `json['content']['quizzes']` (avec fallback sur `quiz_questions`)
- **Effet** : Les flashcards et questions QCM sont correctement désérialisées depuis la colonne JSONB `content` de Supabase. La dette technique des appels directs dans `duel_flashcard_review_screen.dart` et `duel_game_screen.dart` peut être résolue progressivement.

### Nettoyage code mort
- **Supprimé** : `lib/presentation/screens/battle_setup_screen.dart` (écran de config obsolète, remplacé par `create_challenge_screen.dart`, aucune référence dans la codebase)
- **Supprimé** : Classe `AuthWrapper` de `lib/main.dart` (jamais instanciée, code mort depuis le passage au flux SplashScreen → HomeScreen)
- **Supprimés** : Imports inutilisés dans `main.dart` (`presence_service.dart`, `home_screen.dart`, `welcome_carousel_screen.dart`)

## 6. État des tables Supabase — DÉPLOYÉ le 2026-05-26

### Modifications appliquées sur Supabase (SQL exécuté et confirmé)

**Table `users`**
| Colonne ajoutée | Type | Usage |
|---|---|---|
| `last_active` | `TIMESTAMPTZ DEFAULT NOW()` | Heartbeat de présence (joueurs EN LIGNE dans le lobby) |

**Table `battles`**
| Colonne ajoutée | Type | Usage |
|---|---|---|
| `created_at` | `TIMESTAMPTZ DEFAULT NOW()` | Tri des défis dans le lobby |
| `phase_start_time` | `TIMESTAMPTZ` | Timer de phase (révision/quiz) |
| `current_question_index` | `INT DEFAULT 0` | Progression du quiz |
| `real_theme` | `TEXT` | Thème réel généré par l'IA |
| `turn_user_id` | `UUID` | Suivi du tour de jeu |

### Fonctions RPC créées sur Supabase

| Fonction RPC | Paramètres | Comportement |
|---|---|---|
| `create_battle` | `p_inviter_id, p_invited_id, p_theme, p_xp_bet` | Crée un défi, retourne l'UUID |
| `submit_answer` | `p_battle_id, p_user_id, p_question_index, p_answer` | Vérifie la réponse vs `content→quizzes`, incrémente le score |
| `abandon_battle` | `p_battle_id, p_loser_id` | Clôture en abandon, winner = l'autre joueur, distribue XP |
| `finish_battle` | `p_battle_id` | Clôture normale, compare scores, distribue XP — **idempotente** |

**Règle XP** : Gagnant `+xp_bet × 2` · Perdant `-xp_bet` · Égalité `±0`

## 7. Bouton Défis déplacé dans le Dashboard + epe.png — Session 2026-05-26

### Déplacement du bouton "L'ARÈNE KALAN"
- **Retiré de** : `lib/presentation/screens/leaderboard_screen.dart` (import + méthode `_buildVersusBlock` supprimés)
- **Ajouté dans** : `lib/presentation/screens/home_dashboard.dart` via la méthode `_buildArenaBlock`
- **Position** : Entre la grille des matières et la section badges, toujours visible dès le chargement du dashboard
- Le bouton utilise `epe.png` comme icône (voir ci-dessous)

### Correction de l'image epe.png
- **Problème** : Le projet principal utilisait l'emoji `⚔️` (texte) à la place de la vraie image `epe.png` dans `battle_lobby_screen.dart`
- **Cause** : `assets/images/epe.png` n'existait pas dans le projet principal (seulement dans `KALAN/`)
- **Correction** :
  1. Copie de `KALAN/kalan_app/assets/images/epe.png` → `kalan_app/assets/images/epe.png`
  2. `battle_lobby_screen.dart` : `Text('⚔️')` → `Image.asset('assets/images/epe.png', height: 120)` avec fallback emoji
  3. `home_dashboard.dart` : bouton arena utilise `epe.png` (height: 52) comme icône visuelle

## 8. Nouvelle méthode `generateSingleFlashcard` — Session 2026-05-26

**Fichier modifié** : `lib/services/local_ai_service.dart`

### Méthode ajoutée : `generateSingleFlashcard({required String input, String? notes})`

Détecte automatiquement parmi 3 cas et appelle le bon prompt Qwen :

| Cas | Condition | Comportement |
|---|---|---|
| **1** | `notes` fourni + `input` est une question | Cherche le fragment minimal **dans les notes uniquement** — pas d'invention |
| **2** | `notes` fourni + `input` est une phrase affirmative | Transforme en paire Q/R — réponse = fragment minimal de la phrase |
| **3** | Pas de `notes` (ou < 20 chars) | Qwen répond depuis sa connaissance, simule 2 sources concordantes |

### Output JSON garanti
```json
{"question": "...", "answer": "...", "source": "cours|web"}
// ou si sources contradictoires (cas 3) :
{"question": "...", "answer": null, "warning": "sources contradictoires", "source": "web"}
```

### Détails techniques
- `_isQuestion(text)` : détecte via `?` final ou mots interrogatifs FR/EN
- `temperature: 0.2` pour des réponses factuelles et déterministes
- `max_tokens: 256` suffisant pour une flashcard unique
- `_parseSingleCard` rejette la réponse si identique à l'input brut (sécurité anti-boucle)
- Fallback automatique sur `Qwen2.5-7B` si `72B` est indisponible

### Usage depuis le code Flutter
```dart
final ai = LocalAIService();

// Cas 1 — question dans les notes
final card = await ai.generateSingleFlashcard(
  input: "Qu'est-ce qu'Ali aime ?",
  notes: "Ali aime les mangues et joue au foot.",
);
// → {"question": "Qu'est-ce qu'Ali aime ?", "answer": "les mangues", "source": "cours"}

// Cas 3 — question sans notes
final card = await ai.generateSingleFlashcard(
  input: "Quelle est la capitale de la France ?",
);
// → {"question": "Quelle est la capitale de la France ?", "answer": "Paris", "source": "web"}
```

## 9. Audit & Corrections des modifications Gemini CLI — Session 2026-05-26

### Modifications Gemini validées (aucun bug)
- `create_challenge_screen.dart` : params `initialOpponentId`/`initialOpponentPseudo` → correctement utilisés depuis `versus_screen.dart`
- `user_repository_impl.dart` : `searchUsers` retourne maintenant `points` + `last_active` → permet d'afficher niveau + statut en ligne dans la recherche d'adversaire
- `_buildGemmaPrompt(text, subject)` : ajout du param `subject` → Gemma reçoit le contexte de matière ✅
- `canUseOnlineAI()` : fallback si plugin connectivity échoue → plus robuste en mode test ✅
- `generateBattleContent` : température abaissée à 0.3 ✅
- Flow Maître Kalan : acceptBattle + startGeneration + generateBattleContent auto ✅

### Bugs Gemini corrigés

**Bug Critique 1 — `generateSingleFlashcard` ignorait `notes` (paramètre perdu)**
- **Cause** : Gemini a remplacé le routage 3-cas par un seul "diagnostic prompt" qui n'injectait jamais `notes`
- **Effets** : `_buildCas1Prompt`, `_buildCas2Prompt`, `_buildCas3Prompt`, `_isQuestion`, `_parseSingleCard` devenues code mort
- **Correction** : Routage 3-cas restauré — `hasNotes && isQuestion` → cas1, `hasNotes` → cas2, sinon → cas3

**Bug Critique 2 — Exception `image_floue` avalée dans generateSingleFlashcard**
- **Cause** : `throw Exception('image floue')` était à l'intérieur d'un try/catch → silencieusement ignoré, le loop continuait
- **Correction** : Supprimée de `generateSingleFlashcard` (n'a pas de sens pour saisie manuelle)

**Bug 3 — Diagnostic OCR au mauvais endroit**
- **Cause** : La détection d'image floue était mise dans `generateSingleFlashcard` (saisie manuelle) au lieu de `_generateOnlineFlashcards` (scan OCR)
- **Correction** : Déplacée dans `_generateOnlineFlashcards` via un ÉTAPE 1 dans le prompt Qwen + rethrow ciblé `IMAGE_FLOUE`
- `generating_screen.dart` : catch identifie `IMAGE_FLOUE` → SnackBar orange "Image trop floue, reprends la photo"

## 10. Intégration `generateSingleFlashcard` dans l'écran de création manuelle — Session 2026-05-26

**Fichier modifié** : `lib/presentation/screens/manual_flashcard_create_screen.dart`

### Changements
- Ajout import `../../services/local_ai_service.dart`
- Ajout champs `bool _isGenerating` + `LocalAIService _ai`
- Label du champ question renommé `'Question ou phrase'` (reflète les 3 cas de l'IA)
- Bouton ✨ (`Icons.auto_awesome`, vert #2D6A2D) ajouté à droite du champ question avec `Tooltip`
- Spinner blanc 20×20 pendant la génération (remplace l'icône)

### Logique `_generateWithAI()`
1. Refuse si le champ question est vide (SnackBar)
2. Passe `notes: widget.extractedText` si le texte OCR est présent (≥1 char), `null` sinon
3. Appelle `_ai.generateSingleFlashcard(input, notes)` avec timeout 30s
4. Si `answer != null` : remplit `_questionController` (question normalisée) et `_answerController`
5. Si `warning != null` : affiche SnackBar d'avertissement (sources contradictoires)
6. Si `answer == null` : SnackBar "L'IA n'a pas pu trouver de réponse"
7. Catch réseau → SnackBar "Erreur réseau"

### Cas couverts automatiquement (délégués à `LocalAIService`)
| Input utilisateur | Notes OCR | Résultat |
|---|---|---|
| "Qu'est-ce que la photosynthèse ?" | Présent | Réponse extraite des notes uniquement |
| "La photosynthèse est le processus..." | Présent | Transformé en paire Q/R minimale |
| "Qu'est-ce que la photosynthèse ?" | Absent | Réponse depuis connaissance Qwen (web) |
