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
