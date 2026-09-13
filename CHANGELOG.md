# Changelog

All notable changes to the Lumetric Corrector project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-09-13

Major rework: every control the shader supports is now in the UI, presets and
LUTs actually work, and the whole script is driven by one parameter table so
defaults, UI, update and shader can no longer drift apart.

### Added
- **Missing controls**: Brightness, Highlights, Shadows, Whites and Blacks sliders (the shader supported them since 1.0, the UI never exposed them)
- **Film grain is back**: animated, luminance-weighted grain with amount and size controls (removed in 2.0 because of stutter; now driven by a per-frame time uniform)
- **17 new presets** (47 in total, 5 categories): Bleach Bypass, Faded Shadows, Cross Process, Moody Blue, Warm Portrait, Day For Night, Night Enhancer, Forest Green, Desert Heat, Arctic Chill, 70s Film, 80s Retro, 90s VHS, … — every preset the README promised now exists
- **Presets apply instantly** when selected; "Apply again" and "Reset all settings" buttons
- **Look files**: save/load all color settings as JSON to share looks between scenes, profiles and machines
- **LUT export as PNG**: 512x512 grid compatible with the built-in OBS "Apply LUT" filter, in addition to 33³ .cube
- **LUT status line** in the UI shows the loaded cube size or the reason a file was rejected
- **English and German tooltips** for every control; the UI language follows the OBS locale
- Developer tooling in `dev/`: obslua mock + end-to-end test-suite, module unit tests, HLSL compile check via fxc

### Fixed
- **3D LUT loading was broken**: `.cube` files were passed to an image loader and the shader expected a 3D texture that was never created. LUTs are now parsed in Lua, converted to a 16-bit PNG atlas (cached in the OBS `plugin_config` folder) and sampled trilinearly from a 2D texture — works on Direct3D, OpenGL and Metal
- **Creative presets never applied their split toning** (values were written to keys that nothing read)
- **Presets leaked internal state** (`last_*`, `dirty`, `width`, `height`, …) into the scene file; these keys are removed automatically when an old scene is loaded
- **LUT export ignored most controls** and used a different exposure curve than the shader; the exporter now mirrors the shader's non-spatial pipeline 1:1 (verified against an independent reference implementation) and bakes a loaded `.cube` LUT into the export
- Vignette shape slider was read as an integer and only worked at 1.0
- Tint direction now matches its description (+ magenta, − green)
- Halation now only glows around highlights; bloom is thresholded and uses a 9-tap kernel instead of brightening the whole frame
- Highlights/Shadows/Whites/Blacks are weighted by luminance instead of per channel, so tone adjustments no longer shift hues
- Vibrance used Rec.601 luma while the rest of the pipeline used Rec.709
- Vignette/mask feathering used reversed `smoothstep` arguments (undefined in GLSL) and could divide by zero at feather 0
- `apply preset` ran the update callback twice; the filter reported a 0x0 size until its first tick; a missing filter target no longer leaves the frame black; nil-safety in render and button callbacks
- Uniforms are uploaded only when settings change (previously vectors were re-set every frame)

### Changed
- UI regrouped: Presets → Tone → Fade & Lift → White Balance → Color → Color Wheels → Split Toning → Creative Effects → Vignette → Mask (checkable group) → 3D LUT → Looks & LUT Export
- LUT strength defaults to 1.0 so a freshly selected LUT is visible immediately
- Presets no longer touch mask or LUT settings
- Script description uses the current version automatically

### Removed
- Dead preview-render code path and duplicate translation/log helpers

### Notes for existing scenes
All settings keys are unchanged; existing scenes load as before. Looks may differ slightly where the math was corrected (bloom, halation, tone weighting, tint sign).

## [2.2.0] - 2025-06-29

### Added
- **Cross-platform LUT Export**: Native file dialog for selecting LUT export location
  - Support for both Windows and macOS file systems
  - File extension validation and auto-completion
  - Default path to user's Documents folder

### Fixed
- **LUT Loading and Application**: Fixed broken LUT functionality
  - Implemented proper LUT image loading using gs_image_file API
  - Added texture initialization and shader parameter binding
  - Fixed LUT mix control to properly blend between original and LUT-graded image
  - Added cross-platform support for PNG and CUBE LUT formats
- **Critical Mask Rendering Bug**: Fixed black screen issue when using mask
  - Corrected vector type mismatch (vec4 → vec2) for mask position and size
  - Added safety clamps to prevent division by zero in mask size calculations
- **Mask Blending Logic**: Improved mask feathering and edge quality
  - Corrected alpha blending between masked and unmasked areas
  - Enhanced smoothstep implementation for better feather transitions
- **Error Handling**: Robust error handling for file operations
  - Safe file open/write operations with pcall wrappers
  - Detailed logging of success/failure states

### Changed
- **Performance**: Optimized shader parameter updates
- **UI**: Improved file dialog integration with sensible defaults
- **Logging**: Enhanced debug information for troubleshooting

## [2.0.0] - 2025-06-24

### Added
- **Split-Toning**: Separate color controls for shadows and highlights
- **Creative Effects**: New section with advanced visual effects
  - Sharpen: Local contrast enhancement using unsharp mask
  - Bloom: Soft glow effect on bright areas
  - Halation: Film-like reddish glow on highlights
- **10 New Creative Presets**:
  - Neo Noir: Dramatic B&W look with blue split-toning
  - Cyberpunk: Futuristic look with neon colors and bloom
  - Retro Film: Vintage film emulation with halation
  - Teal & Orange: Popular cinematic color contrast
  - Dreamy Bloom: Soft ethereal look with bloom effects
  - Crisp Clarity: Sharp, clear look with enhanced detail
  - Horror Atmosphere: Dark, ominous look for horror content
  - Pastel Dreams: Soft pastel colors with split-toning
  - Game Stream: Optimized look for gaming streams
  - Analog VHS: Retro VHS look with halation effects
- **3D LUT Support**: Load and apply 3D LUTs in CUBE or PNG format
- **Enhanced Documentation**: Improved usage instructions in script description

### Fixed
- Cross-platform shader compatibility issues
- Fixed uniform parameter size mismatch warnings
- Proper handling of texture dimensions across platforms
- Improved buffer_size handling for consistent texel calculations
- Fixed split-toning parameter handling with proper vec4 implementation
- Enhanced macOS compatibility with platform-specific shader error handling
- Implemented fallback to minimal shader for problematic platforms
- Secure shader creation with pcall wrappers on all platforms
- Forced shader parameter updates during each render pass for consistent behavior
- Optimized GLSL shader syntax for broader compatibility
- Implemented platform-specific texture sampling functions
- Added explicit GLSL version declarations for better compatibility

### Changed
- Refactored shader parameter handling for better cross-platform support
- Improved UI organization with new preset categories
- Enhanced error handling with pcall wrappers for all shader parameter setters
- Updated translations for all new features in English and German
- Added missing `update` function for UI settings synchronization
- Implemented immediate parameter updates for consistent real-time preview
- Added helper function `update_filter_from_settings` for consistent settings application
- Enhanced platform-specific debug outputs with detailed information
- Improved validation in all filter lifecycle functions
- Stabilized rendering pipeline across all platforms



## [1.3.1] - 2025-06-22

### Fixed
- Fixed: Restored macOS compatibility, slider changes now correctly affect the image
- Fixed: GLSL shader syntax error (`sampler2d` → `sampler2D`)
- Improved: Texture sampling function for macOS compatibility (`texture2D` instead of `texture` on OpenGL)

### Improved
- Enhanced platform detection and better debug logging
- More robust shader parameter validation
- Improved error handling during shader compilation

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
