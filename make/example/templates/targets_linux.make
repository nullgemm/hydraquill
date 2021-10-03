bin/$(NAME): $(OBJ) $(OBJ_EXTRA)
	mkdir -p $(@D)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

res/noto/files:
	make/scripts/noto_get.sh

res/noto/noto.bin.zst: res/noto/files
	make/scripts/noto_pack.sh

res/zstd/build/single_file_libs/zstddeclib.c:
	make/scripts/zstd_gen.sh

leak: bin/$(NAME)
	cp res/noto/noto.bin.zst bin/
	mkdir -p bin/test
	cd bin && valgrind $(VALGRIND) 2> ../valgrind.log $(CMD)
	less valgrind.log

run: bin/$(NAME)
	cp res/noto/noto.bin.zst bin/
	mkdir -p bin/test
	cd bin && $(CMD)
