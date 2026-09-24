# ============================================================
# Lab 0 —— RV32I 单周期 CPU
#
#   make                      显示帮助
#   make hex  PROG=t02_fib    只汇编：sw/t02_fib.S -> build/t02_fib.hex
#   make dis  PROG=t02_fib    反汇编（对着波形看指令）
#   make sim  PROG=t02_fib    跑仿真，打印 PASS/FAIL
#   make wave PROG=t02_fib    跑仿真 + dump 波形 + 打开 gtkwave
#   make test                 把 sw/t*.S 全部跑一遍  ← Lab 0 的验收命令
#   make clean                清掉 build/
# ============================================================

LAB_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SW_DIR  := $(LAB_DIR)/sw
RTL_DIR := $(LAB_DIR)/rtl
TB_DIR  := $(LAB_DIR)/tb
BUILD   := $(LAB_DIR)/build
OBJ_SIM := $(BUILD)/obj_sim
SIM_BIN := $(OBJ_SIM)/sim

CROSS   := riscv64-linux-gnu-
CC      := $(CROSS)gcc
OBJCOPY := $(CROSS)objcopy
OBJDUMP := $(CROSS)objdump

# 裸机 RV32I：不要 libc、不要启动代码、不要 PIE
CFLAGS  := -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -no-pie \
           -Wl,--build-id=none -Wl,--no-warn-rwx-segments -T $(SW_DIR)/link.ld

PROG ?= t02_fib
ELF  := $(BUILD)/$(PROG).elf
BIN  := $(BUILD)/$(PROG).bin
HEX  := $(BUILD)/$(PROG).hex
LOG  := $(BUILD)/$(PROG).log
FST  := $(BUILD)/wave_$(PROG).fst
DASM := $(BUILD)/$(PROG).dump

PROGS := $(basename $(notdir $(wildcard $(SW_DIR)/t*.S)))

VFLAGS := --binary --timing --trace-fst -j 0 -Wall -Wno-fatal -DTRACE \
          --top-module tb_top -Mdir $(OBJ_SIM) -o sim

.PHONY: help hex dis sim wave test clean

help:
	@echo ""
	@echo "  Lab 0 —— RV32I 单周期 CPU"
	@echo "  ------------------------------------------------------------"
	@echo "    make hex  PROG=<名>    汇编 + 转 hex"
	@echo "    make dis  PROG=<名>    反汇编"
	@echo "    make sim  PROG=<名>    跑仿真"
	@echo "    make wave PROG=<名>    跑仿真 + 开波形"
	@echo "    make test              全部测试跑一遍"
	@echo "    make clean             清理 build/"
	@echo ""
	@echo "    可用程序: $(PROGS)"
	@echo "    当前 PROG: $(PROG)"
	@echo ""

$(BUILD):
	@mkdir -p $@

# ---------- 软件侧：.S -> .elf -> .bin -> .hex ----------

$(ELF): $(SW_DIR)/$(PROG).S $(SW_DIR)/link.ld | $(BUILD)
	@$(CC) $(CFLAGS) -o $@ $<
	@$(OBJDUMP) -d $@ | grep -q '^00000000 <_start>:' \
	  || { echo "ERROR: _start 不在地址 0 —— 它必须是 $(PROG).S 里第一段代码"; \
	       echo "       看看 sw/$(PROG).S 开头是不是 .text / .globl _start / _start:"; exit 1; }

$(BIN): $(ELF)
	@$(OBJCOPY) -O binary --only-section=.text $< $@

$(HEX): $(BIN)
	@python3 $(SW_DIR)/bin2hex.py $< $@

hex: $(HEX)

dis: $(ELF)
	@$(OBJDUMP) -d $< | tee $(DASM)

# ---------- 仿真 ----------

$(SIM_BIN): $(RTL_DIR)/rv32i_core.sv $(TB_DIR)/tb_top.sv | $(BUILD)
	@echo "  正在编译 RTL (verilator)..."
	@verilator $(VFLAGS) $(RTL_DIR)/rv32i_core.sv $(TB_DIR)/tb_top.sv \
	    > $(BUILD)/verilator.log 2>&1 \
	  || { echo "ERROR: verilator 编译失败，详细日志 $(BUILD)/verilator.log"; \
	       tail -25 $(BUILD)/verilator.log; exit 1; }
	@# 只把 lint 警告捞出来显示，g++ 那堆噪音留在日志里
	@grep -E '^%(Warning|Error)' $(BUILD)/verilator.log | sort -u | head -20 || true

sim: $(HEX) $(SIM_BIN)
	@$(SIM_BIN) +prog=$(HEX) 2>&1 | tee $(LOG); \
	 if grep -q '=== PASS ===' $(LOG); then echo "  [$(PROG)] PASS"; \
	 else echo "  [$(PROG)] FAIL  —— 详见 $(LOG)"; exit 1; fi

wave: $(HEX) $(SIM_BIN)
	@$(SIM_BIN) +prog=$(HEX) +wave=$(FST) 2>&1 | tee $(LOG)
	@echo "  波形 -> $(FST)"
	@gtkwave $(FST) >/dev/null 2>&1 &

test: | $(BUILD)
	@ok=1; \
	for p in $(PROGS); do \
	  if $(MAKE) --no-print-directory sim PROG=$$p >$(BUILD)/$$p.testlog 2>&1; then \
	    printf '  %-12s PASS\n' "$$p"; \
	  else \
	    printf '  %-12s FAIL\n' "$$p"; \
	    sed 's/^/      | /' $(BUILD)/$$p.testlog | tail -20; \
	    ok=0; \
	  fi; \
	done; \
	echo ""; \
	if [ $$ok -eq 1 ]; then echo "  全部通过"; \
	else echo "  有失败。单跑一个看细节：make sim PROG=<名>"; exit 1; fi

clean:
	@rm -rf $(BUILD)
