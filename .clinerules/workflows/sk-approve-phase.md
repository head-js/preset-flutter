---
name: sk-approve-phase
description: Execute Command: .agents/commands/sk-approve-phase/COMMAND.md
metadata:
    version: 0.0.3
---

# Approve Phase

**FAIL-FAST REQUIREMENT** 检查 `# LLM Coding Level Board`，当前使用基模的评分必须优于 `L3`。如果满足，回复 **{实际使用的基模名称} + 所以我来砍，阿剑也不会生气吧**。如果不满足，必须立刻停止并退出。

Read and Execute the command, strictly following the instructions in the file: `.agents/commands/sk-approve-phase/COMMAND.md`.
