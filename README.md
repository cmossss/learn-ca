# Learn-CA · 计算机体系结构 + GPGPU 系统学习

> 一个面向 RTL 工程师的体系结构学习项目：读教材 → 写笔记 → 每个主题配一个 RTL lab。

## 学习目标

系统化掌握计算机体系结构核心（ISA / 流水线 / 缓存 / 乱序）+ GPGPU 架构（SIMT / warp 调度 / 存储层次 / coalescing），以 **RTL 动手实现**为主要实践方式。

| 项 | 说明 |
|---|---|
| 背景 | 3 年数字电路设计（RTL / 时序 / datapath / pipeline），体系结构未系统学过 |
| 周期 | 约 5-6 个月，工作日 1-2h + 周末多 |
| 资料 | 英文为主（CO&D / CAQA / CUDA Guide / NVIDIA 白皮书） |
| 实践 | SystemVerilog RTL + 自备仿真环境（无 NVIDIA GPU，性能实验可用 GPGPU-Sim） |

## 进度总览

| Phase | 主题 | 状态 |
|---|---|---|
| Phase 0 | 摸底与工具链 | 🔄 摸底完成，Lab 0 待开始 |
| Phase 1 | 体系结构核心（1-6 周） | ⬜ 未开始 |
| Phase 2 | GPU/GPGPU 基础（7-12 周） | ⬜ 未开始 |
| Phase 3 | 深度学习 GPGPU 架构（13-20 周） | ⬜ 未开始 |

完整计划见 **[PLAN.md](PLAN.md)**（滚动更新，每完成一项打勾）。

## 目录结构

```
learn-ca/
├── CLAUDE.md        # 学习项目上下文（给 AI 助手的说明）
├── PLAN.md          # 完整学习计划（打勾清单）
├── notes/           # 学习笔记（英文术语 + 中文解释）
├── labs/            # RTL 练习 lab0 ~ lab7
├── papers/          # 论文精读笔记
└── reviews/         # 每周复盘
```

## 当前进度

- ✅ 摸底自测完成（2026-08-29）：体系结构接近零起点，Phase 1 从 Lab 0 正常推进
- ⬜ Lab 0：RV32I 单周期 CPU（IF/ID/EX/MEM/WB 逻辑 + 跑通仿真）
- ⬜ `notes/isa.md`：ISA 笔记

## 学习资源

| 资源 | 用途 |
|---|---|
| Patterson & Hennessy, *CO&D, RISC-V Edition* | 体系结构原理 |
| Hennessy & Patterson, *CAQA 6th* | 定量分析、论文基础 |
| Kirk & Hwu, *Programming Massively Parallel Processors* | GPU 编程与架构 |
| NVIDIA *CUDA C Programming Guide* + 各代白皮书 | GPU 架构一手资料 |
| Onur Mutlu, *CMU 18-447* | 体系结构深讲 |
| RISC-V Spec | ISA 一手规范 |

## 纪律

1. 每周必须有一个可交付物（笔记或 lab 进展）。
2. 卡住超过 30 分钟就求助。
3. 每个 lab 结束时写「我学到了什么 + 还能怎么改」。
4. 计划是活的，随时根据进度调整。
