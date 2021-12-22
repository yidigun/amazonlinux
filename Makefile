
.PHONEY: clean

seed.iso: build/meta-data build/user-data
	[ -f seed.iso ] && rm -f seed.iso; \
	case `uname -s` in \
	  Darwin) \
	    hdiutil makehybrid -o seed.iso -hfs -joliet -iso -default-volume-name cidata build;; \
	  Linux) \
	    (cd build; genisoimage -output seed.iso -volid cidata -joliet -rock user-data meta-data);; \
	  *) \
	    echo "Unsupported system: `uname -s`"; \
	esac

build/meta-data: meta-data
	mkdir -p build; \
	cp meta-data build/meta-data

build/user-data: user-data
	mkdir -p build; \
	cp user-data build/user-data

clean:
	rm -rf build seed.iso
