# Lifecycle Safety Hardening Notes

## 新增工具
- `AWMSafeDispatchTimer`：封装 `dispatch_source_t`，提供幂等启停、在 `dealloc` 中自动取消，避免尾帧回调。
- `DYYYLifecycleSafety.h`：提供 `weakify/strongify` 宏、`DYYYDispatchAfterWeak` 辅助以及 Debug 日志宏（仅 Debug 生效）。

## 改造要点
- 所有 block 回调使用 `weakify/strongify` 判空早退，避免访问已释放对象。
- 定时器统一增加 `stop/cancel`，在退出流程和 `dealloc` 中保证释放；使用新的安全封装或显式 `invalidate`。
- 通知/监听改造为显式保存 token，并在退出/析构时移除。
- `dispatch_after`、动画回调等异步逻辑通过 `DYYYDispatchAfterWeak` 或手动弱引用防止悬空调用。
- Debug 模式下新增日志（`DYYYDebugLog`），用于确认定时器与监听的生命周期。

## 测试与验证
- 提供 `Tests/run_tests.sh` 运行最小化生命周期校验。该脚本在 macOS 命令行环境中依赖 `Foundation`，如遇崩溃请在目标 iOS 环境或 Xcode 工程中复现执行。
- 建议在真机上重点回归：纯净模式按钮自动恢复、浮动按钮显示/隐藏、通知驱动的界面刷新。

## 注意事项
- `AWMSafeDispatchTimer` 默认在 `cancel` 时置空 handler，无需额外清理。
- 若需在 Release 关闭日志，可确保 `DEBUG=0`，宏将变为空操作。
- 外部 SDK 回调仍需在入口做弱引用判空；对无法改动的 SDK，可参考新封装将回调包裹在安全层。

