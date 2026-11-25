#!/usr/bin/env bash
# Exit immediately on errors, treat unset variables as errors, and fail pipelines if any command fails.
set -euo pipefail

# Launch the Foxglove bridge for remote visualization/debugging.
# Defaults match the project's standup communication configuration.
#
# Usage:
#   ./scripts/standup-communication-bridge.sh [address] [port] [extra ros2 launch args...]
#
# Environment variable overrides (used when positional args are omitted):
#   FOXGLOVE_ADDRESS=100.104.101.59 FOXGLOVE_PORT=8765 ./scripts/standup-communication-bridge.sh
#
# Examples:
#   ./scripts/standup-communication-bridge.sh
#   ./scripts/standup-communication-bridge.sh 100.104.101.59 8765

# Resolve the bind address: positional arg 1, then FOXGLOVE_ADDRESS env var, then project default.
ADDRESS="${1:-${FOXGLOVE_ADDRESS:-100.104.101.59}}"
# Resolve the port: positional arg 2, then FOXGLOVE_PORT env var, then project default.
PORT="${2:-${FOXGLOVE_PORT:-8765}}"

# Remove consumed positional args so remaining args can be forwarded to ros2 launch.
if [ "$#" -ge 2 ]; then
  # Both address and port were provided; drop them and keep any extra launch args.
  shift 2
elif [ "$#" -eq 1 ]; then
  # Only address was provided; drop it and keep any extra launch args.
  shift 1
fi

# Print a consistent error prefix to stderr for all preflight failures.
error() {
  printf 'Error: %s\n' "$*" >&2
}

# If ROS 2 is not already sourced, try the project's ROS 2 Jazzy install location.
if [ -z "${ROS_DISTRO:-}" ]; then
  # Source the Jazzy setup file if it exists to populate ROS environment variables.
  ros_setup="/opt/ros/jazzy/setup.bash"
  if [ -f "$ros_setup" ]; then
    # shellcheck source=/dev/null
    source "$ros_setup"
  fi
fi

# Verify the ros2 CLI is available before attempting any ROS-specific commands.
if ! command -v ros2 >/dev/null 2>&1; then
  # Report that ROS 2 is missing and tell the user where we looked.
  error "ROS 2 CLI ('ros2') was not found."
  printf 'Checked: PATH and /opt/ros/jazzy/setup.bash.\n' >&2
  printf 'Install ROS 2 Jazzy or source the setup file:\n' >&2
  printf '  source /opt/ros/jazzy/setup.bash\n' >&2
  exit 1
fi

# Confirm the ros2 CLI actually runs, catching broken/incomplete environments.
if ! ros2 --help >/dev/null 2>&1; then
  # Report that ros2 exists but is not functioning correctly.
  error "ROS 2 CLI ('ros2') was found but failed to run."
  printf 'Verify your ROS 2 installation and environment, then retry.\n' >&2
  exit 1
fi

# Ensure a ROS distro is active; package checks depend on a sourced ROS environment.
if [ -z "${ROS_DISTRO:-}" ]; then
  # Report missing distro context and show how to source ROS 2 Jazzy.
  error "ROS_DISTRO is not set; a ROS 2 environment does not appear to be fully sourced."
  printf 'Source the ROS 2 Jazzy setup file:\n' >&2
  printf '  source /opt/ros/jazzy/setup.bash\n' >&2
  exit 1
fi

# Ensure the active ROS distro is Jazzy, since this project targets Jazzy.
if [ "${ROS_DISTRO}" != "jazzy" ]; then
  # Report a distro mismatch and instruct the user to source Jazzy.
  error "Unsupported ROS_DISTRO '${ROS_DISTRO}'. This project requires ROS 2 Jazzy."
  printf 'Source the ROS 2 Jazzy setup file:\n' >&2
  printf '  source /opt/ros/jazzy/setup.bash\n' >&2
  exit 1
fi

# Check that the foxglove_bridge package is installed and discoverable in this ROS environment.
if ! PKG_PREFIX="$(ros2 pkg prefix foxglove_bridge 2>/dev/null)"; then
  # Report the missing package and provide the distro-specific apt install command.
  error "Required ROS 2 package 'foxglove_bridge' is not available in the current environment (ROS_DISTRO=${ROS_DISTRO})."
  printf 'Install it with:\n' >&2
  printf '  sudo apt install ros-%s-foxglove-bridge\n' "${ROS_DISTRO}" >&2
  printf 'After installing, source your ROS 2 environment and retry.\n' >&2
  exit 1
fi

# Build the expected launch file path from the installed package prefix.
LAUNCH_FILE="${PKG_PREFIX}/share/foxglove_bridge/launch/foxglove_bridge_launch.xml"
# Verify the launch file exists so ros2 launch does not fail with a less clear error.
if [ ! -f "${LAUNCH_FILE}" ]; then
  # Report an incomplete/corrupted package installation and suggest reinstalling.
  error "foxglove_bridge launch file is missing: ${LAUNCH_FILE}"
  printf 'The package appears incomplete. Try reinstalling it with:\n' >&2
  printf '  sudo apt install --reinstall ros-%s-foxglove-bridge\n' "${ROS_DISTRO}" >&2
  exit 1
fi

# Launch foxglove_bridge with resolved address/port and forward any extra user-provided launch args.
exec ros2 launch foxglove_bridge foxglove_bridge_launch.xml \
  address:="${ADDRESS}" \
  port:="${PORT}" \
  "$@"
