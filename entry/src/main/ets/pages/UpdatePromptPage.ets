// ets/pages/UpdatePromptPage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { PromptInterface, UpdatePromptParamsType } from '../type/Index';
import { updatePromptService } from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';

@Entry
@Component
struct UpdatePromptPage {
  @State promptContent: string = ''; // 提示词内容
  private promptId: string = ''; // 提示词id
  private loadingController: LoadingController = new LoadingController();

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  aboutToAppear() {
    // 上一页把提示词对象直接传递过来
    const params = router.getParams() as Record<string, Object>;
    const promptItem: PromptInterface = (params?.prompt as PromptInterface) || {} as PromptInterface;
    this.promptId = promptItem.id || '';
    this.promptContent = promptItem.prompt || '';

    if (!this.promptId) {
      promptAction.showToast({
        message: '获取提示词信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }
  }

  /**
   * @description: 更新提示词
   * @date: 2026-09-19
   * @author wuwenqiang
   */
  updatePrompt() {
    if (!this.promptContent.trim()) {
      promptAction.showToast({
        message: '提示词不能为空',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    const params: UpdatePromptParamsType = {
      id: this.promptId,
      prompt: this.promptContent.trim()
    };

    this.loadingController.showLoading();
    updatePromptService(params)
      .then((res) => {
        if (res.data > 0) {
          promptAction.showToast({
            message: '更新成功',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
          // 关闭更新提示词页面，回到提示词弹窗后点击刷新按钮即可看到最新的提示词
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
        console.error('更新提示词失败:', JSON.stringify(err));
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
   * @date: 2026-09-19
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
          title: '更新提示词'
        })

        // 内容区：灰色背景 + 标准内间距 + 占满剩余空间
        Column({ space: size.middleGap }) {
          // 文本框卡片：高度占满内容区剩余高度
          Column() {
            TextArea({
              text: this.promptContent,
              placeholder: '请输入提示词内容'
            })
              .height('100%')
              .width('100%')
              .backgroundColor(colors.white)
              .borderRadius(size.middleBorderRaduis)
              .padding(size.middleGap)
              .onChange((value: string) => {
                this.promptContent = value;
              })
          }
          .blockStyle()
          .layoutWeight(1)

          // 取消/确定按钮
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
                  this.updatePrompt();
                }
              })
          }
          .width('100%')
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

export default UpdatePromptPage;
