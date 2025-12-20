# 👁️ 隐形守护者 (R-Vision)

<div align="center">

![OpenHarmony](https://img.shields.io/badge/OpenHarmony-5.0-blue)
![RISC-V](https://img.shields.io/badge/Arch-RISC--V-red)
![Device](https://img.shields.io/badge/Device-SpacemiT_K1-orange)
![Language](https://img.shields.io/badge/Language-ArkTS-green)
![License](https://img.shields.io/badge/License-Apache_2.0-lightgrey)

**基于 RISC-V 架构与 OpenHarmony 的原生图像隐写与高性能处理引擎**

[核心技术](#-核心技术-technology) • [快速开始](#-快速开始-quick-start)

</div>

---

## 📖 项目简介 (Introduction)

**隐形守护者 (R-Vision)** 是一款专为 **RISC-V (进迭时空 K1)** 芯片打造的 OpenHarmony 原生图像处理应用。

本项目旨在验证 OpenHarmony 在 RISC-V 架构上的多媒体处理潜力。不同于调用现成的第三方库，R-Vision 通过 **ArkTS** 直接操作底层的内存二进制流（ArrayBuffer），实现了**毫秒级**的图像编解码、像素级算法处理以及**LSB (Least Significant Bit) 隐写术**。

> 🚩 **参赛作品**：本项目为 **“WIN精彩·邮你创” / “OpenHarmony+RISC-V千人应用开发实践活动”** 参赛作品。

## ✨ 核心功能 (Features)

### 1. 🕵️ 隐形守护者 (LSB Steganography)
- **原理**：利用位运算，将文本信息的二进制流写入图片 RGB 通道的最低有效位。
- **效果**：肉眼完全无法察觉图片变化，但可以携带大量加密信息（支持中/英文/特殊字符）。
- **应用**：版权保护、隐蔽通信、数字水印。

### 2. ⚡ 性能仪表盘 (Performance Dashboard)
- **实时监控**：内置算法计时器，精确捕捉 RISC-V 芯片处理百万级像素点的内存吞吐耗时。
- **硬件验证**：直观展示 K1 芯片在纯软件算法下的算力表现。

### 3. 🎨 原生像素引擎
- **无依赖**：不使用 OpenCV 等重型库，纯手写算法实现。
- **全流程**：打通了从 `PhotoViewPicker` 选图 -> `PixelMap` 解码 -> `ArrayBuffer` 修改 -> UI 渲染的全链路。


## 🛠️ 核心技术 (Technology)

本项目涉及的核心技术点与算法逻辑：

### 1. 位运算隐写算法
核心代码片段展示了如何通过掩码操作 (`& 0xFE`) 清除最低位，并写入信息位 (`| bit`)：

```typescript
// LSB 核心逻辑 (Core Algorithm)
for (let i = 0; i < pixelData.length; i += 4) {
  // ...省略外层循环
  // 清零最低位 (Mask: 11111110) 并写入新比特
  pixelData[i + offset] = (pixelData[i + offset] & 0xFE) | bit; 
}
```

### 2. 开发环境规格
- **硬件设备**: SpacemiT K1 (RISC-V 64bit)
- **操作系统**: OpenHarmony 5.0 Release
- **开发工具**: DevEco Studio 5.0.5.310
- **SDK 版本**: OpenHarmony API 12 (Full SDK)

## 📂 项目结构 (Structure)

```text
R-Vision
├── entry/src/main/ets
│   ├── pages
│   │   └── Index.ets      // 核心业务逻辑与UI布局 (LSB算法/UI)
│   └── entryability
│       └── EntryAbility.ts
├── build-profile.json5    // 编译架构配置 (RuntimeOS: OpenHarmony)
└── resources              // 静态资源
```

## 🚀 快速开始 (Quick Start)

想要在你的 K1 设备上运行此项目？请遵循以下步骤：

### 1. 环境准备
确保你安装了 **DevEco Studio 5.0+** 并下载了 **OpenHarmony API 12 Full SDK**（注意：Public SDK 可能无法调用底层 Image 写入接口）。

### 2. 克隆代码
```bash
git clone [https://github.com/Laurel-11/R-Vision.git](https://github.com/Laurel-11/R-Vision.git)
```

### 3. 签名配置 (关键)
由于 K1 设备通常需要调试签名，请在 `build-profile.json5` 或 IDE 的 **Signing Configs** 中：
- 取消勾选 "Support HarmonyOS"
- 确保 `runtimeOS` 设置为 `"OpenHarmony"`

### 4. 编译与安装
```bash
# 进入项目目录
hvigorw assembleHap
# 或使用 hdc/bm 工具安装
bm install -p entry/build/default/outputs/default/entry-default-signed.hap
```

## 🤝 贡献与致谢 (Credits)
感谢 **进迭时空 (SpacemiT)** 提供 RISC-V 硬件支持，以及 **OpenHarmony 社区** 的技术文档。

---

**Developed with ❤️ by Laurel-11**
