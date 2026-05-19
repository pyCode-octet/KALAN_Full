# 🌳 KALAN

Application d'apprentissage par flashcards pour élèves africains.
Offline-first avec sync cloud quand connexion disponible.

---

## 📁 Structure du projet

| Dossier | Description |
|:---|:---|
| `kalan_app/` | Application Flutter (Android/iOS) |
| `kalan_backend/` | Backend Supabase (config, fonctions) |
| `kalan_interface/` | Designs HTML de référence |

---

## 🚀 Installation rapide

### 1. Cloner le repo
```bash
git clone https://github.com/Blackdry13579/KALAN_Full.git
cd KALAN
```

### 2. Configurer l'environnement
```bash
cp .env.example .env
# Éditer .env avec tes clés
```

### 3. Lancer l'app
```bash
cd kalan_app
flutter pub get
flutter run
```

### 4. Configurer l'IA (Online & Offline)
Toutes les instructions pour connecter l'IA **Qwen (en ligne)** et savoir comment l'IA **Gemma (hors ligne)** se télécharge et s'exécute automatiquement sur le smartphone sont détaillées dans le [Guide de l'IA de l'Application](kalan_app/README.md).

---

## 🗄️ Base de données (Supabase)

Les tables à créer manuellement dans Supabase :

| Table | Description |
|:---|:---|
| `users` | Profils utilisateurs |
| `subjects` | Matières scolaires |
| `decks` | Fiches de révision |
| `flashcards` | Cartes question/réponse |
| `quiz_results` | Résultats des quiz |
| `badges` | Badges disponibles |
| `user_badges` | Badges débloqués par user |

Détails complets : voir `kalan_backend/README.md`

---

## 🤝 Contribution

1. Fork → Branch → PR
2. Ne jamais commit de `.env` ou clés API
3. Ne jamais commit de modèles IA lourds (.gguf, .bin)

---

## 📄 License

MIT
