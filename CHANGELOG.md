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
- Improved parameter structure and initialisation for greater robustness.

### Fixed
- Resolved Lua syntax errors in parameter-update blocks.
- Correctly integrated OBS API calls (`gs_effect_set_float`, `gs_effect_set_texture`) via the `obs` module.
- Ensured compatibility with current OBS Studio Lua standards.

### Internal
- Code refactoring for improved readability.
- Preparations for future optimisations and features.

## [1.1.1] - 2025-05-06

### Fixed
- Restored Windows (Direct3D/HLSL) rendering by wrapping GLSL intrinsic replacements with `#ifdef GS_PLATFORM_OPENGL`.
- Maintained macOS (OpenGL/GLSL) compatibility.

### Added
- Platform-specific intrinsic mapping logic enabling true cross-platform support.
