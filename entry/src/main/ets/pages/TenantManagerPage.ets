import * as colors from '../theme/color';
import * as size from '../theme/size';
import {
  addTenantUserService,
  deleteTenantUserService, getTenantUserListService,searchUserListService } from '../service/Index';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import { TenantUserType,UserDataType,UserWithChecked } from '../type/Index';
import AvaterComponent from '../components/AvaterComponent';
import {PAGE_SIZE,TENANT_USER_DATA,USER_DATA} from "../common/constant";
import DialogComponent from '../components/DialogComponent';
import { display, promptAction } from '@kit.ArkUI';
import BottomDialogComponent from '../components/BottomDialogComponent';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';

@Entry
@Component
struct TenantManagerPage {
  @State tenantUserList:Array<TenantUserType> = [];
  @StorageLink(TENANT_USER_DATA) tenantUser: TenantUserType = {} as TenantUserType;
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @State keyword:string = "";
  @State searchUserList:UserWithChecked[] = [];
  @State total:number = 0;
  private loadingController: LoadingController = new LoadingController()
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

  onDeleteSearchCheckedUser(){
    deleteTenantUserService(this.tenantUser.tenantId,this.searchUserList[this.deleteIndex].id!).then((res)=>{
      promptAction.showToast({
        message: `删除租户${res.data ? '成功' : '失败'}`,
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      if(res.data){
        const item:UserWithChecked =  JSON.parse(JSON.stringify(this.searchUserList[this.deleteIndex]));
        item.checked = 0;
        this.searchUserList.splice(this.deleteIndex,1,item);
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
        this.dialogController = new CustomDialogController({
          customStyle: true,
          builder: BottomDialogComponent({
            dialogHeight: '80%',
            builder: this.addTenantUserBuilder.bind(this)
          }),
          alignment: DialogAlignment.Bottom,
        })
        this.dialogController.open()
      })
  }


  onAddTenantUser(index:number){
    if(this.searchUserList[index].checked === 0){
      addTenantUserService(this.tenantUser.tenantId,this.searchUserList[index].id!).then(()=>{
        this.searchUserList[index].checked = 1;
        const item:UserWithChecked = JSON.parse(JSON.stringify(this.searchUserList[index]));
        this.searchUserList.splice(index,1,item)
        promptAction.showToast({
          message: `添加用户成功`,
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      })
    }else{
      this.deleteIndex = index;
      this.dialogController = new CustomDialogController({
        customStyle: false,
        builder: DialogComponent({
          title: "是否删除租户？",
          cancel: (): void => this.onCancel(),
          confirm: (): void => this.onDeleteSearchCheckedUser(),
        }),
        alignment: DialogAlignment.Center,
      })
      this.dialogController?.open();
    }
  }

  @Builder
  addTenantUserBuilder() {
    Column() {
      Row() {
        Image($r("app.media.icon_add"))
          .width(size.normalFontSize)
          .height(size.normalFontSize)
          .opacity(0.5)
          .onClick(() => {

          })
          .margin({ left: size.pagePadding })
        Text('添加用户')
          .padding(size.pagePadding)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_close"))
          .width(size.normalFontSize)
          .height(size.normalFontSize)
          .opacity(0.5)
          .onClick(() => {
            this.dialogController?.close()
          })
          .margin({ right: size.pagePadding })
      }
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })
    }
    Scroll(){
      Column(){
        Row(){
          Row(){
            TextInput({
              placeholder: "请输入用户姓名/工号/电话/邮箱"
            })
              .height(size.middleAvaterSize)
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value) => {
                this.keyword = value;
              }).layoutWeight(1)
            if(this.keyword){
              Image($r("app.media.icon_clear"))
                .margin({left:size.smallPadding})
                .width(size.smallIconSize)
                .height(size.smallIconSize)
                .onClick(()=>{
                  this.keyword = ""
                })
            }
            Image($r("app.media.icon_search"))
              .margin({left:size.smallPadding,right:size.pagePadding})
              .width(size.smallIconSize)
              .height(size.smallIconSize)
              .onClick(()=>{
                this.pageNum = 1;
                this.searchUserList = [];
                searchUserListService(this.keyword,this.tenantUser.tenantId,this.pageNum,PAGE_SIZE).then((res)=>{
                  this.total = res.total;
                  this.searchUserList.push(...res.data);
                })
              })
          }
          .backgroundColor(colors.pageBackgroundColor)
          .borderRadius(size.bigAvaterSize)
          .width("100%")
          .alignItems(VerticalAlign.Center)
        }.blockStyle()
        Column(){
          if(this.searchUserList.length === 0){
            Text("暂无数据").padding({top:size.pagePadding,bottom:size.pagePadding}).textAlign(TextAlign.Center)
          }else {
            ForEach(this.searchUserList,(item:UserWithChecked,index:number)=>{
              Column(){
                Row(){
                  Row(){
                    AvaterComponent({dimensions:size.middlIconSize,avater:item.avater})
                      .margin({right:size.pagePadding})
                    Text(item.username).layoutWeight(1)
                    Image(item.checked ? $r('app.media.icon_add_tenant_active') : $r('app.media.icon_add_tenant'))
                      .width(size.smallIconSize)
                      .height(size.smallIconSize)
                      .onClick(()=>{
                        this.onAddTenantUser(index);
                      })
                  }
                  .border({
                    width: {
                      bottom: 1,
                    },
                    color: {
                      bottom: index === this.searchUserList.length - 1 ? Color.Transparent :colors.pageBackgroundColor
                    },
                    style: {
                      bottom: BorderStyle.Solid
                    }
                  })
                  .padding({top:index === 0 ? 0 : size.pagePadding,bottom:index === this.searchUserList.length -1 ? 0 : size.pagePadding})

                }
              }
            })
          }
        }.blockStyle()
      }
    }
    .backgroundColor(colors.pageBackgroundColor)
    .padding({
      left: size.pagePadding,
      right: size.pagePadding,
    })
    .layoutWeight(1)
    .align(Alignment.TopStart)
    .onScrollEdge(()=>{
      if(this.total <= this.pageNum * PAGE_SIZE){
        this.pageNum++
        searchUserListService(this.keyword,this.tenantUser.tenantId,this.pageNum,PAGE_SIZE).then((res)=>{
          this.total = res.total;
          this.searchUserList.push(...res.data);
        })
      }
    })
  }

  build() {
    Column() {
      GlobalLoading({ controller: this.loadingController })
      NavigatorTitleComponent({
        title: "租户管理",
        rightContent: this.AddIcon.bind(this)
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
