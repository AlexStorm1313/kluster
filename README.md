# OKD Installation Tooling

This repository contains a Makefile to automate the process of creating and installing OKD (The Community Distribution of Kubernetes that powers Red Hat OpenShift) clusters. It supports both single-node and multi-node configurations.

## Prerequisites

- Podman
- sudo privileges
- Sufficient disk space (at least 16GB per node)
- `.env` file with required configuration (see Configuration section)

## Configuration

Create a `.env` file in the root directory with the following variables:

```env
OKD_VERSION=<version>      # The OKD version to install
WORKING_DIR=<dir>         # Working directory name
DISK_DEVICE=<device>      # Device path for disk images (e.g., /dev/loop0)
IMAGE_URL=<url>           # CoreOS image URL
```

## Directory Structure

```
.
├── tooling/              # Version-specific OKD tools
├── install/              # Installation configuration files
└── output/              # Generated files and images
```

## Available Commands

### Setup

- `make tooling`: Downloads and extracts the required OKD tools for the specified version

### Ignition Configuration

- `make single-node-ignition-config`: Creates ignition configuration for single-node deployments
- `make ignition-configs`: Creates ignition configurations for multi-node deployments

### Disk Image Creation

- `make bootstrap-image`: Creates a disk image with bootstrap configuration
- `make master-image`: Creates a disk image with master node configuration
- `make worker-image`: Creates a disk image with worker node configuration

### Installation Monitoring

- `make bootstrap-complete`: Waits for the bootstrap process to complete
- `make install-complete`: Waits for the entire installation process to complete

## Usage Examples

### Single Node Installation

```bash
# 1. Set up tooling
make tooling

# 2. Create single node ignition config
make single-node-ignition-config

# 3. Create bootstrap image
make bootstrap-image

# 4. Wait for installation to complete
make install-complete
```

### Multi-Node Installation

```bash
# 1. Set up tooling
make tooling

# 2. Create ignition configs
make ignition-configs

# 3. Create node images
make bootstrap-image
make master-image
make worker-image

# 4. Wait for bootstrap and installation
make bootstrap-complete
make install-complete
```

## Technical Details

- The Makefile uses Podman to run containers in privileged mode for certain operations
- Disk images are created as 16GB sparse files
- The process uses loop devices for image creation
- CoreOS installer is used to write the images

## Important Notes

1. This Makefile requires sudo privileges for disk operations
2. Make sure to have sufficient disk space available
3. The loop device specified in DISK_DEVICE should be available
4. Backup any important data before running disk operations

## Troubleshooting

If you encounter issues with loop devices:
1. Check if the device is already in use: `sudo losetup -a`
2. Manually detach if needed: `sudo losetup --detach /dev/loopX`

## Security Considerations

- The Makefile runs some commands with sudo privileges
- Containers are run in privileged mode
- Ensure proper security measures when handling ignition configs

## Contributing

Feel free to submit issues and pull requests to improve this installation process.