# Proportional cursor crossing for KWin

**English** · [Українська](README.uk.md)

This native Plasma Wayland effect preserves the cursor’s relative height when moving between side-by-side displays, or its relative horizontal position when moving between stacked displays. You can cross even from the part of a larger display’s edge where the cursor would normally stop. If several displays lie on the same side, the effect chooses the one closest to the crossing point.

Proportional crossing also works when moving a window between displays. KWin handles the cursor as usual when you resize a window, drag anything else with a mouse button held down, lock the session, or use an application that grabs or confines the pointer.

## Installing on Fedora

Run these commands from the project directory in your Plasma session as your regular user.

```bash
sudo dnf install libdnf5-plugin-actions gcc-c++ cmake extra-cmake-modules kwin-devel qt6-qtbase-devel qt6-qtdeclarative-devel kf6-kcoreaddons-devel libdrm-devel libepoxy-devel wayland-devel
./install.sh
```

Disable the effect with `./install.sh --disable` and enable it again with `./install.sh --enable`.

After DNF5 updates the `kwin` package, a systemd service automatically rebuilds the effect. The current session may use the previous build until your next Plasma login. At boot, the service checks the KWin version and whether the plugin is present, then rebuilds if needed. View the log with `journalctl -u kwin-relative-pointer-rebuild.service`.
