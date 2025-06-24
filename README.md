# R.E.M. - Sleep and Dream Social App 🌙

A Flutter application focused on promoting healthy sleep and dream journaling, built with Firebase.

---

## 📖 Description

**R.E.M. (Rest Experience Mindfulness)** is a cross‑platform social app for athletes and active individuals to:

* **Track Sleep**: Log nightly sleep details (duration, stages, quality).
* **Journal Dreams**: Record dreams with ratings and tags.
* **Community Sharing**: Share insights and compare trends with friends.
* **Analytics**: View charts for sleep consistency, dream frequency, and more.

---

## 🚀 Features

* 🔒 **Firebase Authentication** (Signup, Login, Password Reset)
* 📔 **Dream Journaling** with multi‑dream entry modal
* 📊 **Sleep Tracking** (sleep stages, sleep score, consistency)
* ☁️ **Cloud Firestore** for real‑time data storage per user
* 📱 **Multi‑Platform**: Android, iOS, Web, macOS, Windows
* 🌙 **Dark Mode** with per‑user persistence
* 📆 **Daily Reminders** ("Did you dream last night?")

---

## 📦 Dependencies

```yaml
flutter:
  sdk: flutter
firebase_core: ^2.0.0
firebase_auth: ^4.0.0
cloud_firestore: ^4.0.0
fl_chart: ^0.71.0
cupertino_icons: ^1.0.0
```

---

## 🔨 Installation & Setup

1. **Clone the repo**

   ```bash
   git clone https://github.com/Cpos64/REM.git
   cd REM
   ```

2. **Install packages**

   ```bash
   flutter pub get
   ```

3. **OpenAI configuration**

   Create a `.env` file in the project root and add your OpenAI API key:

   ```bash
   echo "OPENAI_API_KEY=your-key" > .env
   ```

4. **Firebase configuration**

   * Create a Firebase project.
   * Add Android, iOS, and Web apps in Firebase console.
   * Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS).
   * Place them in `android/app/` and `ios/Runner/` respectively.
   * For Web, update `index.html` Firebase config snippet in `/web` folder.
   * Create the composite Firestore indexes listed in [FIRESTORE_INDEXES.md](FIRESTORE_INDEXES.md).

5. **Run the app**

   ```bash
   flutter run
   ```

### Android requirements

The project uses `minSdkVersion` 21. When building or launching on an
emulator, ensure that your Android SDK and device images are at least API
level 21; older API levels will fail during Gradle setup.

---

## 🗂️ Project Structure

```
lib/
 ├── main.dart          # App entrypoint
 ├── screens/           # Screens: Home, SleepLog, Dreams
 ├── widgets/           # Reusable UI components
 ├── services/          # Firestore, Auth, Notifications
 └── models/            # Data models (SleepEntry, DreamEntry)

planner.md             # Daily/Weekly task planner
README.md              # Project overview and setup
```

---

## 📝 Planner

Keep track of your daily and weekly goals in [`planner.md`](planner.md). It’s versioned with the code so you never lose sight of what’s next!

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/your-feature`
3. Commit your changes: \`git commit -m 'feat: add my feature'
4. Push to your branch: `git push origin feat/your-feature`
5. Open a Pull Request and describe your changes.

Please follow the existing code style and include before/after snippets for any code modifications.

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
