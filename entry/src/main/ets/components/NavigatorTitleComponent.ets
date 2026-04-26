import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
@Component
export default struct NavigatorTitleComponent {
  @Prop title: string;

  // 新增：右侧自定义内容构建器，可选参数
  @BuilderParam rightContent?: () => void;

  build() {
    Row() {
      // 左侧返回图标
      Image($r('app.media.icon_back'))
        .width(size.smallIcon)
        .height(size.smallIcon)
        .opacity(size.opacity)
        .onClick(() => {
          router.back()
        })

      // 标题
      Text(this.title)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)

      // 右侧内容 - 动态内容
      // 如果有传入自定义内容，则显示，否则显示隐藏的占位图标
      if (this.rightContent) {
        this.rightContent()
      } else {
        Image($r('app.media.icon_back'))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .visibility(Visibility.Hidden)
      }
    }
    .width('100%')
    .padding(size.middleGap)
    .backgroundColor(colors.white)
  }
}