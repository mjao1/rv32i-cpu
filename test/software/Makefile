# RV32I bare-metal build, writes test/programs/main.mem for simulation
PREFIX ?= riscv64-unknown-elf-
CC := $(PREFIX)gcc
OBJCOPY := $(PREFIX)objcopy

CFLAGS := -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -ffreestanding -O2 -Wall
LDFLAGS := -T link.ld

BUILD := build
PROG_MEM := ../programs/main.mem

.PHONY: all clean

all: $(PROG_MEM)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/main.elf: crt0.S main.c link.ld | $(BUILD)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ crt0.S main.c

$(BUILD)/main.bin: $(BUILD)/main.elf
	$(OBJCOPY) -O binary $< $@

$(PROG_MEM): $(BUILD)/main.bin bin2mem.py
	python3 bin2mem.py $< $@ 1024

clean:
	rm -rf $(BUILD)
	rm -f $(PROG_MEM)
