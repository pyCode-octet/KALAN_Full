# 🧠 KALAN AI - Module Intelligence Artificielle (Online & Offline)

Bienvenue dans le cœur intelligent de **KALAN** ! Cette application utilise une architecture d'IA hybride révolutionnaire pensée pour fonctionner de manière optimale en Afrique, même dans les zones sans connexion réseau.

---

## 🚀 Architecture IA de KALAN

Le système de génération de flashcards pédagogiques fonctionne selon un principe de cascade à 3 niveaux :

1. **Niveau 1 : IA en ligne (Prioritaire - Ultra-Intelligente)** 🌐
   * **Modèle** : `Qwen/Qwen2.5-72B-Instruct` (via l'API Hugging Face).
   * **Rôle** : Génère des fiches de révision d'une qualité exceptionnelle (pédagogie structurée, questions de réflexion) formatées en JSON.
2. **Niveau 2 : IA hors ligne (Secours 1 - Locale)** 🔌
   * **Modèle** : `Gemma 3 270M` (exécuté localement sur le processeur du smartphone via TensorFlow Lite et le plugin `flutter_gemma`).
   * **Rôle** : Prend le relais si l'élève n'a pas internet. Il utilise un prompt textuel optimisé et rapide.
3. **Niveau 3 : Extracteur Grammatical (Secours 2 - Zéro Latence)** 📝
   * **Algorithme** : Analyse de texte heuristique propre à KALAN.
   * **Rôle** : Si le mini-modèle Gemma offline ne parvient pas à répondre, KALAN analyse les cours pour extraire automatiquement les définitions grammaticales clés (ex: les phrases contenant *« est »*, *« sont »*, *« signifie »*) et en faire de vraies flashcards de cours.

---

## 🔑 Connexion de l'IA Qwen (En ligne)

Pour connecter l'IA **Qwen-72B** (qui est le modèle en ligne par défaut), tu as besoin d'un jeton d'accès (token) gratuit de Hugging Face.

### Étape 1 : Créer ton jeton Hugging Face
1. Rends-toi sur [Hugging Face](https://huggingface.co/) et crée un compte gratuit.
2. Va dans tes **Settings** ⚙️ > **Access Tokens**.
3. Clique sur **New Token**, donne-lui le nom `kalan-app`, choisis le rôle **Read**, puis clique sur **Generate**.
4. Copie le token généré (il commence par `hf_...`).

### Étape 2 : Configurer l'application
1. Dans le dossier `kalan_app/`, duplique le fichier d'exemple :
   ```bash
   cp .env.example .env
   ```
2. Ouvre le fichier `.env` et ajoute ton token dans la variable `HF_TOKEN` :
   ```env
   SUPABASE_URL=https://votre-projet.supabase.co
   SUPABASE_ANON_KEY=votre-cle-anon-ici
   HF_TOKEN=hf_ton_token_copie_ici
   ```

*(Le code de l'application chargera automatiquement ce token via le package `flutter_dotenv`)*.

---

## 📲 Comment se passe le téléchargement de l'IA locale (Gemma) ?

**Oui ! Le téléchargement est entièrement automatisé et transparent pour l'utilisateur.** 

### Comment ça marche ?
1. **Détection** : Dès que l'utilisateur tente d'importer un cours en mode offline, le module `ModelDownloader` vérifie si le modèle Gemma (`gemma3-270m-it-q8.task`) est déjà installé sur le téléphone.
2. **Téléchargement silencieux** : S'il est absent, l'application lance automatiquement un téléchargement en tâche de fond depuis le dépôt de releases public optimisé de KALAN :
   `https://github.com/Blackdry13579/kalan-ai-models/releases/download/v1.0/gemma3-270m-it-q8.task`
3. **Suivi visuel** : L'écran de l'application affiche une barre de progression en temps réel de 0% à 100% à l'utilisateur.
4. **Stockage et chargement** : Le fichier du modèle (environ 270 Mo) est stocké de manière sécurisée dans les dossiers système de l'application sur le téléphone. Lors des futures révisions, il se charge **immédiatement en moins d'une seconde** sans consommer le moindre mégaoctet de connexion internet !

---

## 🛠️ Démarrage rapide du Projet (Développeurs)

Pour lancer le projet localement après l'avoir cloné :

```bash
# 1. Aller dans le dossier flutter
cd kalan_app

# 2. Configurer les variables d'environnement
cp .env.example .env
# Renseigne tes clés Supabase et ton jeton HF_TOKEN dans le fichier .env

# 3. Récupérer les dépendances Flutter
flutter pub get

# 4. Lancer l'application sur ton appareil ou émulateur
flutter run
```

---

## 🎯 Prompts Système utilisés par KALAN

* **Prompt Qwen (En ligne)** : Demande une structure académique complexe au format JSON strict pour générer les fiches les plus riches et interactives.
* **Prompt Gemma (Hors ligne)** : Simplifié pour s'adapter à la taille réduite de l'appareil mobile, il demande un format textuel direct `Q1:` / `R1:` pour garantir rapidité et fiabilité totale de la réponse sans gaspiller la batterie du smartphone.
