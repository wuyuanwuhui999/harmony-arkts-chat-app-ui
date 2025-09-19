import * as colors from '../theme/color';
import * as size from '../theme/size';
import { getTenantUserListService } from '../service/Index';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import { TenantUserType } from '../type/Index';
import AvaterComponent from '../components/AvaterComponent';
import {PAGE_SIZE,TENANT_USER_DATA} from "../common/constant";

@Entry
@Component
struct TenantManagerPage {
  @State tenantUserList:Array<TenantUserType> = [];
  @StorageLink(TENANT_USER_DATA) tenantUser: TenantUserType = {} as TenantUserType;

  pageNum:number = 1;
  @Styles blockStyle(){
    .backgroundColor(colors.blockColor)
    .borderRadius(size.blockBorderRaduis)
    .padding(size.pagePadding)
    .width('100%')
    .margin({ top: size.pagePadding })
  }

  aboutToAppear(): void {
    getTenantUserListService(this.tenantUser.tenantId,this.pageNum,PAGE_SIZE).then((res)=>{
      this.tenantUserList.push(...res.data);
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 删除弹窗
   * @date: 2025-04-13 12:07
   */
  @Builder
  DeleteButton(tenantUser:TenantUserType) {
    Column() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(16)
    }
    .justifyContent(FlexAlign.Center)
    .width(80)
    .height('100%')
    .backgroundColor((tenantUser.roleType ==1 && this.tenantUser.roleType === 2 || tenantUser.roleType === 0) ? colors.warnColor : colors.disableTextColor)
    .onClick(() => {

    })
  }

  /**
   * @author: wuwenqiang
   * @description: 删除弹窗
   * @date: 2025-04-13 12:07
   */
  @Builder
  AddIcon() {
    Image($r('app.media.icon_add'))
      .width(size.smallIconSize)
      .height(size.smallIconSize)
      .onClick(() => {
        console.log('设置图标被点击');
      })
  }

  build() {
    Column() {
      NavigatorTitleComponent({
        title: "租户管理",
        rightContent: this.AddIcon
      })
      Scroll() {
        List(){
          ForEach(this.tenantUserList,(item:TenantUserType,index:number)=>{
            ListItem(){
              Row(){
                AvaterComponent({dimensions:size.middlIconSize,avater:item.avater})
                  .margin({right:size.pagePadding})
                Text(item.username).layoutWeight(1)
              }
              .border({
                width: {
                  bottom: 1,
                },
                color: {
                  bottom: index === this.tenantUserList.length - 1 ? Color.Transparent :colors.pageBackgroundColor
                },
                style: {
                  bottom: BorderStyle.Solid
                }
              })
              .padding({top:index === 0 ? 0 : size.pagePadding,bottom:index === this.tenantUserList.length -1 ? 0 : size.pagePadding})
            }.swipeAction({
              end: () => {
                return this.DeleteButton(item)
              }
            })

          })
        }
        .blockStyle()
        .margin(size.pagePadding)
        .width("auto")
      }
      .layoutWeight(1)
      .backgroundColor(colors.pageBackgroundColor)
      .scrollable(ScrollDirection.Vertical)
      .align(Alignment.Top)
    }
  }
}
