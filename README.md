# 👁️ 隐形守护者 (R-Vision)

<div align="center">

![OpenHarmony](https://img.shields.io/badge/OpenHarmony-5.0-blue)
![RISC-V](https://img.shields.io/badge/Arch-RISC--V-red)
![Device](https://img.shields.io/badge/Device-SpacemiT_K1-orange)
![Language](https://img.shields.io/badge/Language-ArkTS-green)
![License](https://img.shields.io/badge/License-Apache_2.0-lightgrey)

**基于 RISC-V 架构与 OpenHarmony 的原生图像隐写与高性能处理引擎**

[查看演示](#-运行演示-demo) • [核心技术](#-核心技术-technology) • [快速开始](#-快速开始-quick-start)

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

## 🖼️ 运行演示 (Demo)

| 加密前 (Original) | 性能监控 (Monitor) | 解密演示 (Decoded) |
|:---:|:---:|:---:|
| ![Original](resources/base/media/app_icon.png) | *(此处建议替换为你的仪表盘截图)* | *(此处建议替换为解密弹窗截图)* |

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
