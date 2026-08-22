# SimpleOpenVPN

SimpleOpenVPN is an Omarchy bar widget for running a single OpenVPN tunnel from the Omarchy shell. It provides a compact status icon, a profile picker, profile-specific credentials, connect/disconnect controls, live tunnel details, and recent OpenVPN log output.

The plugin is intentionally small: it does not manage NetworkManager VPN profiles, systemd services, or multiple concurrent tunnels. It is built for users who already have `.ovpn` or `.conf` files and want a direct bar control for them.

## Features

- Add `.ovpn` or `.conf` profiles with a graphical file picker
- Remember profiles across restarts
- Save login credentials per profile file
- Connect or disconnect from the bar
- Right-click the bar icon for quick connect/disconnect
- Show active tunnel interface, IPv4 address, and traffic counters
- Show recent OpenVPN log lines inside the panel
- Keep profile state under `~/.local/state`

## Requirements

SimpleOpenVPN is designed for Omarchy and its Quickshell-based shell.

Install these packages before enabling the plugin:

```sh
omarchy pkg add openvpn jq zenity
```

It also uses tools that are normally present on Omarchy or Arch Linux:

- `pkexec`
- `ip`
- `ps`
- `find`
- `awk`
- `grep`
- `sed`
- GNU coreutils

## Install

Install dependencies:

```sh
omarchy pkg add openvpn jq zenity
```

Add and enable the plugin:

```sh
omarchy plugin add https://github.com/diogogc/simple-openvpn.git --enable
```

Move it to the right side of the bar if needed:

```sh
omarchy bar move io.github.diogogc.simple-openvpn --section right
```

You can also use the included installer from a checked-out copy:

```sh
./install.sh
```

`omarchy plugin add` does not run plugin install hooks or privileged setup. The installer script is only a convenience wrapper that installs packages first and then calls `omarchy plugin add`.

## Usage

Click the SimpleOpenVPN bar icon to open the panel.

Use **Add Profile** to select an OpenVPN `.ovpn` or `.conf` file. The selected file is remembered as a profile and becomes the active profile.

Enter your VPN username and password, then click **Save for Profile**. Credentials are linked to the selected profile path, so switching profiles also switches the saved credentials.

Use the switch in the panel to connect or disconnect. You can also right-click the bar icon to toggle the VPN without opening the panel.

## State and Credentials

SimpleOpenVPN stores persistent user state here:

```text
~/.local/state/omarchy-openvpn/
```

Profile-specific credentials are stored as `0600` files under:

```text
~/.local/state/omarchy-openvpn/auth/
```

Runtime files are stored under:

```text
/tmp/omarchy-openvpn-<uid>/
```

The runtime auth file is removed when the tunnel is disconnected. Saved per-profile credentials remain until you clear them from the panel or delete the state directory.

## Privilege Model

Omarchy plugins run inside the unsandboxed Omarchy shell with your user permissions. SimpleOpenVPN only escalates for OpenVPN start and stop operations, using `pkexec`.

When connecting, the plugin runs OpenVPN with:

- `--config <profile>`
- `--writepid <runtime pid file>`
- `--status <runtime status file> 5`
- `--auth-user-pass <runtime auth file>` when saved credentials exist

Review the plugin code before enabling it, especially if installing from a fork.

## Development

The plugin follows the Omarchy marketplace bar-widget structure:

```text
manifest.json
BarWidget.qml
Panel.qml
OpenVpnService.qml
scripts/
  openvpn-ctl
  openvpn-lib
```

Validate the manifest:

```sh
omarchy plugin validate .
```

If `qmllint` is available on your system, lint the QML files:

```sh
qmllint -I "$OMARCHY_PATH/shell" BarWidget.qml Panel.qml OpenVpnService.qml
```

During local development, copy or keep the repo at:

```text
~/.config/omarchy/plugins/io.github.diogogc.simple-openvpn/
```

Then rescan and enable:

```sh
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.diogogc.simple-openvpn --section right
```

## Troubleshooting

If the widget does not appear, validate and rescan:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.diogogc.simple-openvpn
omarchy-shell shell rescanPlugins
```

If a QML change does not appear immediately, restart the shell:

```sh
omarchy restart shell
```

If connecting fails, open the panel and inspect **Recent Log**. You can also read the full runtime log:

```sh
tail -n 100 /tmp/omarchy-openvpn-$(id -u)/openvpn.log
```

If credentials are wrong for a profile, select that profile, click **Clear Auth**, then save the credentials again.

## Remove

Remove the plugin:

```sh
omarchy plugin remove io.github.diogogc.simple-openvpn
```

Remove saved profiles and credentials:

```sh
rm -rf ~/.local/state/omarchy-openvpn
```

## License

MIT
