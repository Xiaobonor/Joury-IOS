# Joury iOS App

AI-powered personal growth and interactive journaling iOS app built with SwiftUI.

## Project Status

✅ **基礎架構完成** - 核心模組和系統已實作並整合

## Features Implemented

### Core Architecture
- **App Configuration**: Centralized config management with environment-specific settings
- **Theme System**: Dynamic light/dark theme support with custom color schemes
- **Localization**: Multi-language support (Traditional Chinese & English)
- **Network Layer**: Robust networking with error handling, retry logic, and authentication
- **Environment Management**: Integrated state management across the app

### Design System
- **Color Schemes**: Comprehensive light and dark theme colors
- **Typography**: Consistent font usage and sizing
- **Components**: Reusable UI components (StatusCard, QuickActionButton)
- **Animations**: Smooth transitions and micro-interactions ready

## Project Structure

```
IOS/Joury/Joury/
├── Core/                        # Core functionality
│   ├── Config/
│   │   └── AppConfig.swift     # App configuration and constants
│   ├── Theme/
│   │   └── ThemeManager.swift  # Theme management system
│   ├── Localization/
│   │   └── LocalizationManager.swift  # Multi-language support
│   └── Networking/
│       └── NetworkManager.swift # HTTP client and API layer
├── Features/                    # Feature modules (to be implemented)
│   ├── Authentication/         # Google OAuth + Guest login
│   ├── Journal/               # AI-powered journaling
│   ├── Habits/                # Habit tracking
│   ├── Focus/                 # Focus sessions
│   └── Analytics/             # Data insights
├── Shared/                      # Shared components (to be implemented)
│   ├── Components/            # Reusable UI components
│   ├── Extensions/            # Swift extensions
│   └── Utilities/             # Helper functions
├── JouryApp.swift              # Main app entry point
└── ContentView.swift           # Demo main view
```

## Development Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ target
- macOS 14.0+ for development

### Running the App
1. Open `Joury.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press Cmd+R to build and run

### Key Features Demo
The current build demonstrates:
- **Theme Switching**: Tap "Change Theme" to cycle between light, dark, and auto modes
- **Language Toggle**: Switch between Traditional Chinese and English
- **Network Status**: Real-time network connectivity monitoring
- **System Integration**: Proper environment object management

## Technical Highlights

### Architecture Patterns
- **MVVM**: Clean separation of view and business logic
- **Dependency Injection**: Environment objects for shared state
- **Reactive Programming**: Combine framework for state management
- **Protocol-Oriented**: Extensible and testable design

### Core Technologies
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **URLSession**: Native HTTP networking
- **UserDefaults**: Local preferences storage
- **Keychain**: Secure credential storage (ready for implementation)

## Next Steps

### Immediate (Week 3-4)
- [ ] Implement Google OAuth authentication
- [ ] Add guest login mode
- [ ] Create basic navigation structure
- [ ] Implement local data persistence

### Short Term (Week 5-8)
- [ ] AI chat interface for journaling
- [ ] Habit tracking UI and logic
- [ ] Focus timer with virtual rooms
- [ ] Data synchronization with backend

### Medium Term (Week 9-12)
- [ ] Advanced analytics dashboard
- [ ] Rich media support (photos, voice)
- [ ] Notification system
- [ ] Widget and shortcuts integration

## Design Philosophy

The app follows these design principles:
- **Simplicity**: Clean, minimal interface focusing on content
- **Warmth**: Gentle colors and friendly interactions
- **Accessibility**: VoiceOver support and dynamic type
- **Performance**: Smooth animations and responsive UI
- **Privacy**: Local-first approach with optional cloud sync

## Contributing

When adding new features:
1. Follow the modular architecture
2. Add proper localization keys
3. Support both light and dark themes
4. Write unit tests for business logic
5. Update documentation

## Build Configuration

- **Debug**: Local development with logging enabled
- **Release**: Production build with optimizations
- **Feature Flags**: Toggle functionality based on build configuration

---

*This project is part of the Joury suite - an AI-powered personal growth platform.*
