---
name: tpu-kernel-perf
description: 仅在用户要求分析 TPU kernel 性能、计算 Gold Time / Hardware Theoretical Time、分析 LLO dump、统计 Pallas/Triton kernel 的 FLOP 数量，或对 TPU v6e 硬件上界建模时使用。触发关键词：gold time、hardware theoretical、LLO、dump_llo、bundle 分析、FLOP 计数、roofline、TPU 性能建模、vmatmul、vbcast、vcmp、EUP、VALU、MXU 利用率。
---

# TPU Kernel 性能分析

## 方法论：三层时间模型

对任意 TPU kernel，在三个层次上计算时间：

```
Gold Time  →  Hardware Theoretical  →  Current LLO
（数学最小值）    （真实硬件上界）          （编译器输出）
```

### 第一步：Gold Time — 数学最小值

**给定一个 kernel 函数**，从数学公式出发统计所有操作：

1. **1D 逐元素**：mul、add、sub、cmp、select — 每个标量元素计 1 次操作
2. **2D 矩阵乘**：每次矩阵乘计 M×K×N 个 MAC。每个 MAC = 1 次 mul + 1 次 add，在 MXU 上融合执行
3. **超越函数**：exp₂、log、sqrt — 每个元素计 1 次操作，吞吐量与 VALU 等同
4. **规约**：max、sum — 计 (n-1) 次比较或加法

**排除实现产物**：不计子块分解、dtype 转换、数值稳定性参考点、内存延迟。

**操作计数**：编写一个 Python 脚本，精确镜像 kernel 的数学操作，对每次调用的每个标量操作计数。用 C、K、BC、NC 变量表示与维度无关的计数。

**理论时间**：将每类操作数除以 TPU 吞吐量：

| 资源 | 吞吐量（v6e） |
|------|-------------|
| VALU（1D） | 4,096 ops/cycle |
| MXU（2D） | 262,144 MACs/cycle |
| EUP（exp₂） | 与 VALU 相同（4,096），共享 1D 发射槽 |

`Gold = max(1D_cycles, 2D_cycles)`，以每次调用为单位。Grid 元素视为并行执行。

### 第二步：Hardware Theoretical Time — 真实硬件上界

**加入编译器无法消除的真实硬件约束**：

**a) 子块分解**：若算法进行了拆分，重新计算操作数。

**b) dtype 转换**：检查 `dot_general` 是否使用 `preferred_element_type=jnp.float32` — 这会强制进行 bf16→f32 软转换（vand+vsub，每个元素约 2 次 VALU 操作）。统计进入矩阵乘的元素数量并乘以 2。

**c) MXU tile 分解**：每个逻辑矩阵乘 `[M,K]@[K,N]` 会分解为 `ceil(M/tile_M) × ceil(N/tile_N) × ceil(K/tile_K)` 条硬件矩阵乘指令。使用 LLO dump 获取精确计数：在 `final_bundles.txt` 中 `grep` vmatmul/vmatprep/vmatpush3/vpop 的数量。

**d) mask 构造开销**：若 kernel 使用因果 mask，统计 LLO 指令序列：
- `vlaneseq` (1) + `vand` (1) → 生成 idx 向量
- `vbcast.xlu0/1`（多次）→ 广播为 [C,C]
- `vpop.permute` → 通过 permute 从 XLU 读回
- `vcmp.ge/gt` → 逐元素比较，每轮 C²/1024 条指令
- `vmpackc` → 将 mask 位打包供 MXU 使用
- `vsel` → 应用 mask（jnp.where）

**e) 重叠模型**：VALU 与 MXU 运行在独立流水线上。瓶颈 = max(VALU_total, MXU_instruction_overhead + VLOAD + VSTORE + SALU)。EUP 与 VALU 共享 1D 发射槽。

**f) 排除可优化开销**：spill/fill（来自 vreg 压力）、串行循环气泡、冗余 SALU — 这些可通过更好的代码消除（批量矩阵乘、子块加载、指令提升）。

### 第三步：LLO 分析 — 编译器输出的真实基准

**每个 kernel 的关键 LLO 文件**（命名格式 `*_kernelname.1-NN-description.txt`）：

| 文件 | 内容 |
|------|------|
| `-71-schedule-analysis_final_bundles.txt` | 总 bundle 数、空 bundle 数 |
| `-72-final_bundles.txt` | 最终 VLIW 汇编 — 指令计数 |
| `-70-final_hlo-static-per-bundle-utilization.txt` | 每个 bundle 的功能单元使用情况 |
| `-35-critical-path.txt` | 最长依赖链 |
| `-46-register-pressure.txt` | sreg/vreg 数量 |
| `-68-pre-delay_*.txt` | 延迟转换器之前的利用率 |
| `-47-schedule-analysis_packed-bundles-pre-ra.txt` | RA 前的 bundle 数量 |
| `-59-region-expansion-*.txt` | spill/fill 扩展情况 |

**指令分类模式**（从 final_bundles 中 grep 计数）：
- MXU：`vmatmul`、`vmatprep`、`vmatpush3`、`vpop.f32.mrf`
- VALU：`vadd.f32`、`vmul.f32`、`vsub.f32`
- bf16→f32：`vand.u32 42949`（每对 = 1 vand + 1 vsub）
- 硬件解包：`vunpack.[ic].[hl].bf16`
- Mask：`vcmp.ge/gt.s32`、`vsel`、`vmpackc`、`vlaneseq`
- 标量：`scmp`、`smov`、`scalar_select`
- XLU：`vxpose`、`vrot`、`vpop.permute`

**从利用率矩阵分析重叠**：
每行格式 = `MXU XLUT VALU VPOP EUP VLOAD VLOAD:FILL VSTORE VSTORE:SPILL SALU`。
统计共现次数，判断哪些单元可以同时发射。

## 分析文档结构

```markdown
# <kernel_name> 性能建模
## 1. 问题规模 & 硬件参数
## 2. Gold Time
### 2.1 数学公式
### 2.2 计算量
### 2.3 理论时间
## 3. Hardware Theoretical Time
### 3.1 数学公式 + 工程实现（math → LLO 映射）
### 3.2 计算量
### 3.3 硬件开销
### 3.4 理论时间
## 4. Current LLO（当前实测）
## 5. 优化方案
```yml:calculation_format
维度       | 操作数      | 吞吐量        | 时间
1D (VALU) | N/ops      | 4096/cycle   | N/4096
2D (MXU)  | N/MACs     | 262144/cycle | N/262144
Gold = max(T_1D, T_2D)
```

## TPU v6e 关键参数

| 参数 | 数值 |
|------|------|
| 时钟 | 1.75 GHz，1 cycle ≈ 0.571 ns |
| MXU | 4 × 256² 脉动阵列，918 TFLOPs，262,144 MACs/cycle |
| VALU | 4,096 element ops/cycle，7.168 TFLOPs |
| EUP | 与 VALU 共享 1D 发射槽，4,096 ops/cycle |
| HBM 带宽 | 1.6 TB/s（芯片级） |
| 向量 SIMD | ~1024 fp32 lanes |
| 架构 | 双 SubCore，每 SubCore 2 个 MXU |

## 验证清单

计算完三个层次后，核查：
- [ ] Gold 表格中各元素计数总和正确（mul+add+sub+cmp+exp₂）
- [ ] Gold 1D 吞吐量除法结果接近整数 cycle
- [ ] HW 1D 数学总量与 §3.2 表格加总一致
- [ ] HW 表格总量与 Gold → HW → LLO 的差距分解吻合
- [ ] LLO 指令计数从当前 dump 重新提取（非旧数据）
- [ ] bf16→f32 开销追溯到代码中的 `preferred_element_type`
- [ ] 从单次调用到全数据集的缩放使用了正确的 grid 大小
- [ ] spill/fill 开销与理论硬件最小值分开统计
- [ ] 所有重叠假设均有依据并已记录

## 常见陷阱

1. **将 mask 计为标量**：mask 构造使用 vcmp（向量指令）而非 scmp（标量指令）。查看 LLO 确认实际指令类型。
2. **EUP 吞吐量**：EUP 与 VALU 共享 1D 发射槽 — 不能重叠。
3. **vbcast 重复**：XLU 寄存器会被 vxpose 覆写，导致必须重新广播。统计实际 LLO 中 vbcast 的数量，而非算法理论最小值。
4. **MXU tile 数量随编译器版本变化**：始终从当前 dump 重新提取。
5. **Gold 不应包含 g_max/r/c 数值稳定性产物**：这些是实现细节，不是数学要求。
