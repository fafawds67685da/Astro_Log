# ✨ StarLog

**Your Personal Astronomy Journal**

StarLog is a beautiful, feature-rich Flutter application designed for astronomy enthusiasts to track their celestial observations, manage their astronomy library, organize research, and build a stunning astrophotography collection.

![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green)
![License](https://img.shields.io/badge/License-MIT-blue)

---

## 🌟 Features

### 🏠 **Dashboard**
- **Cosmic Glass Morphism UI** - Stunning space-themed interface with animated starfield
- **Live Statistics** - Real-time tracking of all your astronomy data
- **Progress Tracking** - Visual progress indicators for books, objects, projects, and papers
- **Quick Overview** - Glanceable stats for all categories

### 📚 **Academics Hub**
- **Book Library** - Organize astronomy books by genre with folder-style grouping
- **Research Papers** - Track reading progress and organize by categories
- **Projects** - Manage astronomy projects with status tracking (Planned, In Progress, Done)

### 🌌 **Astronomy Explorer**
- **Celestial Objects** - Catalog planets, stars, galaxies, nebulae with classifications
- **Constellations** - Track star patterns with mythology and observation notes
- **Observatories** - Log observation sites with location and equipment details
- **Photo Gallery** - Create custom albums for astrophotography collections

### 🤖 **AI Assistant** (Placeholder)
- Chat interface ready for AI integration
- Quick action buttons for common astronomy queries
- Designed for future astronomy knowledge assistance

---

## 📱 Screenshots

> Add screenshots here showing:
> - Home Dashboard with cosmic theme
> - Astronomy hub with menu cards
> - Book library with genre folders
> - Gallery with custom albums
> - Object catalog with classifications

---

## 🛠️ Tech Stack

**Frontend:**
- **Flutter 3.0+** - Cross-platform UI framework
- **Dart 3.0+** - Programming language
- **Material Design** - UI components with custom cosmic theme

**Database:**
- **SQLite** (sqflite ^2.2.0) - Local database
- **Schema Version:** 5
- **Migration Support** - Automatic schema upgrades

**Image Handling:**
- **image_picker** - Gallery and camera image selection
- **Local Storage** - Images stored in app documents directory

**Key Packages:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.2.0+3
  path_provider: ^2.0.12
  image_picker: ^0.8.6
  path: ^1.8.2
```

---

## 🗄️ Database Schema

### **Core Tables**

**books** - Astronomy book library
- `id`, `title`, `author`, `genre`, `genreId`, `imagePath`, `isRead`, `notes`, `createdAt`

**celestial_objects** - Observed celestial bodies
- `id`, `name`, `type`, `classification`, `classificationId`, `imagePath`, `isObserved`, `notes`, `createdAt`

**constellations** - Star patterns
- `id`, `name`, `mythology`, `imagePath`, `notes`, `createdAt`

**observatories** - Observation locations
- `id`, `name`, `location`, `equipment`, `imagePath`, `notes`, `createdAt`

**projects** - Astronomy research projects
- `id`, `title`, `description`, `status`, `imagePath`, `notes`, `createdAt`

**research_papers** - Academic papers
- `id`, `title`, `author`, `journal`, `status`, `imagePath`, `notes`, `createdAt`

**gallery_albums** - Photo album organization
- `id`, `name`, `createdAt`

**gallery_images** - Astrophotography collection
- `id`, `albumId`, `imagePath`, `title`, `description`, `createdAt`

**genres** - Book categorization
- `id`, `name`

**classifications** - Object categorization
- `id`, `name`

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0 or higher
- Dart SDK 3.0 or higher
- Android Studio / VS Code
- Android device or emulator (Android 5.0+)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/astro_log.git
cd astro_log
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

### First Time Setup

**Important:** If upgrading from an older version, uninstall the existing app first to ensure proper database migration:

```bash
# On your device: Settings → Apps → StarLog → Uninstall
# Then run:
flutter run
```

---

## 🎨 Design Philosophy

StarLog features a **Cosmic Glass Morphism** design language:

- **Deep Space Gradients** - Purple, blue, and black cosmic backgrounds
- **Frosted Glass Containers** - Backdrop blur effects with transparency
- **Animated Starfield** - Twinkling stars for immersive experience
- **Neon Accents** - Cyan, purple, pink gradients for interactive elements
- **Smooth Animations** - Pulsing glows, smooth transitions
- **High Contrast** - Optimized for night-time astronomy use

---

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point with navigation
├── screens/
│   ├── home_dashboard_screen.dart # Main dashboard with stats
│   ├── space_screen.dart          # Astronomy hub menu
│   ├── academics_screen.dart      # Books/Papers/Projects tabs
│   ├── ai_assistant_screen.dart   # AI chat interface
│   ├── books_screen.dart          # Book library
│   ├── celestial_objects_screen.dart
│   ├── constellations_screen.dart
│   ├── observatories_screen.dart
│   ├── gallery_screen.dart        # Photo albums
│   ├── projects_screen.dart
│   └── research_papers_screen.dart
├── services/
│   └── database_helper.dart       # SQLite database management
├── widgets/
│   └── image_card.dart            # Reusable image display card
└── themes/
    └── app_theme.dart             # App-wide theming
```

---

## 🔧 Configuration

### Changing App Name
Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<application android:label="YourAppName">
```

### Database Version
Current version: **5**

To add new features, increment version in `database_helper.dart` and add migration logic.

---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas for Contribution
- 🤖 AI assistant integration (Gemini API)
- 📊 Data export/import functionality
- 🌍 Multi-language support
- 📈 Data visualization charts
- 🔍 Advanced search and filtering
- ☁️ Cloud sync capabilities
- 📸 Image editing tools

---

## 🐛 Known Issues

- **Duplicate App Icons:** Remove `android:taskAffinity=""` from AndroidManifest (fixed in latest version)
- **Database Migration:** Requires app uninstall when upgrading schema versions
- **Image Storage:** Images stored locally, no cloud backup

---

## 📋 Roadmap

- [ ] AI Assistant integration with Google Gemini
- [ ] Export data to PDF/CSV
- [ ] Cloud backup and sync
- [ ] Widget for home screen
- [ ] Dark/Light theme toggle
- [ ] Advanced filtering and search
- [ ] Star map integration
- [ ] Weather data for observatories
- [ ] Social sharing capabilities
- [ ] iOS support

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Your Name**
- GitHub: [@yourusername](https://github.com/yourusername)

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Astronomy community for inspiration
- Open source contributors

---

## 📞 Support

For support, email your@email.com or open an issue in the repository.

---

**⭐ Star this repo if you find it useful!**
