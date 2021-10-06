bin/$(NAME).app: bin/$(NAME)
	mv bin/$(NAME) $@

bin/$(NAME): $(OBJ) $(OBJ_EXTRA)
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

res/noto/files:
	make/scripts/noto_get.sh
	make/scripts/twemoji_get.sh

res/noto/noto.bin.zst: res/noto/files
	make/scripts/noto_pack.sh

res/zstd/build/single_file_libs/zstddeclib.c:
	make/scripts/zstd_gen.sh

run: bin/$(NAME) res/noto/noto.bin.zst
	cp res/noto/noto.bin.zst bin/
	mkdir -p bin/test
	cd bin && $(CMD)
