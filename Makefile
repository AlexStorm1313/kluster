.PHONY: tooling single-node-ignition-config ignition-configs bootstrap-image master-image worker-image bootstrap-complete install-complete

TOOLING_DIR=./tooling/$(OKD_VERSION)
INSTALL_DIR=./install
OUTPUT_DIR=./output/$(WORKING_DIR)/$(OKD_VERSION)

include .env

# Get OKD version specific tooling
tooling:
	mkdir -p $(TOOLING_DIR)

	# podman run --rm --privileged -v ./$(TOOLING_DIR):/data -w /data quay.io/openshift/origin-cli:latest oc adm release extract --tools registry.ci.openshift.org/origin/release-scos:$(OKD_VERSION)
	podman run --rm --privileged -v ./$(TOOLING_DIR):/data -w /data quay.io/openshift/origin-cli:latest oc adm release extract --tools registry.ci.openshift.org/origin/release:$(OKD_VERSION)
	
	rm $(TOOLING_DIR)/*rhel*.tar.gz
	
	tar zxvf $(TOOLING_DIR)/openshift-install-linux-*.tar.gz -C $(TOOLING_DIR)
	chmod +x $(TOOLING_DIR)/openshift-install
	tar zxvf $(TOOLING_DIR)/openshift-client-linux-*.tar.gz -C $(TOOLING_DIR)
	chmod +x $(TOOLING_DIR)/oc

# Download helper
_download:
	podman run --rm --privileged -v ./$(OUTPUT_DIR):/data -w /data quay.io/coreos/coreos-installer:release download --image-url $(IMAGE_URL)

# Download image
download-image:
	make _download HOST=metal IMAGE=raw.xz

# Download iso
download-iso:
	make _download HOST=live IMAGE=iso

# Ignition helper
_ignition:
	rm -rf $(OUTPUT_DIR)
	mkdir -p $(OUTPUT_DIR)

	cp $(INSTALL_DIR)/install-config.yaml $(OUTPUT_DIR)

	$(TOOLING_DIR)/openshift-install --dir=$(OUTPUT_DIR) create manifests

	for file in $(INSTALL_DIR)/openshift/*.yaml; do \
		podman run --rm --privileged -v $(INSTALL_DIR)/openshift:/data -v $(OUTPUT_DIR)/openshift:/openshift -w /data quay.io/coreos/butane:release --pretty --strict $$(basename $$file) -o /openshift/$$(basename $$file) ; \
	done

	cp -r $(INSTALL_DIR)/manifests/*.yaml $(OUTPUT_DIR)/manifests

# Create the SNO ignition
single-node-ignition-config:
	make _ignition
	
	$(TOOLING_DIR)/openshift-install --dir=$(OUTPUT_DIR) create single-node-ignition-config
	mv $(OUTPUT_DIR)/bootstrap-in-place-for-live-iso.ign $(OUTPUT_DIR)/bootstrap.ign

# Create the ignition configs
ignition-configs:
	make _ignition

	$(TOOLING_DIR)/openshift-install --dir=$(OUTPUT_DIR) create ignition-configs

# Generic image helper
_image:
	touch $(OUTPUT_DIR)/$(IMAGE_VARIANT).img
	truncate -s 16G $(OUTPUT_DIR)/$(IMAGE_VARIANT).img
	
	sudo losetup --detach $(DISK_DEVICE) || true
	sudo losetup -P $(DISK_DEVICE) $(OUTPUT_DIR)/$(IMAGE_VARIANT).img
	
	echo $$(basename $(IMAGE_URL))

	# sudo podman run --rm --privileged -v /dev:/dev -v /run/udev:/run/udev -v ./$(OUTPUT_DIR):/data -w /data quay.io/coreos/coreos-installer:release install --image-url $(IMAGE_URL) --ignition-file ./$(IMAGE_VARIANT).ign $(DISK_DEVICE)
	sudo podman run --rm --privileged -v /dev:/dev -v /run/udev:/run/udev -v ./$(OUTPUT_DIR):/data -w /data quay.io/coreos/coreos-installer:release install --image-file $$(basename $(IMAGE_URL)) --ignition-file ./$(IMAGE_VARIANT).ign $(DISK_DEVICE)
	
	sudo losetup --detach $(DISK_DEVICE)

# Write bootstrap ignition to disk image
bootstrap-image:
	make _image IMAGE_VARIANT=bootstrap HOST=metal IMAGE=raw.xz

# Write bootstrap ignition to disk image
master-image:
	make _image IMAGE_VARIANT=master HOST=metal IMAGE=raw.xz

# Write bootstrap ignition to disk image
worker-image:
	make _image IMAGE_VARIANT=worker HOST=metal IMAGE=raw.xz

# Generic ISO helper
_iso:
	podman run --rm --privileged -v ./$(OUTPUT_DIR):/data -w /data quay.io/coreos/coreos-installer:release iso ignition embed --force --ignition-file ./$(IMAGE_VARIANT).ign --output $(IMAGE_VARIANT).iso $$(basename $(IMAGE_URL))

# Write bootstrap ignition to disk image
bootstrap-iso:
	make _iso IMAGE_VARIANT=bootstrap HOST=live IMAGE=iso

# Write bootstrap ignition to disk image
master-iso:
	make _iso IMAGE_VARIANT=master HOST=live IMAGE=iso

# Write bootstrap ignition to disk image
worker-iso:
	make _iso IMAGE_VARIANT=worker HOST=live IMAGE=iso


# Wait for bootstrap process to complete
bootstrap-complete:
	$(TOOLING_DIR)/openshift-install --dir=$(OUTPUT_DIR) wait-for bootstrap-complete

# Wait for install process to complete
install-complete:
	$(TOOLING_DIR)/openshift-install --dir=$(OUTPUT_DIR) wait-for install-complete

copy-images-to-libvirt:
	# sudo cp -r $(OUTPUT_DIR)/*.img /var/lib/libvirt/images
	sudo cp -r $(OUTPUT_DIR)/bootstrap.iso /var/lib/libvirt/images
