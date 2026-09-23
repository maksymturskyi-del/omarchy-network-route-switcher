# Omarchy Internet Route Switcher

Omarchy Shell plugin and CLI helper for choosing which NetworkManager connection provides the preferred default route: Ethernet or Wi-Fi.

The plugin is based on Omarchy's built-in network panel and adds an **INTERNET ROUTE** control. Wi-Fi and Ethernet connections stay connected, so their local network routes remain available.

## Modes

| Mode | Behavior |
| --- | --- |
| `Auto` | Ethernet gets route metric 100 and Wi-Fi gets 600. Either can provide a default route; Ethernet is preferred. |
| `Ethernet` | Ethernet gets metric 100. Wi-Fi is marked `never-default`, so it remains available for LAN access without supplying the default route. |
| `Wi-Fi` | Wi-Fi gets metric 50 and Ethernet gets 2000. Both connections remain eligible to supply a default route, with Wi-Fi preferred. |
| `Both` | New connections are distributed across Ethernet and Wi-Fi. Each connection keeps using its selected path for replies. This does not combine the links for one download. |

The settings are applied to **all saved Ethernet and Wi-Fi NetworkManager connection profiles**. Select `Auto` to restore the defaults used by this tool. Existing custom route metrics or `never-default` settings on those profiles will be replaced.

## Requirements

- Omarchy Shell with the plugin system and `omarchy` CLI
- NetworkManager with `nmcli`
- `nftables`, `iproute2`, and `pkexec` for `Both`
- Bash

## Install

From a clone of this repository, run:

```bash
./install.sh
```

The installer copies the CLI to `~/.local/bin/`, installs the root-owned routing helper and NetworkManager dispatcher, validates the plugin, installs it from GitHub as `maksymturskyi-del.network-route-switcher`, enables it, and restarts Omarchy Shell. `sudo` is required during installation. Selecting `Both` asks Polkit to authorize the routing helper. Make sure `~/.local/bin` is on your `PATH` to use the CLI.

To install the plugin through Omarchy's Git-based plugin manager, then install the CLI and privileged helper without adding the plugin a second time:

```bash
omarchy plugin add https://github.com/maksymturskyi-del/omarchy-network-route-switcher.git --enable
```

Then run the installer with plugin installation skipped:

```bash
./install.sh --skip-plugin
```

## CLI

```bash
omarchy-internet-route          # Show the selected mode
omarchy-internet-route Auto
omarchy-internet-route Ethernet
omarchy-internet-route Wi-Fi
omarchy-internet-route Both
```

The mode is stored in `~/.config/omarchy/network-route.mode`. NetworkManager profile changes require NetworkManager and may be re-applied when a connection reconnects.

## Keyboard controls

The added route row supports the panel's existing navigation: `j`/`k` to move between sections, `h`/`l` to select a mode, and `Enter`/`Space` to apply it.

## Notes

- This changes NetworkManager profile settings for both IPv4 and IPv6.
- `Both` spreads new flows across two connected uplinks using connection tracking and policy routing. It requires an IPv4 gateway on both links. IPv6 is balanced when both links have IPv6 gateways. A third default route (such as a VPN tunnel) causes `Both` to refuse activation.
- `Both` has an optional `Manual` policy in the panel. Its default list shows apps with open windows, grouped by executable; routing a group moves all matching instances. The Advanced · PID view lists those apps first by PID, followed by the user's other processes. Existing connections keep their original path until the app reconnects. `Auto` continues to balance new flows.
- The process picker filters by name (and by PID in Advanced mode) inside a bounded list. Polkit keeps an active-session admin authorization briefly (typically five minutes) for route changes instead of prompting for every click.
- `Both` does not aggregate bandwidth for one flow; separate connections may use different uplinks.
- This repository includes a modified copy of Omarchy's network panel. See [NOTICE](NOTICE) for upstream attribution and license information.
- This is an independent community plugin and is not affiliated with or endorsed by Omarchy.

## License

MIT. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
