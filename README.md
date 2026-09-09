# Ashworld for PortMaster - experimental 0.1.0

ARM64 Linux handheld adaptation of the supplied Windows/GOG Ashworld 1.8.1b build. Follows the Gunslugs port method (https://github.com/ronaxdevil/gunslug_port) and the local Gunslugs 2 and Residual Java hosts. The original game is kept unchanged in ashworld.dat; this file is a Java archive despite its extension.

## Requirements and device support

Use a purchased copy of the supported build, ARM64 Linux firmware, working PortMaster, and compatible graphics drivers. Targets include RG34XX SP on muOS, R36S with 64-bit firmware, and other ARM64 Anbernic XX handhelds. This package does not support 32-bit firmware. Device names alone do not establish compatibility.

The launcher uses PortMaster's Java 17 and Westonpack runtimes. The bundled ARM64 GLFW/OpenAL libraries need GLIBC 2.27; OpenAL additionally needs GLIBCXX_3.4.22 / CXXABI_1.3.9. The firmware/runtime environment must provide these. Tests performed on desktop are documented in VALIDATION.md; physical handheld testing remains required.

## Install

Choose your ZIP:

- **ashworld-byo-data.zip**: extract into the firmware's ports directory, then copy your own ashworld.dat into ashworld/ashworld.dat.
- **ashworld-private-portmaster.zip**: contains this owner's supported game archive; extract into the ports directory. Keep this ZIP private.

For muOS, the additional **ashworld-private-muos.zip** is arranged for extraction to the SD-card root: Ashworld.sh goes in roms/PORTS and the ashworld directory goes in ports. Keep it private too. The equivalent manual layout is /roms/PORTS/Ashworld.sh plus /ports/ashworld. Standard PortMaster layouts keep Ashworld.sh beside the ashworld directory.

Launch Ashworld from Ports. Missing Java 17 / Westonpack runtimes are requested through PortMaster and require a connection to install. Steam integration, cloud saves, desktop news and newsletter popups are unavailable; the host uses local offline play.

## Prepare data on the handheld

No conversion or asset extraction is needed. Copy ashworld.dat directly from your owned Windows installation to the handheld's ashworld directory. First launch verifies it locally. Neither ashworld.exe nor the Windows jre directory is needed. The handheld cannot generate the commercial game data without an owned copy or run the Windows installer through this port.

Supported archive: **ashworld.dat**, 28,903,869 bytes, SHA256:

`672f2ba91677d2279c1a630255eece0d09fbc9f0061b6323514689b23217446f`

Other builds are rejected until their compatibility is checked.

## Controls

| Handheld | Original keyboard action |
|---|---|
| D-pad / left stick | Move / navigate (arrow keys) |
| A / R2 | Action / attack / confirm (X) |
| B / R1 | Activate / interact (Z) |
| X | Inventory (Tab) |
| Y | Quick melee (F) |
| L1 | Map (F1) |
| L2 | Title-screen options (O) |
| Start / Select | Pause / back / skip intro (Escape) |

Keep the original keyboard defaults or edit ashworld.gptk to match changes. PortMaster supplies controller identification and its standard exit shortcut. Prefer the game's save/quit option before exiting.

## Display and speed

Automatic display selection uses the firmware's oriented width and height. Supported output sizes include:

- 640x480: RG35XX-family, RG40XX and R36S displays.
- 720x480: RG34XX / RG34XX SP.
- 720x720: RG CubeXX.
- 1024x768: TrimUI Brick.
- 1280x720: TrimUI Smart Pro.

These are display targets, not hardware test certifications. Other dimensions from 160 to 8192 pixels are accepted. The host preserves the original 16:9 desktop view, with black borders on narrower screens; it extends the view on wider screens. It restores the viewport adapter each frame because the bundled window backend resets graphics state.

If automatic sizing is wrong, put one line such as 720x480 in ashworld/resolution.txt. Use auto or remove that file to restore detection. ASHWORLD_RESOLUTION overrides it. The launcher also supports ASHWORLD_PORTMASTER and ASHWORLD_DATA_DIR when firmware uses custom locations.

An independent monotonic frame limiter caps updates at 60 per second, matching the original Windows launcher. No catch-up updates run after a pause or stall. Slower devices may still run below 60 FPS.

## Saves and troubleshooting

The host redirects settings and the original svg1 save file into ashworld/saves. Back up the complete saves directory before updates. Cache goes in ashworld/cache; launch output goes in ashworld/log.txt. Host shutdown saves settings; use the game's save/quit action for world progress. Do not depend on forced termination to save a session.

For a failed launch, retain log.txt and note the device, firmware/version and resolution. Check the archive fingerprint and PortMaster runtimes first. Native-library or graphics-driver failures need compatible firmware/runtime support.

## Build and prepare PortMaster ZIPs

Install Python 3.8+ and JDK 17+ on the build computer. From this source folder:

```sh
python tools/inspect_input.py /path/to/Ashworld
python tools/build.py --game-jar /path/to/Ashworld/ashworld.dat --jdk /path/to/jdk
python tools/verify_package.py
bash tests/verify_display.sh
```

PowerShell example:

```powershell
python tools/build.py --game-jar '../Ashworld/ashworld.dat' --jdk 'C:/Program Files/Java/jdk-26.0.2.1'
```

The --game-jar argument accepts the original .dat archive. Compilation uses the supplied game's classes, emits Java 8-compatible host bytecode, and requires no dependency downloads. Deployment uses Java 17. After a full build, documentation/launcher-only changes can be repackaged with `python tools/build.py --package-only`.

The dist directory contains BYO-data, private PortMaster, private muOS and source ZIPs plus SHA256SUMS.txt. The source ZIP excludes proprietary data, decompilation output, generated binaries and saves. Share only the source/BYO archives; private archives contain the commercial game.

## Release notes - 0.1.0

- Initial experimental Ashworld 1.8.1b ARM64 PortMaster host.
- Uses the unmodified original ashworld.dat and its Linux ARM64 libraries.
- Offline startup, mapped controls and separate local saves.
- Five common handheld display sizes, aspect-preserving scaling and a 60 Hz update cap.
- Java 17 / Westonpack launcher, muOS layout, public BYO and source packages.
- Physical handheld graphics, audio, controls, performance and suspend/resume still need testing.

Host and adapted launcher licensing is in LICENSE. The original game and bundled third-party libraries retain their own licenses.
