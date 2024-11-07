# kluster - OKD install script

The kluster script is a bash script that simplifies the process of installing and configuring an OKD (OpenShift Kubernetes Distribution) cluster. It automates the download of necessary tooling, creation of ignition configs, and generation of disk images for different node types.

- Automatic download and extraction of OKD tooling (openshift-install, oc)
- Generation of ignition files for single-node and multi-node deployments
- Creation of disk images for bootstrap, master, and worker nodes
- Overlay customization of ignition files using Butane
- Bash completion support for command-line arguments

## Install
```bash
# Clone the repo to a location in your $PATH
git clone git@github.com:AlexStorm1313/kluster.git ~/.local/bin/kluster 
```
```bash
# Make the script executable
chmod +x ~/.local/bin/kluster/kluster
```

## Getting started
Run the `kluster init` command to create cluste configuration directory

```bash
├── install/				# Installation configuration files
	├── manifests/			# Kubernetes YAML (Optional)
	├── openshift/			# Butane YAML (Optional)
	└── install-config.yaml	# OKD install configuration
├── tooling/				# Version-specific OKD tools (Optional)
├── output/					# Ignition files and images/ISO (Optional)
├── overlay/				# Butane overlay customization
	└── bootstrap.yaml		# Butane Node customization (Optional)
└── .env					# Enviroment variables
```

The script requires a `.env` file in the same directory with the following environment variables:

- `OKD_VERSION`: The version of OKD to be installed (e.g., `4.15`)
- `HOST`: The hosting type of the target system (e.g. `metal`, `live`, `aws`)
- `ARCH`: The architecture of the target system (e.g., `x86_64`)
- `IMAGE`: The CoreOS image to be used (e.g. `raw.xz`, `iso`)
- `DISK_DEVICE`: The block device to be used for disk image creation (e.g., `/dev/loop0`)


## Available Commands
```bash
help                         	   # Show this help message
init                              # Initialize the current directory as the configuration directory
get
	tooling                       # Download and extract OKD tooling for the specified version
	image                         # Download CoreOS image (currently unimplemented)
create
	single-node-ignition-config   # Generate ignition config for single-node deployment
	ignition-configs              # Generate ignition configs for multi-node 
	overlay                       # Create custom ignition overlay from Butane configs
	manifests                     # Generate and customize OKD manifests
	image
		bootstrap                 # Create bootstrap node disk image
		master                    # Create master node disk image
		worker                    # Create worker node disk image
openshift-install            	  # Direct access to openshift-install command
oc                           	  # Direct access to oc command
```
## Usage Examples

### Single Node Installation

```bash
# Initialize current directory
kluster init
# Download tooling
kluster get tooling
# Create the ignition configuration
kluster create single-node-ignition-config
# Create node images
kluster create image bootstrap
# Wait for bootstrap and installation
kluster openshift-install wait-for bootstrap-complete
kluster openshift-install wait-for install-complete
```

### Multi-Node Installation
```bash
# Initialize current directory
kluster init
# Download tooling
kluster get tooling
# Create the ignition configuration
kluster create ignition-configs
# Create node images
kluster create image bootstrap
kluster create image master
kluster create image worker
# Wait for bootstrap and installation
kluster openshift-install wait-for bootstrap-complete
kluster openshift-install wait-for install-complete
```

## Contributing

Feel free to submit issues and pull requests to improve this installation process.