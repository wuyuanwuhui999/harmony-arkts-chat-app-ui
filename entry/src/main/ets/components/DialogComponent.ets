import * as colors from '../theme/color';
import * as size from '../theme/size';

/**
 * @description: 退出登录弹窗
 * @date: 2024-01-14 21:47
 * @author wuwenqiang
 */
@CustomDialog
export default struct DialogComponent {
  controller: CustomDialogController
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  };
  title: string = ""

  build() {
    Column() {
      Text(this.title)
        .padding(size.middleGap * 2)
      Row() {
        Text('取消')
          .onClick(() => {
            this.controller.close()
            this.cancel()
          })
          .flexGrow(1)
          .textAlign(TextAlign.Center)
          .backgroundColor(colors.white)
          .fontColor(Color.Black)
          .onClick(() => {
            this.cancel()
          })
        Divider().height('100%').width(1).backgroundColor(colors.pageBackground)
        Text('确定')
          .onClick(() => {
            this.confirm()
          })
          .flexGrow(1)
          .textAlign(TextAlign.Center)
          .backgroundColor(colors.white)
          .fontColor(Color.Red)
          .onClick(() => {
            this.confirm()
          })
      }.border({
        width: {
          top: 1,
        },
        color: {
          top: colors.pageBackground
        },
        style: {
          top: BorderStyle.Solid
        }
      }).alignItems(VerticalAlign.Center).width('100%').height(size.dialogBtnHeight)
    }
    .width('100%')
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .margin({ left: size.middleGap, right: size.middleGap })
  }
}