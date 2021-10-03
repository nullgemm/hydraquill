bin/$(NAME): $(OBJ) $(OBJ_EXTRA)
	mkdir -p $(@D)
	$(CC) -Febin/$(NAME).exe $^ -link -ENTRY:mainCRTStartup $(LDFLAGS) $(LDLIBS)

res/noto/files:
	make/scripts/noto_get.sh

res/noto/noto.bin.zst: res/noto/files
	make/scripts/noto_pack.sh

res/zstd/build/single_file_libs/zstddeclib.c:
	make/scripts/zstd_gen.sh

run: bin/$(NAME)
	cp res/noto/noto.bin.zst bin/
	mkdir -p bin/test
	cd bin && $(CMD)

leak: bin/$(NAME).exe
	cp res/noto/noto.bin.zst bin/
	mkdir -p bin/test
	cd bin && drmemory.exe $(DRMEMORY) 2> ../drmemory.log $(CMD)
	less drmemory.log

.SUFFIXES: .c .obj
.c.obj:
	$(CC) $(CFLAGS) -Fo$@ -c $<
