ALL: user.bin

user.bin: tambor.o user.cfg
	ld65 -C user.cfg -o user.bin tambor.o

tambor.o: tambor.s
	ca65 -o $@ $<
