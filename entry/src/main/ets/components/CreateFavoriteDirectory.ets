import * as colors from '../theme/color';
import * as size from '../theme/size';
import { FavoriteDirectoryType } from '../type/Index';
import { insertFavoriteDirectoryService } from '../service/Index';
import promptAction from '@ohos.promptAction';
import display from '@ohos.display';

@Component
export default struct CreateFavoriteDirectory {
  @State checkboxValue: Array<number> = [];
  @State favoriteDirectoryList: Array<FavoriteDirectoryType> = [];
  @State favoriteName: string = '';
  public onCreateDirectory: (favoriteDirectory: FavoriteDirectoryType) => void = () => {
  };
  public onCancleCreateDirectory: () => void = () => {
  };

  build() {
    Column({ space: size.pagePadding }) {
      Row() {
        Text('*').fontColor(Color.Red)
        Text('名称')
        TextInput({ text: this.favoriteName, placeholder: '请输入收藏夹名称' })
          .height(size.middleAvaterSize)
          .backgroundColor(colors.pageBackgroundColor)
          .borderRadius(size.smallBorderRaduis)
          .margin({ left: size.pagePadding })
          .onChange((value) => {
            this.favoriteName = value.trim();
          })
          .layoutWeight(1)
      }
      .width('100%')

      Row() {
        Text('*').visibility(Visibility.Hidden)
        Text('封面')
        Row() {
          Image($r('app.media.icon_add'))
            .width(size.middlIconSize)
            .aspectRatio(1)
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(colors.pageBackgroundColor)
        .borderRadius(size.smallBorderRaduis)
        .margin({ left: size.pagePadding })
        .width(size.bigAvaterSize)
        .aspectRatio(1)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      Button('创建')
        .width('100%')
        .padding(size.pagePadding)
        .backgroundColor(colors.warnColor)
        .fontColor(Color.White)
        .borderRadius(size.blockBorderRaduis * 2)
        .onClick(() => {
          const favoriteDirectory: FavoriteDirectoryType = {
            name: this.favoriteName,
          }
          insertFavoriteDirectoryService(favoriteDirectory).then(res => {
            promptAction.showToast({
              message: '创建收藏夹成功',
              duration: 2000,
              bottom: px2vp(display.getDefaultDisplaySync().height) / 2
            })
            this.onCreateDirectory(res.data);
          });
        })

      Button('取消')
        .width('100%')
        .padding(size.pagePadding)
        .border({ width: 1, color: colors.borderColor })
        .backgroundColor(Color.Transparent)
        .fontColor(Color.Black)
        .borderRadius(size.blockBorderRaduis * 2)
        .onClick(() => {
          this.onCancleCreateDirectory()
        })
    }.padding(size.pagePadding)
  }
}