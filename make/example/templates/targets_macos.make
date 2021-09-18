bin/$(NAME).app: bin/$(NAME)
	mv bin/$(NAME) $@

bin/$(NAME): $(OBJ) $(OBJ_EXTRA)
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

res/noto/files:
	make/scripts/noto_get.sh

res/noto/noto.bin.zst: res/noto/files
	make/scripts/noto_pack.sh

res/objconv/objconv:
	make/scripts/objconv_make.sh

res/noto/noto_elf.o: res/noto/noto.bin.zst res/objconv/objconv
	$(OBJCOPY) -I binary -O elf64-x86-64 -B i386:x86-64 \
	--redefine-syms=res/noto/syms.map \
	--rename-section .data=.noto \
	$< $@

res/noto/noto_mach.o: res/noto/noto_elf.o
	res/objconv/objconv -fmac64 -nu+ -v0 \
	res/noto/noto_elf.o $@

res/zstd/build/single_file_libs/zstddeclib.c:
	make/scripts/zstd_gen.sh

run: bin/$(NAME)
	cp res/noto/noto.bin.zst bin/
	mkdir -p bin/test
	cd bin && $(CMD)
