import * as colors from '../theme/color';
import * as size from '../theme/size';

/**
 * @description: 修改新别弹窗
 * @date: 2024-01-14 21:47
 * @author wuwenqiang
 */
@CustomDialog
export default struct OptionDialogComponent {
  controller: CustomDialogController
  cancel: () => void = () => {
  };
  confirm: (value: string,index:number) => void = () => {
  };
  options: Array<string> = []

  build() {
    Column() {
      Column() {
        ForEach(this.options, (item: string, index: number) => {
          Text(item)
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding(size.middleGap)
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis)
            .onClick(() => {
              this.confirm(item,index)
            })
          if (index !== this.options.length - 1) {
            Divider()
              .height(1)
              .backgroundColor(colors.pageBackground)
          }
        })
      }.backgroundColor(colors.white)
      .borderRadius(size.middleBorderRaduis)
      .padding({ left: size.middleGap, right: size.middleGap })

      Divider()
        .height(size.middleGap)
        .backgroundColor(Color.Transparent)
      Text('取消')
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding(size.middleGap)
        .backgroundColor(colors.white)
        .borderRadius(size.middleBorderRaduis)
        .onClick(() => {
          this.cancel()
        })
      Divider()
        .height(size.middleGap)
        .backgroundColor(Color.Transparent)
    }.width('100%').backgroundColor(Color.Transparent).padding({ left: size.middleGap, right: size.middleGap })
  }
}