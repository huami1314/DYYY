# DYYY 源码修改记录

## 本次改动

1. **GIF 文件选择器**
   - 设置项 `DYYYProgressAnimationPath` 现在打开 iOS 系统文件选择器，不再要求手动填写绝对路径。
   - 选中的 GIF 会复制到应用沙盒 `Documents/DYYY/DYYYProgressAnimation.gif`，并将路径写入 `DYYYProgressAnimationPath`。
   - 在 `AWEFeedProgressSlider` 上加入 GIF 覆盖层逻辑，并使用 ImageIO 解析 GIF 帧。
   - 设置项显示已导入 GIF 的文件名。

2. **本地评论语音包管理**
   - 语音包列表可将音频路径写入 `DYYYSelectedVoicePackPath`，并以勾选状态显示当前选择。
   - 增加 `DYYYSelectedVoicePackURL()` 供后续提交 Hook 读取所选音频。
   - **重要限制：当前源码没有找到抖音语音评论录制/上传/提交的真实入口。** 已检查本项目 `DYYY.xm` 和 `AwemeHeaders.h`，现有相关代码是读取已发布评论的 `AWECommentAudioModel` 用于下载分享；它不是发布语音评论的入口。因此本次没有添加猜测性的提交 Hook，也不能声称所选音频已经替换真实评论发送内容。要完成这一步，需要针对目标抖音版本的类/方法运行时信息或录制提交时的调用栈/日志。

3. **Makefile**
   - 保留项目现有 `DYYYFeatureTools.m` 编译项、iOS 14.0 deployment target、AVFAudio 弱链接及 CoreAudio framework 配置；本次新增代码放在已编译的 `DYYYFeatureTools.m` 中，无需新增源文件。

## 验证状态

- 已进行源码文本检查，确认设置项调用 GIF picker、GIF 路径存储键一致，且 Makefile 已包含 `DYYYFeatureTools.m`。
- 未运行 Theos/Logos 构建；本环境没有确认可用的完整 iOS 构建链，因此**未编译验证**。
- 未在 iPhone / 抖音目标版本上运行；GIF 覆盖显示和文件访问权限仍需设备测试。
- 本源码 ZIP 不是已编译、签名或可直接安装的 IPA/DEB。


## 版本 3.0 打包修正（2026-10-22）

- 在 Makefile 中显式设置 `THEOS_PACKAGE_BASE_VERSION = 3.0`，避免只修改 control 或界面版本而实际生成的 Debian 包仍显示旧版本。
- GIF 设置项源码调用 `DYYYPresentProgressGIFPicker`；如果安装后仍出现旧输入框，说明实际安装的构建产物并非包含该源码的版本，或运行时仍加载了旧 dylib。
- 此 ZIP 尚未在当前环境使用 Theos 重新编译；语音上传 Hook 仍需目标抖音版本的运行日志和实机测试确认。
