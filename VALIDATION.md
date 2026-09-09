# Validation - Ashworld 0.1.0

## Scope

All 128 supplied input files were inventoried and a final SHA256 comparison confirmed they were unchanged. Every member of ashworld.dat (3,213 entries) and webcache.zip (9 entries) passed CRC inspection. Windows executables and installers were not run.

Built with JDK 26 targeting Java 8 bytecode. Runtime tests use Windows Java 17.0.20.1, a 256 MB heap and SerialGC. These tests exercise the original game and desktop native libraries; they do not validate Linux ARM64 native loading or Weston/gl4es.

## Runtime tests

The input harness enters the title menu, generates the world, skips the intro with the original back key, moves and uses actions, advances the tutorial dialog and dismisses its map. Each completed resolution run must include at least 300 gameplay frames. It also asserts physical output dimensions, the actual GL viewport after every frame, elapsed time consistent with the 60 Hz update ceiling, and no logged runtime exceptions.

Target matrix: 640x480, 720x480, 720x720, 1024x768 and 1280x720. Screenshots and class-load logs are under build/resolutions. Viewport checks verify centered 16:9 output rather than relying on the window dimensions alone. The host restores its graphics adapter every frame because Lwjgl3Window.makeCurrent resets Gdx graphics state.

The save test uses Ashworld's own SaveGame/LoadGame methods, verifies the stored save's version, and a later process resumes the saved world through the normal continue menu. Settings and world saves use the desktop provider; the legacy libGDX preference fallback has a separate subfolder to avoid treating a settings directory as a file.

Initial exploratory tests exposed a tutorial map that needed a back-button press, the per-frame graphics reset and the preference-directory conflict on restart. Those findings were fixed before the final checks. The initial 9,000-frame exploratory run had only 272 gameplay frames and is not counted as a completed matrix test.

The data verifier was separately tested on a host-only classpath: it accepted the supplied ashworld.dat and rejected a deliberately unsupported test file before loading game classes.

## Final results

All five final runs passed without logged runtime exceptions. The actual GL viewport was checked on every frame; final framebuffer dimensions matched the requested screen size. Screenshots at 640x480, 720x720 and 1280x720 were visually reviewed.

| Output | Render frames | Gameplay frames | Seconds |
|---|---:|---:|---:|
| 640x480 | 1750 | 300 | 32.03 |
| 720x480 | 1750 | 300 | 31.63 |
| 720x720 | 1750 | 300 | 31.60 |
| 1024x768 | 1750 | 300 | 31.84 |
| 1280x720 | 1750 | 300 | 31.63 |

The final separate restart loaded the existing world through the continue menu, completed 300 gameplay frames and passed original save/readback verification in 12.58 seconds. No preference-directory warning remained.

## Package checks

Bash syntax and resolution helper tests cover the requested sizes, additional valid sizes, invalid input, config/environment precedence, CRLF config and automatic fallback. verify_package.py checks archive CRCs, executable shell permissions, LF line endings, required files, metadata syntax, exact private game data, public/source exclusions and SHA256 checksums.

## Reproduce

After building the host:

```sh
python tools/verify_resolutions.py --java /path/to/java17/bin/java --jdk /path/to/jdk --game-jar /path/to/Ashworld/ashworld.dat
```

Use the same test Java class with -Dashworld.testSave=true to enable original save/readback verification. Test output, profiles and decompilation stay in build and are excluded from all distributed archives. No test classes are included in ashworld-host.jar.

## Hardware work still required

No physical RG34XX SP, R36S or other handheld was connected. Linux ARM64 graphics/native loading, audio, real button mapping, suspend/resume, long-session memory and stability need testing on each firmware/device. The original launcher allows a 1 GB Java heap; short tests with 256 MB do not establish memory needs across the whole game. No full campaign or all vehicle/mission paths were tested. 32-bit firmware and store/cloud features are unsupported by this package.
