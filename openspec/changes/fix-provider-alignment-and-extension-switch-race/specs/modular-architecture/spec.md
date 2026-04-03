## MODIFIED Requirements

### Requirement: Extension Mode Switching Race Safety
当通过快捷键连续在不同扩展模式之间快速切换时，系统 MUST 保证模式切换的原子性和一致性，不允许出现界面显示错误（如一个扩展的界面展示了另一个扩展的内容）。

#### Scenario: Rapid switch from custom extension to ClaudeCode
- **WHEN** 用户先按快捷键进入自定义扩展 A，然后在极短时间内（< 0.2 秒）按快捷键进入 ClaudeCode 扩展
- **THEN** 面板最终 MUST 正确显示 ClaudeCode 扩展的内容，不出现自定义扩展 A 的残留内容

#### Scenario: Rapid switch from ClaudeCode to custom extension
- **WHEN** 用户先按快捷键进入 ClaudeCode 扩展，然后在极短时间内按快捷键进入自定义扩展 B
- **THEN** 面板最终 MUST 正确显示自定义扩展 B 的内容，不出现 ClaudeCode 的残留内容

#### Scenario: Multiple rapid switches
- **WHEN** 用户在 1 秒内连续按多个不同扩展的快捷键 3 次以上
- **THEN** 面板最终 MUST 正确显示最后一次快捷键对应的扩展内容，且中间过程不出现内容混合

#### Scenario: ClaudeCode mode entry is synchronous
- **WHEN** ClaudeCode 扩展的快捷键通知 `handleEnterClaudeCodeModeDirectly` 被触发
- **THEN** 模式切换 MUST 同步完成，不使用 asyncAfter 等异步延迟
