# Changelog

All notable changes to the Lumetric Corrector project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-04-23

### Added
- Initial release of Lumetric Corrector
- Comprehensive color correction and grading tools:
  - Basic corrections: Exposure, Contrast, Brightness
  - Tone controls: Highlights, Shadows, Whites, Blacks
  - Color balance: Temperature, Tint, Saturation, Vibrance
  - Advanced color grading with RGB control for shadows, midtones, and highlights
- 25+ Professional presets divided into three categories:
  - Mood presets (Cinematic, Teal & Orange, Vintage Film, etc.)
  - Era presets (80s Retro, 90s VHS, Sepia Tone, etc.)
  - Color style presets (Cyberpunk, Forest Green, Desert Heat, etc.)
- Additional effects:
  - Vignette with adjustable amount, radius, and feathering
  - Film grain with controls for amount and grain size
- Multi-language support with English and German localization
- Real-time preview capabilities

### Technical Features
- Optimized shader code for high performance
- Compatible with OBS Studio 30.0+
- Cross-platform support (Windows, macOS, Linux)
- GPU-accelerated processing for efficient rendering

## [1.1.0] - 2025-04-25

### Changed
- Performance-Optimierung: Shader-Parameter werden nur noch gesetzt, wenn sich der Wert geändert hat (reduziert GPU-Load und verbessert die Effizienz).
- Zeitsensitive Aktualisierung der Filmkorn-Animation durch Timer.
- Verbesserte Fehlerbehandlung und Debug-Logging während des Renderings und beim Laden von Shadern.
- Verbesserte Parameterstruktur und Initialisierung für mehr Robustheit.

### Fixed
- Lua-Syntaxfehler in den Parameter-Update-Blöcken beseitigt.
- OBS-API-Aufrufe (gs_effect_set_float, gs_effect_set_texture) korrekt über das obs-Modul eingebunden.
- Kompatibilität mit aktuellen OBS Studio Lua-Standards sichergestellt.

### Internal
- Code-Refactoring und bessere Lesbarkeit.
- Vorbereitung für weitere Optimierungen und Features.
