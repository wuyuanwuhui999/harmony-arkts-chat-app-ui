import * as colors from '../theme/color';
import * as size from '../theme/size';
import { deleteTenantUserService, getTenantUserListService } from '../service/Index';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import { TenantUserType,UserDataType } from '../type/Index';
import AvaterComponent from '../components/AvaterComponent';
import {PAGE_SIZE,TENANT_USER_DATA,USER_DATA} from "../common/constant";
import DialogComponent from '../components/DialogComponent';
import { display, promptAction } from '@kit.ArkUI';

@Entry
@Component
struct TenantManagerPage {
  @State tenantUserList:Array<TenantUserType> = [];
  @StorageLink(TENANT_USER_DATA) tenantUser: TenantUserType = {} as TenantUserType;
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  dialogController: CustomDialogController | null = null;
  deleteIndex:number = -1;
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
  DeleteButton(tenantUser:TenantUserType,index:number) {
    Column() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(16)
    }
    .justifyContent(FlexAlign.Center)
    .width(80)
    .height('100%')
    .backgroundColor(((tenantUser.roleType ==1 && this.tenantUser.roleType === 2 || tenantUser.roleType === 0 ) && tenantUser.userId !== this.userData.id) ? colors.warnColor : colors.disableTextColor)
    .onClick(() => {
      this.deleteIndex = index;
      this.dialogController = new CustomDialogController({
        customStyle: false,
        builder: DialogComponent({
          title: "是否删除租户？",
          cancel: (): void => this.onCancel(),
          confirm: (): void => this.onDeleteTenantUser(),
        }),
        alignment: DialogAlignment.Center,
      })
      this.dialogController?.open();
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 关闭弹窗
   * @date: 2025-09-20 13:21
   */
  onCancel(){
    this.dialogController?.close();
  }

  /**
   * @author: wuwenqiang
   * @description: 关闭弹窗
   * @date: 2025-09-20 13:21
   */
  onDeleteTenantUser(){
    deleteTenantUserService(this.tenantUserList[this.deleteIndex].tenantId,this.tenantUserList[this.deleteIndex].userId!).then((res)=>{
      promptAction.showToast({
        message: `删除租户${res.data ? '成功' : '失败'}`,
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      if(res.data){
        this.tenantUserList.splice(this.deleteIndex,1);
        this.dialogController?.close()
      }
    });
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
                return this.DeleteButton(item,index)
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
