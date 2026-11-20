# DYYY3

基于 Theos / Logos 的抖音 UI 调整 Tweak，适配 **抖音 41.2.0**，当前版本 `3.0`。

> 仅供学习交流，禁止用于任何商业用途，请在下载后 24 小时内自行删除。

- 支持方案：rootless / roothide
- 系统要求：iOS 14.0+
- 进入设置：抖音内 **双指长按**，或在 **抖音「设置」页** 找到 DYYY 入口

## 说明

41.x 之后抖音大量界面迁移到 Swift 模块，并改用新的播放架构，旧版本的不少功能因此失效。本版针对 41.2.0 重新适配，并将部分 UI 逻辑下沉到数据层，以提升稳定性与抗改版能力。

## 目录

- [构建与打包](#构建与打包)
- [远程配置](#远程配置)
- [解析下载接口](#解析下载接口)
- [许可证](#许可证)

## 构建与打包

需先配置 [Theos](https://github.com/roothide/theos)（roothide 分支）及对应 iOS SDK。

```bash
# roothide 方案打包
make package SCHEME=roothide FINALPACKAGE=1

# rootless 方案
make package SCHEME=rootless FINALPACKAGE=1

# 安装到设备（需配置 THEOS_DEVICE_IP）
make package INSTALL=1

# CI / 无人值守
GITHUB_ACTIONS=true make package
```

产物输出到 `packages/`。建议用 `Makefile.local` 覆盖 `THEOS_DEVICE_IP` 等本地配置，不要直接改主 `Makefile`。

## 远程配置

可通过远程 JSON 批量下发设置，默认地址见 `DYYYConstants.h` 的 `DYYY_REMOTE_CONFIG_URL`：

```json
{
  "mode": "DYYY_MODE_PATCH",
  "data": {
    "ExampleKey": true
  }
}
```

`mode` 可选 `DYYY_MODE_PATCH`（补丁，默认）或 `DYYY_MODE_REPLACE`（覆盖）。

## 解析下载接口

自定义下载接口返回 JSON 时，按以下字段解析视频、图片、音频与封面。

```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "video_list": [
      { "url": "https://video.com/hd.mp4", "level": "高清" },
      { "url": "https://video.com/sd.mp4", "level": "标清" }
    ],
    "video_url": "https://video.com/main.mp4",
    "cover": "https://image.com/cover.jpg",
    "music": "https://audio.com/bgm.mp3",
    "images": [
      "https://image.com/photo1.jpg",
      "https://image.com/photo2.jpg"
    ]
  }
}
```

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `video_list` | 对象数组 | 多清晰度选项，含 `url` 与 `level` |
| `videos` | 字符串数组 | 多个视频 URL |
| `video_url` | 字符串 | 单个视频 URL（优先） |
| `video` | 字符串 | 单个视频 URL（备用） |
| `url` | 字符串 | 通用资源 URL（视频优先） |
| `cover` | 字符串 | 封面图 URL（主） |
| `pics` | 字符串 | 封面图 URL（备用） |
| `music` | 字符串 | 背景音乐 URL（主） |
| `music_url` | 字符串 | 背景音乐 URL（备用） |
| `images` | 字符串数组 | 附加图片集合 |
| `img` | 字符串数组 | 附加图片集合（备用） |

## 许可证

详见 [`LICENSE`](LICENSE)。
