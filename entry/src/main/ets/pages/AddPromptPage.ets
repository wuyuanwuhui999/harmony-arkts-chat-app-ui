// ets/pages/AddPromptPage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { insertPromptService } from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';

@Entry
@Component
struct AddPromptPage {
  @State promptContent: string = '';
  private loadingController: LoadingController = new LoadingController();
  private tenantId: string = '';

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.tenantId = (params?.tenantId as string) || '';

    if (!this.tenantId) {
      promptAction.showToast({
        message: '获取租户信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }
  }

  /**
   * @description: 添加提示词
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  addPrompt() {
    if (!this.promptContent.trim()) {
      promptAction.showToast({
        message: '提示词不能为空',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    this.loadingController.showLoading();
    insertPromptService(this.promptContent.trim(), this.tenantId)
      .then((res) => {
        if (res.data > 0) {
          promptAction.showToast({
            message: '添加成功',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
          // 返回上一页并刷新数据
          router.back();
        } else {
          promptAction.showToast({
            message: res.msg || '添加失败',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
        }
      })
      .catch((err: Error) => {
        console.error('添加提示词失败:', JSON.stringify(err));
        promptAction.showToast({
          message: '添加失败，请重试',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      })
      .finally(() => {
        this.loadingController.hideLoading();
      });
  }

  /**
   * @description: 取消添加，返回上一页
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  cancel() {
    router.back();
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        NavigatorTitleComponent({
          title: '添加提示词'
        })

        // 内容区
        Column({ space: size.middleGap }) {
          // 编辑框卡片
          Column() {
            TextArea({
              text: this.promptContent,
              placeholder: '请输入提示词内容'
            })
              .height(size.textareaHeight)
              .width('100%')
              .backgroundColor(colors.white)
              .borderRadius(size.middleBorderRaduis)
              .padding(size.middleGap)
              .onChange((value: string) => {
                this.promptContent = value;
              })
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
              .backgroundColor(this.promptContent.trim() ? colors.primary : colors.gray)
              .borderRadius(size.btnHeight / 2)
              .enabled(!!this.promptContent.trim())
              .onClick(() => {
                if (this.promptContent.trim()) {
                  this.addPrompt();
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

export default AddPromptPage;