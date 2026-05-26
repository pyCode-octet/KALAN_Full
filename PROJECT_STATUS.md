# Rapport de Statut du Projet KALAN

Ce document récapitule toutes les modifications apportées au projet KALAN, ainsi que l'analyse des vulnérabilités potentielles identifiées.

## 1. Modifications Effectuées (Historique)

### Interface Utilisateur (UI/UX)
- **Dashboard (Tableau de Bord)** : 
    - Refonte complète de l'en-tête : Logo circulaire à gauche (56px), texte "KALAN" à droite (14px).
    - Bannière d'accueil : Gradient Vert Émeraude (`0xFF4CAF50`), mascotte "Bonome" agrandie (85px) et détourée.
- **Profil** : Harmonisation de l'en-tête pour correspondre au Dashboard.
- **Flashcards** : 
    - Création du widget `FlashcardView` (style haute fidélité, bords 32px, thématique Question/Solution).
    - Amélioration de `FlashcardStudyScreen` : Barre de progression horizontale, boutons d'action circulaires, animation de flip.
- **Roadmap (Parcours)** :
    - Transformation en chemin serpentin (ZigZag).
    - Intégration des images de fond thématiques (`assets/roadmap/level-X.jpg`).
    - Ajout des mascottes de niveau le long du parcours.
    - Simplification des bannières de zone (`ZoneBanner`) en retirant les icônes superflues.

### Fonctionnalités & Logique
- **Partage Bluetooth** : Implémentation du service `BluetoothShareService` permettant l'envoi de decks complets (JSON sérialisé, gestion des morceaux/chunks pour le MTU).
- **Partage WhatsApp/Système** : Intégration de `share_plus` pour envoyer des liens de partage.
- **Deep Linking** : Configuration initiale pour ouvrir l'app via des URLs `https://kalan-app.web.app/deck/`.
- **IA locale (Gemma)** :
    - Augmentation du quota de mémoire (`maxTokens` à 2048).
    - Gestion robuste du texte PDF (truncation intelligente à 2000 caractères) pour éviter les crashs matériels.
- **Révision** : Logique de mélange (shuffle) des cartes aléatoire à chaque session mais stable durant la révision.

### Infrastructure & Assets
- **Assets** : Migration sécurisée des images de `roadmap-main` vers `assets/roadmap/` et mise à jour de `pubspec.yaml`.
- **Sécurité/Config** : Création et configuration du fichier `.env` avec les clés Supabase.
- **Build** : Correction des erreurs de compilation (imports manquants comme `foundation.dart`).

---

## 2. Analyse des Filles & Vulnérabilités (Audit)

### Sécurité des Données
- **Deep Links** : Les IDs de decks reçus via URL ne sont pas encore validés. Un utilisateur pourrait potentiellement tenter de deviner des IDs d'autres decks. 
    - *Action recommandée* : Ajouter une vérification de propriété ou rendre les IDs non-séquentiels (UUIDs déjà utilisés, ce qui est bien).
- **Secrets** : Les clés d'API sont bien isolées dans le `.env`, mais il faut s'assurer que ce fichier n'est jamais poussé sur GitHub (vérifié dans `.gitignore`).

### Stabilité & Performance
- **Mémoire Vive (RAM)** : L'IA locale Gemma est gourmande. Sur certains appareils (comme le TECNO testé), le dépassement de 2048 tokens provoque un crash système (Signal 11).
    - *Protection actuelle* : Truncation logicielle à 2000 caractères. C'est sûr, mais cela limite la quantité de texte analysable d'un coup.
- **Base de données** : La plupart des requêtes utilisent des paramètres préparés (`?`), ce qui protège contre l'injection SQL.

---

## 3. Fichiers Modifiés (Liste Complète)

| Fichier | Rôle / Modification |
| :--- | :--- |
| `lib/presentation/screens/home_dashboard.dart` | Refonte UI Header & Bannière |
| `lib/presentation/screens/profile_screen.dart` | Harmonisation Header |
| `lib/presentation/screens/roadmap_screen.dart` | Refonte ZigZag & Mondes |
| `lib/presentation/screens/flashcard_study_screen.dart` | Refonte UI & Shuffle stable |
| `lib/presentation/screens/generating_screen.dart` | Protection contre crash IA (PDF) |
| `lib/presentation/screens/share_screen.dart` | UI Partage & WhatsApp |
| `lib/presentation/widgets/flashcard_view.dart` | Nouveau widget graphique |
| `lib/presentation/widgets/zone_banner.dart` | Nettoyage visuel |
| `lib/services/bluetooth_share_service.dart` | Logique de transfert BLE |
| `lib/services/deep_link_service.dart` | Gestion des liens entrants |
| `lib/services/local_ai_service.dart` | Optimisation Gemma (maxTokens) |
| `lib/data/local/database_helper.dart` | Méthodes d'importation de decks |
| `lib/main.dart` | Initialisation Deep Links & Providers |
| `android/app/src/main/AndroidManifest.xml` | Configuration Deep Links |
| `pubspec.yaml` | Dépendances & Déclaration Assets |
| `.env` | Configuration Supabase |
| `AI_RESUME.md` | Résumé de transition (Ancien) |

---
**Note** : Aucun correctif de "faille" n'a été appliqué sans accord. Je recommande de sécuriser en priorité la validation des liens entrants.
