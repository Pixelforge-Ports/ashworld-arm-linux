# Input audit

Inventoried all 128 supplied files using SHA256, size and signature. Checked CRCs and every member of ashworld.dat (3,213 entries) and webcache.zip (9 entries). Private detailed reports are generated under build/audit by tools/inspect_input.py.

config.json launches com.orangepixel.ashworld.desktop.Main with -Xmx1024M. The desktop launcher identifies version 1.8.1b, uses libGDX 1.12.1 and a 60 FPS cap with a 1280x720 window. The handheld host tests use a smaller 256 MB heap. Short tests cannot establish memory needs throughout the entire game.

The .dat archive contains Java game code, assets and Linux ARM64/ARM32 native libraries alongside Windows and other platform libraries. Windows executable, JRE, uninstaller, GOG metadata and shortcuts are not used. No supplied executable was run.

Inspected startup, frame timing, framebuffer handling, input bindings, optional social/news integration, settings and world-save code. Binary assets and unrelated vendor classes were inventoried and integrity checked, not individually reverse engineered. Decompiled classes were used only for private local inspection and are excluded from distribution.
