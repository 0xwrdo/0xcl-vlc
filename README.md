# 0xcl Modern VLC – Windows build

Your uploaded `.msi` was a **Linux** package (ELF binary + `.so` plugins) with an MSI-looking header, so Windows could never run it.
This folder is the same app rebuilt as a real Windows project.

* `qml/` – the 17 QML files + 2 PNGs **recovered unchanged from your binary** (your exact UI).
* `src/` – C++ backend written from scratch to match what the QML calls
  (`playerController`, `RealVideoSurface`, `playbackStats`, `audioVisualizer`, `ambientSampler`,
  `mediaLibraryModel`, `networkServerModel`). No X11/GLX – video is drawn through libvlc video callbacks
  into a Qt Quick texture, so it works on Windows (and still on Linux/macOS).
* `packaging/` – Inno Setup (`.exe` installer) and WiX v4 (`.msi`).
* `.github/workflows/build-windows.yml` – builds everything on a Windows runner and uploads the installers.

## Easiest: let GitHub build it
1. Push this folder to a GitHub repo.
2. Actions -> "Build Windows installer" -> Run workflow.
3. Download the `0xcl-windows` artifact: `0xcl-modern-vlc-setup.exe` and `0xcl-modern-vlc.msi`.

## Build locally on Windows
Needs: Visual Studio 2022 (C++), Qt 6.5+ (MSVC 64-bit), CMake, Ninja, and the VLC 3.0.x win64 **zip**
(https://get.videolan.org/vlc/3.0.21/win64/) unzipped somewhere.

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DVLC_SDK_DIR=C:/path/to/vlc-3.0.21
    cmake --build build
    mkdir dist && copy build\0xcl.exe dist\
    copy C:\path\to\vlc-3.0.21\libvlc*.dll dist\
    xcopy /E /I C:\path\to\vlc-3.0.21\plugins dist\plugins
    windeployqt --release --no-translations --qmldir qml dist\0xcl.exe
    dist\0xcl.exe movie.mkv

Then `iscc packaging\0xcl.iss` for the installer.

## Known limits (honest list)
* The C++ side is a reconstruction. I could not compile it in my sandbox (no Qt / Windows toolchain), so expect to fix a few compile errors on the first build.
* Video is software-decoded (`--avcodec-hw=none`, same as the original) and copied per frame; fine for 1080p, heavy for 4K.
* Audio visualizer is animated randomly (the original did the same, no real FFT). Buffer health is approximate. Colour space label is a guess from resolution.
* Installers are unsigned, so SmartScreen will warn until you code-sign.
