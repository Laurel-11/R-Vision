import picker from '@ohos.file.picker';
import fs from '@ohos.file.fs';
import image from '@ohos.multimedia.image';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct Index {
  @State displayedImage: PixelMap | undefined = undefined;
  @State statusMsg: string = '请先选择图片';
  @State secretInput: string = '';
  @State processTime: number = 0;
  @State imgResolution: string = '0 x 0';

  private context = getContext(this) as common.UIAbilityContext;

  // 选择图片
  async selectImage() {
    try {
      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoViewPicker = new picker.PhotoViewPicker();
      const result = await photoViewPicker.select(photoSelectOptions);

      if (result.photoUris.length > 0) {
        await this.loadPixelMap(result.photoUris[0]);
        this.statusMsg = "图片加载就绪";
      }
    } catch (err) {
      console.error(`Select failed: ${JSON.stringify(err)}`);
    }
  }

  // 读取并解码图片
  async loadPixelMap(uri: string) {
    try {
      let file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      const imageSource = image.createImageSource(file.fd);
      let options: image.DecodingOptions = { editable: true };
      let pixelMap = await imageSource.createPixelMap(options);

      this.displayedImage = pixelMap;

      // 获取分辨率信息
      let info = await pixelMap.getImageInfo();
      this.imgResolution = `${info.size.width} x ${info.size.height}`;

      fs.closeSync(file);
    } catch (e) {
      console.error('Load failed', e);
    }
  }

  // 核心功能：LSB 隐写加密
  async hideInfo() {
    if (!this.displayedImage || !this.secretInput) {
      promptAction.showToast({ message: '请确保有图片和输入的文字' });
      return;
    }

    let startTime = new Date().getTime();
    this.statusMsg = "正在加密...";

    try {
      // 1. 将字符串转换为 Uint8Array (UTF-8编码)，并添加结束符 0x00
      let textEncoder = new util.TextEncoder();
      let textData = textEncoder.encodeInto(this.secretInput);
      let payload = new Uint8Array(textData.length + 1);
      payload.set(textData);
      payload[textData.length] = 0; // 结束标记

      // 2. 读取像素数据
      let info = await this.displayedImage.getImageInfo();
      let bufferSize = info.size.width * info.size.height * 4;
      let buffer = new ArrayBuffer(bufferSize);
      await this.displayedImage.readPixelsToBuffer(buffer);
      let pixelData = new Uint8Array(buffer);

      // 检查容量是否足够 (每个像素存3bit: R,G,B)
      if (payload.length * 8 > pixelData.length / 4 * 3) {
        promptAction.showToast({ message: '文本过长，图片容量不足' });
        return;
      }

      // 3. 执行 LSB 替换算法
      let dataIndex = 0; // 当前处理的 payload 字节索引
      let bitIndex = 0;  // 当前处理的字节中的位索引 (0-7)

      // 遍历像素 (步长为4: R,G,B,A)
      for (let i = 0; i < pixelData.length; i += 4) {
        if (dataIndex >= payload.length) break;

        // 当前需要写入的字节
        let byte = payload[dataIndex];

        // 分别处理 R, G, B 三个通道
        for (let offset = 0; offset < 3; offset++) {
          if (bitIndex > 7) {
            bitIndex = 0;
            dataIndex++;
            if (dataIndex >= payload.length) break;
            byte = payload[dataIndex];
          }

          // 取出当前位 (0 或 1)
          let bit = (byte >> bitIndex) & 1;

          // 修改像素值的最低位：先清零最低位，再或上新值
          pixelData[i + offset] = (pixelData[i + offset] & 0xFE) | bit;

          bitIndex++;
        }
      }

      // 4. 写回图片
      await this.displayedImage.writeBufferToPixels(buffer);

      // 5. 记录性能
      let endTime = new Date().getTime();
      this.processTime = endTime - startTime;
      this.statusMsg = "加密成功！信息已隐藏";
      promptAction.showToast({ message: '信息已隐藏进图片' });

    } catch (e) {
      console.error("Encrypt failed", e);
      this.statusMsg = "加密失败";
    }
  }

  // 核心功能：LSB 隐写解密
  async decryptInfo() {
    if (!this.displayedImage) return;

    let startTime = new Date().getTime();
    this.statusMsg = "正在解密...";

    try {
      let info = await this.displayedImage.getImageInfo();
      let buffer = new ArrayBuffer(info.size.width * info.size.height * 4);
      await this.displayedImage.readPixelsToBuffer(buffer);
      let pixelData = new Uint8Array(buffer);

      let extractedBytes: number[] = [];
      let currentByte = 0;
      let bitCount = 0;

      // 使用标签来控制外层循环的退出
      loopPixels:
        for (let i = 0; i < pixelData.length; i += 4) {
          for (let offset = 0; offset < 3; offset++) {
            // 提取 R,G,B 的最低位
            let bit = pixelData[i + offset] & 1;

            // 组装字节
            currentByte |= (bit << bitCount);
            bitCount++;

            if (bitCount === 8) {
              if (currentByte === 0) {
                // 读到结束符 0x00，跳出最外层循环
                break loopPixels;
              }
              extractedBytes.push(currentByte);
              currentByte = 0;
              bitCount = 0;
            }
          }
        }

      // 解码二进制数据为字符串
      // 修正点：去掉 new，create 是静态方法
      let textDecoder = util.TextDecoder.create("utf-8");
      let resultUint8 = new Uint8Array(extractedBytes);
      let decodedString = textDecoder.decodeWithStream(resultUint8);

      let endTime = new Date().getTime();
      this.processTime = endTime - startTime;

      // 弹窗显示结果
      promptAction.showDialog({
        title: '解密结果',
        message: decodedString.length > 0 ? decodedString : '未发现隐藏信息',
        buttons: [{ text: '确定', color: '#000000' }]
      });
      this.statusMsg = "解密完成";

    } catch (e) {
      console.error("Decrypt failed", e);
      this.statusMsg = "解密失败";
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Text('隐形守护者 (R-Vision)')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 10 })

      // 性能仪表盘
      Row() {
        Column() {
          Text('处理耗时')
            .fontSize(12)
            .fontColor(Color.Gray)
          Text(this.processTime + ' ms')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#E64566')
        }.alignItems(HorizontalAlign.Start).margin({ right: 30 })

        Column() {
          Text('分辨率')
            .fontSize(12)
            .fontColor(Color.Gray)
          Text(this.imgResolution)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
        }.alignItems(HorizontalAlign.Start)
      }
      .width('90%')
      .padding(15)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 5, color: '#1A000000', offsetY: 2 })
      .margin({ bottom: 15 })

      // 图片展示区
      Stack() {
        if (this.displayedImage) {
          Image(this.displayedImage)
            .objectFit(ImageFit.Contain)
            .width('100%')
            .height('100%')
        } else {
          Column() {
            Text("NO IMAGE")
              .fontColor('#CCCCCC')
              .fontWeight(FontWeight.Bold)
          }
        }
      }
      .width('90%')
      .height('40%')
      .backgroundColor('#F0F2F5')
      .borderRadius(12)
      .margin({ bottom: 15 })

      // 信息输入区
      TextInput({ placeholder: '在此输入要隐藏的秘密信息...', text: this.secretInput })
        .onChange((value: string) => {
          this.secretInput = value;
        })
        .width('90%')
        .height(45)
        .margin({ bottom: 15 })
        .backgroundColor('#F9F9F9')

      // 操作按钮区
      Row() {
        Button('选图')
          .onClick(() => this.selectImage())
          .backgroundColor('#888888')
          .width('20%')
          .margin({ right: 10 })

        Button('加密隐藏')
          .onClick(() => this.hideInfo())
          .backgroundColor('#0A59F7')
          .width('35%')
          .margin({ right: 10 })

        Button('读取解密')
          .onClick(() => this.decryptInfo())
          .backgroundColor('#E64566')
          .width('35%')
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(this.statusMsg)
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 15 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}