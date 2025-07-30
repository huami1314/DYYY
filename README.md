### DYYY 

用于调整抖音 UI 的 Tweak  
仅在 **34.2.0 版本** 中测试。  
**仅供学习交流，禁止用于商业用途。**  

#### **功能说明**  
- 通过 **双指长按** 或 **抖音设置** 进入设置界面  
- 功能自测

#### 远程配置

DYYY 可以通过远程 JSON 文件批量应用设置。默认下载地址在 `DYYYConstants.h` 中的 `DYYY_REMOTE_CONFIG_URL`。配置文件示例：

```json
{
    "mode": "DYYY_MODE_PATCH",
    "data": {
        "ExampleKey": true
    }
}
```

`mode` 字段可选，支持 `DYYY_MODE_PATCH` 和 `DYYY_MODE_REPLACE`，若省略则默认为补丁模式 (`DYYY_MODE_PATCH`)。

#### 解析下载接口

##### 示例1：多清晰度视频（含音频和封面）
```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "video_list": [
      {"url": "https://video.com/hd.mp4", "level": "高清"},
      {"url": "https://video.com/sd.mp4", "level": "标清"}
    ],
    "cover": "https://image.com/cover.jpg",
    "music": "https://audio.com/bgm.mp3",
    "images": [
      "https://image.com/extra1.jpg",
      "https://image.com/extra2.jpg"
    ]
  }
}
```

##### 示例2：单个视频资源（含封面）
```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "video_url": "https://video.com/main.mp4",
    "cover": "https://image.com/thumbnail.jpg",
    "music_url": "https://audio.com/soundtrack.mp3"
  }
}
```

##### 示例3：纯图片资源
```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "images": [
      "https://image.com/photo1.jpg",
      "https://image.com/photo2.jpg"
    ],
    "pics": "https://image.com/cover.png",
    "img": [
      "https://image.com/additional.jpg"
    ]
  }
}
```

##### 示例4：混合资源（视频+图片）
```json
{
  "code": 200,
  "msg": "success",
  "data": {
    "url": "https://video.com/short.mp4",
    "videos": [
      "https://video.com/extra.mp4"
    ],
    "cover": "https://image.com/poster.jpg",
    "images": [
      "https://image.com/screenshot1.png",
      "https://image.com/screenshot2.png"
    ]
  }
}
```

##### 字段说明
| 字段名       | 类型       | 说明                               |
| ------------ | ---------- | ---------------------------------- |
| `video_list` | 对象数组   | 多清晰度选项，含`url`和`level`字段 |
| `videos`     | 字符串数组 | 多个视频资源的URL集合              |
| `video_url`  | 字符串     | 单个视频资源URL（优先使用字段）    |
| `video`      | 字符串     | 单个视频资源URL（备用字段）        |
| `url`        | 字符串     | 通用资源URL（视频优先）            |
| `cover`      | 字符串     | 封面图URL（主字段）                |
| `pics`       | 字符串     | 封面图URL（备用字段）              |
| `music`      | 字符串     | 背景音乐URL（主字段）              |
| `music_url`  | 字符串     | 背景音乐URL（备用字段）            |
| `images`     | 字符串数组 | 附加图片资源集合                   |
| `img`        | 字符串数组 | 附加图片资源集合（备用字段）       |
