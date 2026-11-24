# FIU Luna2 Pitbull

Software repository for the FIU Luna2 Pitbull robotics project.

## Overview

This project targets a ROS 2 Jazzy-based robot stack running on Ubuntu/Linux (Jetson Nano). The repository currently includes project documentation and startup scripts for communication/visualization tooling.

## Architecture

The software architecture diagram in `docs/Pitbull Software Architecture.drawio` identifies the following components and data flow:

- **Laptop: Mission Control** running **Lichtblick Visualizer** and a **Gamepad Controller**.
- **Nvidia Jetson Nano: Brain** running **ROS 2 Jazzy** on **Ubuntu Linux** (diagram also shows a Docker container).
- **Foxglove Bridge (WebSocket)** for topic communication/visualization between the laptop and Jetson.
- **ROS nodes on Jetson**: LiDAR node (`/lidar/points`), camera nodes (`/camera_1/image_raw`, `/camera_2/image_raw`, `/camera_3/image_raw`), and CAN-to-ROS/socketcan nodes (`/to-can-bus`, `/from-can-bus`).
- **Motor/control path**: SocketCAN/`ros2_socketcan` node over physical GPIO/wiring through a CAN transceiver board to a **TI F28P55X microcontroller** running motor driver code.

> Note: The diagram is the source for the high-level architecture above; implementation details may evolve as the codebase grows.

## Repository Layout (TBD)

```text
.
├── docs/
│   └── Pitbull Software Architecture.drawio
├── scripts/
│   └── standup-communication-bridge.sh
├── LICENSE
└── README.md
```

## Requirements

For the Foxglove bridge startup script:

- ROS 2 Jazzy installed and sourceable (`/opt/ros/jazzy/setup.bash`), or an already-sourced Jazzy environment
- `ros2` CLI available
- `ros-jazzy-foxglove-bridge` installed in the active ROS environment

## Scripts

### `scripts/standup-communication-bridge.sh`

Starts the Foxglove bridge with project defaults and performs preflight checks before launching.

**Default behavior:**

```bash
./scripts/standup-communication-bridge.sh
```

Defaults:
- Address: `100.104.101.59` (override with `FOXGLOVE_ADDRESS` or arg 1)
- Port: `8765` (override with `FOXGLOVE_PORT` or arg 2)

**Usage:**

```bash
./scripts/standup-communication-bridge.sh [address] [port] [extra ros2 launch args...]
```

**Examples:**

```bash
./scripts/standup-communication-bridge.sh
./scripts/standup-communication-bridge.sh 100.104.101.59 8765
FOXGLOVE_ADDRESS=0.0.0.0 FOXGLOVE_PORT=8765 ./scripts/standup-communication-bridge.sh
```

**Preflight checks performed by the script:**
- Tries to source `/opt/ros/jazzy/setup.bash` if `ROS_DISTRO` is unset
- Verifies `ros2` CLI is present and runnable
- Verifies `ROS_DISTRO=jazzy`
- Verifies `foxglove_bridge` package is discoverable (`ros2 pkg prefix foxglove_bridge`)
- Verifies the expected launch file exists

If a check fails, the script exits with an error and prints troubleshooting/install guidance.

## License

This project is licensed under the MIT License. See `LICENSE`.