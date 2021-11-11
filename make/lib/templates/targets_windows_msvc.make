bin/$(NAME).lib: $(OBJ)
	mkdir -p $(@D)
	$(LIB) -OUT:$@ $^

.SUFFIXES: .c .obj
.c.obj:
	$(CC) $(CFLAGS) -Fo$@ -c $<
