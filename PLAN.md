# GPGPU 系统学习计划 (Learn-CA)

> 学习是一个主动过程：读教材是输入，动手实现和复述是输出。**本计划要求每个主题都配一个 RTL 练习**，用电路实现去消化抽象概念。

## 学员画像与目标

| 项 | 说明 |
|---|---|
| 背景 | 3 年数字电路设计经验（RTL / 时序 / datapath / pipeline），有体系结构常识但未系统学过 |
| 现状 | 刚入职 GPGPU 设计公司，需要把体系结构 + GPGPU 架构知识系统化 |
| 目标 | 体系结构基础 → GPGPU/GPU 架构深入 → RTL 动手实践 |
| 时间 | 工作日 1-2h/天 + 周末较多，约 12-15h/周 |
| 总周期 | 约 5-6 个月 |
| 资料 | 英文为主 |
| 实践 | RTL 实现为主，自备仿真环境（无 NVIDIA GPU） |

## 三条核心原则

1. **用电路思维学体系结构**——你最大的优势是硬件直觉。每个概念都要能「翻译」成时序图/数据通路：forwarding 就是旁路 MUX，hazard 就是 stall 信号，register renaming 就是一张映射表。遇到难懂的概念，先在纸上画 datapath。
2. **每个主题配一个 RTL lab**——动手实现是把理论变成肌肉记忆的唯一方式，也是你作为 RTL 工程师最有产出感的学习路径。
3. **笔记用英文术语写**——公司文档、论文、面试都基于英文术语。在 `notes/` 里用英文记概念，用自己的话复述（费曼学习法）。

## 目录结构

```
D:\learn_ca\
├── PLAN.md          # 本计划（滚动更新，每完成一项打勾）
├── notes/           # 学习笔记：每个主题一个文件，英文术语 + 中文解释
├── labs/            # RTL 练习，按 lab0, lab1... 组织
├── papers/          # 论文精读笔记（一篇一个文件）
└── reviews/         # 每周复盘：本周学了什么 / 卡在哪 / 下周计划
```

---

## Phase 0：摸底与工具链（第 1 周）

**目标**：确认知识缺口，跑通仿真环境，完成第一个热身练习。

- [x] **0.1 摸底自测** ✅ 完成（2026-08-29）。结论：**体系结构接近零起点**——Part A 有零星印象（RISC 定长、三种寻址模式含义），但 Q2 判型答成 funct3（应为 opcode）、load-store 设计动机不清晰；Part B~E 全部「完全没概念」。**Phase 1 不可快进**，从 Lab 0 正常推进。注意：学员自评偏保守（Q1 实际答对却标「听说过」），以实际作答为准。
- [ ] **0.2 仿真环境确认**：确认你现有仿真 flow 能跑 SystemVerilog，能看波形。若想在家也练，可考虑 [Verilator](https://www.veripool.org/verilator/)（开源、快，适合本计划；工作环境用公司 flow 即可）
- [ ] **0.3 Lab 0：RV32I 单周期 CPU**（热身 + 验证环境）
  - 实现 IF/ID/EX/MEM/WB 五段逻辑（非流水线）的 RV32I 处理器：取指、译码、寄存器堆、ALU、数据内存
  - 跑通简单测试程序（如求斐波那契），能看波形
  - 参考：Patterson & Hennessy《Computer Organization and Design》RISC-V 版 Ch.4 的 RISC-V 数据通路；[RISC-V 规范](https://riscv.org/technical/specifications/)
- [ ] **0.4 搭建笔记模板**：在 `notes/` 建 `template.md`

---

## Phase 1：体系结构核心（第 1-6 周）

> 你有硬件底子，这块可以快但不要跳。这是 GPGPU 所有概念的地基（调度、乱序、存储层次……GPU 全都在用）。

**教材**：Patterson & Hennessy《Computer Organization and Design, RISC-V Edition》(简称 CO&D) + Hennessy & Patterson《Computer Architecture: A Quantitative Approach 6th》(简称 CAQA)。CO&D 讲原理，CAQA 讲定量分析（等你进入 Phase 3 论文阶段会大量用到）。

### Week 1（与 Phase 0 并行）：ISA 与 RISC-V
- **阅读**：CO&D Ch.2；RISC-V Unprivileged Spec 的 RV32I/RV64I 部分
- **笔记**：`notes/isa.md` —— 指令编码、寄存器约定、addressing modes、为什么定长指令对流水线友好
- **Lab 0** 完成

### Week 2：流水线基础
- **阅读**：CO&D Ch.4（5 级流水线、三类 hazard、forwarding、load-use stall、分支损失）
- **笔记**：`notes/pipeline.md` —— 用时序图画出 5 级流水线；画出 forwarding 数据通路
- **Lab 1a**：把 Lab 0 改成 5 级流水线（加流水线寄存器）

### Week 3：分支预测与控制冒险
- **阅读**：CO&D Ch.4 后半；CAQA Ch.3（分支预测）挑读
- **笔记**：`notes/branch_prediction.md` —— static vs dynamic、2-bit 饱和计数器、BTB、BTB 缺失损失
- **Lab 1b**：Lab 1a 加 forward + load-use stall + 2-bit branch predictor（带 BTB），对比加预测器前后 CPI
- **里程碑**：一个能跑出真实 CPI 收益的流水线 RISC-V CPU ✅

### Week 4：乱序执行（难度陡增，可放缓）
- **阅读**：CAQA Ch.3（数据冒险的三种处理：stall → 静态调度 → 动态调度）；Tomasulo 算法；register renaming、ROB
- **视频（强烈推荐）**：Onur Mutlu 的 CMU 18-447 课程 OoO 相关 lecture（YouTube，英文）
- **笔记**：`notes/oo_execution.md` —— 画出 Tomasulo 的 reservation station 数据通路
- **Lab 2**（可选/进阶，量力而行）：
  - 方案 A：实现一个**简化 Tomasulo 控制器**（2 个 ALU + 1 个 Load 单元，支持 reg renaming，处理 WAW/WAR），RTL 或 SystemVerilog 均可
  - 方案 B：读一个开源 OoO 核心的 RTL（如 [Rocket](https://github.com/chipsalliance/rocket-chip)/[BOOM](https://boom-core.org/)）并写架构级代码走读笔记（这一步对你在公司读别家 GPU 的调度逻辑很有用）
  - 如果时间紧，**至少**用一段话说明 OoO 怎么消除 WAR/WAW，怎么在 GPU 上（无 renaming、靠 warp-level parallelism 隐藏）是另一条路——这为 Phase 2 埋伏笔

### Week 5-6：缓存与存储层次
- **阅读**：CAQA Ch.2（这是最核心的一章：cache 组织、替换、写策略、缺失类型 3C、DRAM 结构、内存调度、虚拟内存/TLB）
- **笔记**：`notes/memory_hierarchy.md` —— 画 cache 结构；算 miss rate 的例子；理解「为什么 GPU 高延迟容忍改变了 cache 设计取舍」
- **Lab 3**：实现一个参数化 L1 cache（可配 assoc / line size / 替换策略，含 write-back + write-allocate），RTL 实现 + 简单测试；有条件可接回 Lab 1 的 CPU 做真实对比
- **里程碑**：Phase 1 完成，此时你已有完整体系结构视野 ✅

---

## Phase 2：GPU / GPGPU 基础（第 7-12 周）

> 核心心法：**GPU 是体系结构设计空间里与 CPU 相反的一个极端**。CPU 优化延迟（一堆硬件为单个指令流提速），GPU 优化吞吐（放弃单线程性能，用大规模并行+延迟隐藏换总吞吐）。抓住这个对比，整个 GPU 架构就都能理解。

**教材**：Kirk & Hwu《Programming Massively Parallel Processors》(3rd/4th ed，英文) + NVIDIA《CUDA C Programming Guide》(免费官方文档，重点读 Programming Model 与 Memory Hierarchy 章节)

### Week 7：GPU 设计哲学 + SIMT 执行模型
- **阅读**：CUDA Guide 前几章（thread/grid/block 抽象）；NVIDIA [Fermi 白皮书](https://www.nvidia.com/content/pdf/fermi_white_papers/NVIDIA_Fermi_Compute_Architecture_Whitepaper.pdf)（GPU 架构入门经典）；《Programming Massively Parallel Processors》前 3 章
- **关键概念**：SIMT vs SIMD；warp；lane；lockstep 执行；分支发散 divergence；`__syncthreads`
- **笔记**：`notes/gpu_philosophy.md` —— 用表格对比 CPU vs GPU 在调度/缓存/寄存器/中断/同步上的取舍
- **Lab 4（旗舰练习）：迷你 SIMT 核心**
  - 实现一个 4-lane（或 8-lane）的 SIMT 处理器：取指 → warp 调度 → 指令广播到各 lane → 按 lane mask 执行 → 简化分支处理（无发散则广播，发散则串行化/重收敛栈）
  - 关键模块：lane 的状态掩码、warp 寄存器文件（按 lane 分bank）、统一的指令流
  - 这一步直接复刻 NVIDIA SM 的骨架，做完你对 warp 的理解会远超读十篇文章

### Week 8-9：GPU 存储层次 + 访存合并
- **阅读**：《Programming Massively Parallel Processors》内存相关章节；CUDA Guide 的 Memory Hierarchy 与 Shared Memory 章节；NVIDIA 各代白皮书的 memory 部分
- **关键概念**：寄存器、shared memory、L1/L2、global/constant/texture；**memory coalescing**（合并访存是把带宽用满的头号优化）；bank conflict
- **笔记**：`notes/gpu_memory.md` —— 画 GPU 存储层次图；用例子说明 coalescing 的命中/错过
- **Lab 5a**：实现一个 banked shared memory（如 8 banks × 32bit），带 **bank conflict 检测单元**（模拟一次访问的 cycle 数）
- **Lab 5b**：实现一个简化的 **coalescer**（把 warp 内 32 个 lane 的标量地址合并成 128B 的 cache line 请求），对比合并前后带宽利用

### Week 10-11：Warp 调度与延迟隐藏
- **阅读**：Fermi/Kepler/Volta 白皮书里关于 warp scheduler 的部分；论文《An Analysis of GPU Warp Scheduling Algorithms》或《The importance of warp scheduling》
- **关键概念**：occupancy（占用率，决定多少个 warp 在藏延迟）；round-robin vs greedy-then-oldest 调度；latency hiding 的本质=多个独立 warp 交错执行
- **笔记**：`notes/warp_scheduling.md` —— 手算 occupancy：给定寄存器数/线程数，能放下几个 warp
- **Lab 6**：实现一个 **warp scheduler + occupancy 计算器**（跟踪各 warp 的 ready 状态，round-robin 和 greedy 两种策略可切换，输出每周期 IPC 对比）
- **里程碑**：Phase 2 完成，你已经能看懂现代 GPU 的 SM 结构图 ✅

### Week 12：GPU 同步 / 原子操作 / 编程模型深水区（结合你工作）
- **阅读**：CUDA Guide 的 atomics / memory model 章节；《Programming Massively Parallel Processors》协同并行章节
- **输出**：画一张「一个 kernel 从 launch 到 retire」在硬件里的完整旅程图（CUDA launch → 前端 → dispatch → SM → warp 执行 → 返回）。这张图会是你在公司最有用的心智模型之一

---

## Phase 3：深度学习 GPGPU 架构（第 13-20 周）

> 进入论文级理解。目标：能读懂并复述 ISCA/MICRO/HPCA 的 GPGPU 论文，能对比不同厂商架构。

### Week 13-14：NVIDIA 现代架构深挖
- **阅读**：Volta / Turing / Ampere / Hopper 白皮书（NVIDIA 官网全免费）；重点：SM 内部结构、warp scheduler 数量、tensor core、special function unit、异步拷贝（async copy / TMA）、线程块集群
- **笔记**：`notes/nvidia_generations.md` —— 按代际做一张「SM 组成」对比表（多少 SM 单元 / 多少 scheduler / 多少 FP32 / Tensor Core 引入时间等）
- **练习**：拿一张 Volta 或 Ampere SM 结构图，把 Phase 2 的 Lab 4-6 模块**一一对应**到真实架构的部件上

### Week 15：AMD 架构对比 + 分岔探索
- **阅读**：AMD CDNA2/3、RDNA 白皮书（wave32/wave64 vs NVIDIA warp）；可对比 Intel 的 Xe 架构
- **笔记**：`notes/amd_vs_nvidia.md` —— 对比调度粒度、寄存器组织、cache 策略、GPGPU 编程模型的差异

### Week 16-18：片上网络 / 存储系统 / 高级话题
- **阅读**：CAQA Ch.5 与 NoC 相关；论文：GPGPU 相关 cache management、memory partitioning、NoC
- **话题清单**（挑 2-3 个精读）：GPU 全局内存调度（内存控制器如何给不同 warp 排队）、L2 切分策略、片上互连拓扑、virtual memory 在 GPU 的实现（大页、unified memory）
- **笔记**：`notes/advanced_topics.md` + `papers/` 每篇一个精读笔记（问题/方法/结论/对你工作的启示）

### Week 19-20：综合项目（Capstone）
- **Lab 7：张量/矩阵乘单元（Tensor-Core 式）**
  - 实现一个 systolic array（如 4x4 或 8x8）的 MMA 单元，数据从 shared memory 流入，支持矩阵乘累加
  - 与朴素 MAC 实现对比 cycle 数 / 面积 / 利用率
  - 这是 tensor core 的骨架实现，做完对 GPU 的矩阵单元有彻底的理解
- **Capstone 汇报**：把 Lab 4 + Lab 7 串起来，写一页架构说明（画框图 + 关键参数 + 性能对比），相当于一份「迷你 GPU 设计文档」

---

## 英文学习资源总表

| 资源 | 用途 | 获取 |
|---|---|---|
| Patterson & Hennessy, *Computer Organization and Design, RISC-V Edition* | 体系结构原理（Phase 1） | 书 |
| Hennessy & Patterson, *Computer Architecture: A Quantitative Approach* (6th) | 定量分析、论文基础（Phase 1/3） | 书 |
| Kirk & Hwu, *Programming Massively Parallel Processors* | GPU 编程与架构（Phase 2） | 书 |
| NVIDIA *CUDA C Programming Guide* | GPU 编程模型/存储层次权威参考 | 官网免费 |
| NVIDIA 各代白皮书 (Fermi→Hopper) | GPU 架构一手资料 | nvidia.com 免费 |
| Onur Mutlu, *CMU 18-447 Computer Architecture* 课程视频 | 体系结构深讲（尤其 OoO/缓存） | YouTube 免费 |
| RISC-V Spec | ISA 一手规范 | riscv.org 免费 |
| GPGPU-Sim / Accel-Sim（可选） | 架构级实验（跑在 CPU 上，**无需 NVIDIA GPU**） | 开源 |
| 论文：ISCA / MICRO / HPCA / ASPLOS | 前沿架构 | 各会议官网 |

> 提示：你无 NVIDIA GPU 也能学 CUDA 的**架构概念**（编程模型是架构无关的），只是不能亲手跑 kernel。RTL 路线不受影响。若未来想练性能分析，GPGPU-Sim 跑在 CPU 上、不需要真显卡，可作为补充。

## 周节奏建议

```
工作日（1-2h）：
  前半周：读教材/论文，写 notes
  后半周：推进 RTL lab（碎片时间适合写模块、改代码）
周末（多）：集中做 lab 的联调/波形分析/复盘
每周日晚：写 reviews/ 复盘，并在 PLAN.md 上打勾
```

## 纪律建议

1. **每周必须有一个可交付物**（笔记 或 lab 进展），否则下周降速。
2. **卡住超过 30 分钟就来找我**——我是你的常驻导师，随时可以带着你的 RTL/笔记来讨论。
3. **把公司工作的架构问题带回来**：看不懂的 block 图、调度逻辑、cache 行为，都拿到这里一起拆解，这是最贴近实战的学习。
4. **每个 lab 结束时写一小段「我学到了什么 + 还能怎么改」**，防止「做完了但没懂」。
5. 计划是活的：进度快了就加深，慢了就砍 Lab 2 这种可选项目，随时跟我调整。
