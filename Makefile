
.PHONEY: clean

seed.iso: seedconfig seedconfig/meta-data seedconfig/user-data
	[ -f seed.iso ] && rm -f seed.iso && \
	hdiutil makehybrid -o seed.iso \
	  -hfs -joliet -iso \
	  -default-volume-name cidata \
	  seedconfig

clean:
	rm -f seed.iso
