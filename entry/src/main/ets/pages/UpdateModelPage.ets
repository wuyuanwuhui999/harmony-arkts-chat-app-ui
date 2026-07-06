// ets/pages/UpdateModelPage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { ModelType, UpdateModelParams } from '../type/Index';
import { updateModelService } from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import OptionDialogComponent from '../components/OptionDialogComponent';

@Entry
@Component
struct UpdateModelPage {
  @State modelName: string = '';
  @State type: ModelType = 'ollama';
  @State baseUrl: string = '';
  @State apiKey: string = '';
  private loadingController: LoadingController = new LoadingController();
  private modelId: string = '';
  private companyId: string = '';
  private dialogController: CustomDialogController | null = null;

  // 表单是否完整（必填项：模型名称、类型、模型地址）
  private get isFormValid(): boolean {
    return this.modelName.trim() !== '' &&
      this.baseUrl.trim() !== '';
  }

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  @Styles
  inputRowStyle() {
    .border({
      width: { bottom: 1 },
      color: { bottom: colors.borderColor },
      style: { bottom: BorderStyle.Solid }
    })
    .borderRadius(0)
    .backgroundColor(Color.Transparent)
    .width('80%')
  }

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.modelId = (params?.modelId as string) || '';
    this.modelName = (params?.modelName as string) || '';
    this.type = (params?.type as ModelType) || 'ollama';
    this.baseUrl = (params?.baseUrl as string) || '';
    this.apiKey = (params?.apiKey as string) || '';
    this.companyId = (params?.companyId as string) || '';

    if (!this.modelId) {
      promptAction.showToast({
        message: '获取模型信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }
  }

  /**
   * @description: 更新模型
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  updateModel() {
    if (!this.isFormValid) {
      promptAction.showToast({
        message: '请完整填写必填项',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    const params: UpdateModelParams = {
      id: this.modelId,
      modelName: this.modelName.trim(),
      type: this.type,
      companyId: this.companyId,
      baseUrl: this.baseUrl.trim(),
      apiKey: this.apiKey.trim() || undefined
    };

    this.loadingController.showLoading();
    updateModelService(params)
      .then((res) => {
        if (res.data > 0) {
          promptAction.showToast({
            message: '更新成功',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
          // 返回上一页并刷新数据
          router.back();
        } else {
          promptAction.showToast({
            message: res.msg || '更新失败',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
        }
      })
      .catch((err: Error) => {
        console.error('更新模型失败:', JSON.stringify(err));
        promptAction.showToast({
          message: '更新失败，请重试',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      })
      .finally(() => {
        this.loadingController.hideLoading();
      });
  }

  /**
   * @description: 取消更新，返回上一页
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  cancel() {
    router.back();
  }

  /**
   * @description: 显示模型类型选择弹窗
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  showModelTypeDialog() {
    this.dialogController = new CustomDialogController({
      customStyle: true,
      builder: OptionDialogComponent({
        cancel: (): void => this.dialogController?.close(),
        confirm: (value: string, index: number): void => {
          this.type = index === 0 ? 'ollama' : 'online';
          this.dialogController?.close();
        },
        options: ['Ollama', '在线模型'],
      }),
      alignment: DialogAlignment.Bottom,
    });
    this.dialogController.open();
  }

  /**
   * @description: 获取模型类型显示文本
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  private getTypeText(): string {
    return this.type === 'ollama' ? 'Ollama' : '在线模型';
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        NavigatorTitleComponent({
          title: '编辑模型'
        })

        // 内容区
        Column({ space: size.middleGap }) {
          // 表单卡片
          Column() {
            // 模型名称
            Row() {
              Row() {
                Text('*').fontColor(colors.warn).fontSize(size.middleFont)
                Text('模型名称:').fontSize(size.middleFont)
              }
              .width('25%')

              TextInput({
                placeholder: '请输入模型名称',
                text: this.modelName
              })
                .inputRowStyle()
                .fontSize(size.middleFont)
                .onChange((value: string) => {
                  this.modelName = value;
                })
            }
            .width('100%')
            .padding({ top: size.smallGap, bottom: size.smallGap })
            .alignItems(VerticalAlign.Center)

            // 模型类型
            Row() {
              Row() {
                Text('*').fontColor(colors.warn).fontSize(size.middleFont)
                Text('模型类型:').fontSize(size.middleFont)
              }
              .width('25%')

              Text(this.getTypeText())
                .fontSize(size.middleFont)
                .fontColor(colors.black)
                .width('80%')
                .padding({ top: size.smallGap, bottom: size.smallGap })
            }
            .width('100%')
            .border({
              width: { bottom: 1 },
              color: { bottom: colors.borderColor },
              style: { bottom: BorderStyle.Solid }
            })
            .onClick(() => {
              this.showModelTypeDialog();
            })
            .alignItems(VerticalAlign.Center)

            // 模型地址
            Row() {
              Row() {
                Text('*').fontColor(colors.warn).fontSize(size.middleFont)
                Text('模型地址:').fontSize(size.middleFont)
              }
              .width('25%')


              TextInput({
                placeholder: '请输入模型地址',
                text: this.baseUrl
              })
                .inputRowStyle()
                .fontSize(size.middleFont)
                .onChange((value: string) => {
                  this.baseUrl = value;
                })
            }
            .width('100%')
            .padding({ top: size.smallGap, bottom: size.smallGap })
            .alignItems(VerticalAlign.Center)

            // API Key（可选）
            Row() {
              Row() {
                Text('API Key:')
                  .width('25%')
                  .fontSize(size.middleFont)
              }
              .width('25%')

              TextInput({
                placeholder: '请输入API Key（可选）',
                text: this.apiKey
              })
                .inputRowStyle()
                .fontSize(size.middleFont)
                .onChange((value: string) => {
                  this.apiKey = value;
                })
            }
            .width('100%')
            .padding({ top: size.smallGap, bottom: size.smallGap })
            .alignItems(VerticalAlign.Center)
          }
          .blockStyle()

          // 确定/取消按钮
          Row({ space: size.middleGap }) {
            Text('取消')
              .width('45%')
              .height(size.btnHeight)
              .textAlign(TextAlign.Center)
              .fontColor(colors.gray)
              .border({
                width: 1,
                color: colors.gray,
                style: BorderStyle.Solid
              })
              .borderRadius(size.btnHeight / 2)
              .onClick(() => {
                this.cancel();
              })

            Text('确定')
              .width('45%')
              .height(size.btnHeight)
              .textAlign(TextAlign.Center)
              .fontColor(Color.White)
              .backgroundColor(this.isFormValid ? colors.primary : colors.gray)
              .borderRadius(size.btnHeight / 2)
              .enabled(this.isFormValid)
              .onClick(() => {
                if (this.isFormValid) {
                  this.updateModel();
                }
              })
          }
          .width('100%')
          .margin({ top: size.middleGap })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(colors.pageBackground)
        .padding({
          left: size.middleGap,
          right: size.middleGap,
          bottom: size.middleGap
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(colors.pageBackground)

      // 加载组件
      GlobalLoading({ controller: this.loadingController })
    }
    .width('100%')
    .height('100%')
  }
}

export default UpdateModelPage;