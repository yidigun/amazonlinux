.PHONEY: clean qemu qemu-clean ssh

seed.iso: build/meta-data build/user-data
	[ -f seed.iso ] && rm -f seed.iso; \
	case `uname -s` in \
	  Darwin) hdiutil makehybrid -o seed.iso -hfs -joliet -iso -default-volume-name cidata build;; \
	  Linux) (cd build; genisoimage -output ../seed.iso -volid cidata -joliet -rock user-data meta-data);; \
	  *) echo "Unsupported OS: `uname -s`"; \
	esac

build/meta-data: meta-data
	mkdir -p build; \
	cp meta-data build/meta-data

build/user-data: user-data
	mkdir -p build; \
	cp user-data build/user-data

clean:
	rm -rf build seed.iso

# RUN arm64 VM with qemu

OS_VER   = 2.0.20211201.0
DISK_IMG = amzn2-kvm-$(OS_VER)-arm64.xfs.gpt.qcow2
PORT_FWD = 5555:22 8080 8081 8082 3306
SSH_PORT = 5555
SSH_USER = dagui

qemu: vms/$(DISK_IMG) seed.iso
	hostfwd=; \
	for p in $(PORT_FWD); do \
	  hport=`echo $$p | cut -d: -f1`; \
	  gport=`echo $$p | cut -d: -f2`; \
	  if [ -z "$$gport" ]; then \
	    gport=$$hport; \
	  fi; \
	  hostfwd="$${hostfwd},hostfwd=tcp:127.0.0.1:$$hport-:$$gport"; \
	done; \
	qemu-system-aarch64 \
	  -cpu cortex-a57 \
	  -smp 8 \
	  -m 8G \
	  -M virt \
	  -bios /opt/local/share/qemu/edk2-aarch64-code.fd \
	  -device virtio-blk-device,drive=hd0 \
	  -drive if=none,file=vms/$(DISK_IMG),id=hd0 \
	  -device virtio-net-pci,netdev=eth0,disable-legacy=on,iommu_platform=on \
	  -netdev user,id=eth0$$hostfwd \
	  -cdrom seed.iso \
	  -pidfile qemu.pid \
	  -nographic

ssh:
	if [ -f qemu.pid ]; then \
	  if [ -n "$(CMD)" ]; then \
	    ssh -p $(SSH_PORT) $(SSH_USER)@127.0.0.1 "$(CMD)"; \
	  else \
	    ssh -p $(SSH_PORT) $(SSH_USER)@127.0.0.1; \
	  fi; \
	  exit 0; \
	else \
	  echo "please run vm \"make qemu\"..."; \
	  exit 1; \
	fi

dist/$(DISK_IMG):
	mkdir -p dist; \
	(cd dist; \
	curl -O "https://cdn.amazonlinux.com/os-images/$(OS_VER)/kvm-arm64/$(DISK_IMG)")

vms/$(DISK_IMG): dist/$(DISK_IMG) seed.iso
	mkdir -p vms; \
	cp -f dist/$(DISK_IMG) vms/$(DISK_IMG)

qemu-clean:
	rm -f vms/$(DISK_IMG)

