# System Pills (`bit-dev.system-pills`)

A lightweight, modern Omarchy shell bar widget and background service displaying CPU, memory, and GPU usage pills.

## Features

- **CPU Usage**: Real-time CPU utilization percentage calculated from `/proc/stat`.
- **Memory Usage**: Real-time memory utilization percentage calculated from `/proc/meminfo`.
- **GPU Usage**: Optional GPU utilization percentage queried via `nvidia-smi` (hidden or inactive if unavailable).
- **Customizable**: Configurable refresh intervals, individual accent colors for each pill, and adjustable tint opacity.
- **Efficient**: Efficient polling service with shared background timer and low resource overhead.

## Installation

Install directly using the Omarchy CLI:

```bash
omarchy plugin add https://github.com/Crayonan/omarchy-system-pills.git --enable
```

If you prefer to install without enabling immediately:

```bash
omarchy plugin add https://github.com/Crayonan/omarchy-system-pills.git
omarchy plugin enable bit-dev.system-pills --section left
```

## Removal

To disable the widget from the status bar:

```bash
omarchy plugin disable bit-dev.system-pills
```

To completely uninstall and delete the plugin files:

```bash
omarchy plugin remove bit-dev.system-pills
```

## Configuration

Settings can be customized via Omarchy bar widget configuration or in `~/.config/omarchy/shell.json`:

| Setting | Type | Default | Description |
|---|---|---|---|
| `refreshIntervalSec` | integer | `3` | Polling interval in seconds (1–60s) |
| `cpuAccent` | string (hex color) | `#F59E0B` | Accent color for the CPU pill |
| `memoryAccent` | string (hex color) | `#22C55E` | Accent color for the Memory pill |
| `gpuAccent` | string (hex color) | `#8B5CF6` | Accent color for the GPU pill |
| `pillOpacity` | number | `0.24` | Background tint opacity (0.08–0.85) |

## Dependencies

- **Linux Procfs**: `/proc/stat` and `/proc/meminfo` (standard Linux kernel pseudo-filesystem).
- **Optional**: `nvidia-smi` (part of NVIDIA proprietary drivers) for GPU utilization monitoring. If not present, the GPU pill remains disabled gracefully without errors.

## License

This project is licensed under the [MIT License](LICENSE).
