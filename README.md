# 夜光 · Lumen

透明音乐壁纸主题 `nekotune.theme-lumen`（1.0.0）。中央三行歌词，底部半透明音乐卡片、
封面、青色辉光和真实频谱。没有播放控制图标，整个壁纸鼠标穿透。
主题不包含全屏背景图；已有系统壁纸继续显示。毛玻璃质感由透明深色和细描边实现，不模糊其他程序的桌面内容。

## 构建与启用

```sh
cmake -S . -B build -G Ninja
cmake --build build
ctest --test-dir build --output-on-failure
```

安装 `build/packages/nekotune.theme-lumen.nktheme.zip`，或在宿主挂载 `theme/`。
含 QML 的壁纸需要用户确认信任。宿主需要本次新增的歌词排版属性及跨平台透明能力。

在「设置 → 动态音乐壁纸」中：

1. 壁纸样式选择「跟随当前主题」，主题壁纸来源选择「夜光 · Lumen」。
2. 开启「透明叠加」，关闭「封面背景」，手动开启壁纸。
3. 安装、信任并启用独立扩展 `nekotune.spectrum`，使用默认 FFmpeg 播放后端。

选择壁纸来源不会改变当前应用界面或主动启用壁纸。主题也不会改写这些设置。
没有频谱扩展时，歌曲和歌词仍然展示；播放时频谱区域提示如何启用。
Qt 兼容播放后端会显示不支持频谱，不回退到系统录音。

横屏参照 1296×734 参考图，卡片宽约 64%、底部留约 15%；最大宽 1400 逻辑像素。
竖屏和窄屏把频谱放在卡片下半部。下一句开关和歌词开关沿用宿主设置。
位置、歌词身份和逐字同步复用宿主组件；减少动态效果、零装饰强度、暂停或隐藏时停止频谱与辉光动画。

## 验证

纯打包无需 Qt 或 C++；可选 `-DLUMEN_QML_TESTS=ON` 使用 Qt Quick Test 测试租约与事件状态机。
独立测试使用测试替身；宿主测试使用真实 ExtensionApi 和 QVariantList 事件。

在宿主构建目录运行 `nekotune_wallpaper_test externalWallpaper`，设置
`NEKOTUNE_TEST_WALLPAPER_THEME_DIR=/path/to/lumen/theme` 和可选
`NEKOTUNE_TEST_SCREENSHOT_DIR=/path/to/evidence`，验证横屏、竖屏、小屏、透明 alpha 和频谱接收。
测试截图中的山水背景来自宿主测试资源，仅用于合成效果检查，不包含在主题包中；频谱为明确的测试事件。
原生 Wayland 验收额外设置 `NEKOTUNE_TEST_NATIVE_WALLPAPER=1`、`QT_QPA_PLATFORM=wayland`。

Windows 10/11 的透明嵌入、混合 DPI 和 Explorer 重启需要真机验收。离屏截图只验证 QML 显示及 alpha。
CI 生成本地构建附件，不自动创建 Release。视觉检查记录见 `design-qa.md`。
