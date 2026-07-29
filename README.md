# Ghita PPT Converter - Flutter PowerPoint Creator

A Flutter application that allows you to create PowerPoint presentations with HTML content, advanced animations, and AI-powered code generation.

## Features

1. **HTML to PPT Conversion**: Write custom HTML/CSS for slides, convert to PowerPoint format
2. **Enhanced Effects**: Advanced animation system with visual preview
3. **AI Assistant**: Chat interface to generate presentation HTML code using OpenAI API
4. **Windows Desktop Support**: Native Windows application

## Project Structure

```
lib/
├── main.dart                   # Application entry point
├── screens/
│   ├── home_screen.dart        # Main navigation screen
│   ├── html_to_ppt_screen.dart # HTML conversion interface
│   ├── ai_chat_screen.dart     # AI chat integration
│   └── effects_screen.dart     # Animation effects panel
├── providers/
│   ├── app_provider.dart       # App state management
│   ├── presentation_state.dart # Presentation data model
│   ├── ai_provider_manager.dart # Multi-provider AI manager
│   └── config_service.dart      # Configuration persistence
└── services/
    └── ppt_generator.dart      # PowerPoint generation logic
assets/
├── templates/                  # Presentation templates
├── themes/                     # Theme configurations
├── images/icons/               # Icons and graphics
└── config/                     # Configuration files
    └── providers.json          # AI provider configuration
