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
- Performance optimisation: shader parameters are now updated only when their value changes, reducing GPU load and improving efficiency.
- Time-synchronised film-grain animation driven by a timer.
- Improved error handling and debug logging during rendering and shader loading.
- Refined parameter structure and initialisation for greater robustness.

### Fixed
- Resolved Lua syntax errors in parameter-update blocks.
- Correctly integrated OBS API calls (`gs_effect_set_float`, `gs_effect_set_texture`) via the `obs` module.
- Ensured compatibility with current OBS Studio Lua standards.

### Internal
- Code refactoring for improved readability and maintainability.
- Preparations for future optimisations and features.

## [1.1.1] - 2025-05-06

### Fixed
- Restored Windows (Direct3D/HLSL) visibility by guarding GLSL intrinsic replacements with `#ifdef GS_PLATFORM_OPENGL`.
- Ensured macOS (OpenGL/GLSL) support remains functional.

### Added
- Platform-specific intrinsic mapping logic for true cross-platform compatibility.

## [1.1.2] - 2025-05-08

### Added
- Highlight Fade and Shadow Fade sliders for creative looks like film bleaching effects
- Adjustable vignette shape control allowing oval/rectangular shapes instead of just circular
- Animated film grain that creates a more natural and realistic film look

### Improved
- Film grain now uses dual-noise sampling for smoother animation
- Better time-based seed distribution for grain animation
- UI organization with logical placement of new controls
