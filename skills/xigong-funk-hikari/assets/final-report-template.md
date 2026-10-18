# Hikari-LLVM 明文可运行交付报告

## Artifact DAG

| ID | 层/用途 | 路径 | SHA-256 | 大小 | 执行模型 |
|---|---|---|---|---:|---|

## 识别结论

- family provenance：
- pass contracts：
- 已排除保护：
- CFF/VM gate：

## 外层反混淆

- 静态改写：
- 改动字节/allowlist：
- 未解析动态边：
- rollback：

## Runtime inner 物化

- PID/时机/输入：
- mapping cluster：
- handoff/PC/LR provenance：
- raw/analysis artifacts：
- pointer normalization：
- recovered strings：

## 最终交付等级

- 等级：L1 / L2 / L3 / L4
- 明文直接搜索：PASS / FAIL
- 直接运行：PASS / FAIL
- loader-free：YES / NO
- execution model：

## 五轴验证

| structure | semantics | runtime | packaging | equivalence |
|---|---|---|---|---|

## 输入回归矩阵

| case | root stdout/stderr/rc | candidate stdout/stderr/rc | equal |
|---|---|---|---|

## 已知边界

-
