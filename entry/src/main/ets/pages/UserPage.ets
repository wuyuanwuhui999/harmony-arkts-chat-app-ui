import router from '@ohos.router';
import { TenantUserType, UserDataType, TenantType, TenantStatus} from "../type/Index";
import * as colors from '../theme/color';
import * as size from '../theme/size';
import { USER_DATA,TENANT_USER_DATA,DEFAULT_TENANT_USER, HOST} from '../common/constant';
import { getTenantListService, getTenantUserService, updateUserDataService } from '../service/Index';
import preference from '../utils/PreferenceModel';
import OptionDialogComponent from '../components/OptionDialogComponent';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import DialogComponent from '../components/DialogComponent';
import { SexValueMap } from '../common/config';

@Entry
@Component
struct UserPage {
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @StorageLink(TENANT_USER_DATA) tenantUser: TenantUserType = {} as TenantUserType;
  title: string = '';
  @State field: string = '';
  @State tenantList: Array<TenantType> = [{
    id: "",// 租户ID（主键）
    name: "私人空间",// 租户名称
    code: "personal",// 租户编码（唯一）
    status: TenantStatus.DISABLED,// 租户状态
    created_by: ""// 创建人ID
  }];
  dialogController: CustomDialogController | null = null

  @Styles
  blockStyle(){
    .backgroundColor(colors.blockColor)
    .borderRadius(size.blockBorderRaduis)
    .padding(size.pagePadding)
    .width('100%')
    .margin({ top: size.pagePadding })
  }

  @Styles
  arrowStyle(){
    .margin({ left: size.smallPadding })
    .height(size.smallIconSize)
    .width(size.smallIconSize)
  }

  @Styles
  rowStyle(){
    .border({
      width: {
        bottom: 1,
      },
      color: {
        bottom: colors.pageBackgroundColor
      },
      style: {
        bottom: BorderStyle.Solid
      }
    })
    .width('100%')
    .padding({ top: size.pagePadding, bottom: size.pagePadding })
  }

  aboutToAppear() {
    getTenantListService().then((res)=>{
      this.tenantList.push(...res.data)
    })
  }

  useShowDialog(title: string, field: string) {
    this.title = title;
    this.field = field;
    if (field === 'sex') {
      this.dialogController = new CustomDialogController({
        customStyle: true,
        builder: OptionDialogComponent({
          cancel: (): void => this.onCancel(),
          confirm: (value): void => this.onConfirm(value),
          options: ['男', '女'],
        }),
        alignment: DialogAlignment.Bottom,
      })
    } else if (title === 'logout') {
      this.dialogController = new CustomDialogController({
        customStyle: false,
        builder: DialogComponent({
          title: "是否退出登录？",
          cancel: (): void => this.onCancel(),
          confirm: (): void => this.onLogout(),
        }),
        alignment: DialogAlignment.Center,
      })
    } else {
      this.dialogController = new CustomDialogController({
        customStyle: true,
        builder: CustomDialogComponent({
          cancel: (): void => this.onCancel(),
          confirm: (value): void => this.onConfirm(value),
          title: this.title,
          text: this.userData[this.field]
        }),
        alignment: DialogAlignment.Center,
      })
    }
    this.dialogController.open()
  }

  onCancel() {
    this.dialogController?.close()
  }

  /**
   * @description: 修改用户信息
   * @date: 2024-01-10 23:01
   * @author wuwenqiang
   */
  onConfirm(value: string) {
    const userData: UserDataType = JSON.parse(JSON.stringify(this.userData))
    userData[this.field] = value
    updateUserDataService(userData).then(() => {
      this.userData[this.field] = value;
      this.dialogController?.close()
    })
  }

  onLogout() {
    preference.setToken("");
    router.replaceUrl({
      url: 'pages/LoginPage', // 目标url
    }, router.RouterMode.Single, (err) => {
      if (err) {
        console.error(`Invoke showAlertBeforeBackPage failed, code is ${err.code}, message is ${err.message}`);
      }
    });
    router.clear(); // 清除历史页面
  }

  /**
   * @description: 修改用户信息
   * @date: 2025-09-18 16:53
   * @author wuwenqiang
   */
  getTenantUser = (tenantId:string)=>{
    if(tenantId === ""){
      AppStorage.SetOrCreate(TENANT_USER_DATA,this.getDefaultTenantUser());
      this.dialogController?.close();
    }else {
      getTenantUserService(tenantId).then((res)=>{
        AppStorage.SetOrCreate(TENANT_USER_DATA,res.data);
        this.dialogController?.close();
      })
    }
  }

  getDefaultTenantUser():TenantUserType{
    const defaultTenantUser:TenantUserType = JSON.parse(JSON.stringify(DEFAULT_TENANT_USER));
    defaultTenantUser.userId = defaultTenantUser.tenantId = this.userData.id!;
    defaultTenantUser.username = this.userData.username;
    return defaultTenantUser
  }

  build() {
    Column() {
      NavigatorTitleComponent({ title: "用户信息" })
      Scroll() {
        Column() {
          Column() {
            Row() {
              Text('头像').flexGrow(1)
              Image(this.userData?.avater ? HOST + this.userData.avater : $r('app.media.default_avater'))
                .height(size.bigAvaterSize)
                .width(size.bigAvaterSize)
                .borderRadius(size.bigAvaterSize)
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().justifyContent(FlexAlign.Center)

            Row() {
              Text('昵称').flexGrow(1)
              Text(this.userData.username)
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().justifyContent(FlexAlign.Center).onClick(() => {
              this.useShowDialog('昵称', 'username')
            })

            Row() {
              Text('性别').flexGrow(1)
              Text(SexValueMap[this.userData.sex])
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().justifyContent(FlexAlign.Center).onClick(() => {
              this.useShowDialog('性别', 'sex')
            })

            Row() {
              Text('电话').flexGrow(1)
              Text(this.userData.telephone)
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().justifyContent(FlexAlign.Center).onClick(() => {
              this.useShowDialog('电话', 'telephone')
            })

            Row() {
              Text('邮箱').flexGrow(1)
              Text(this.userData.email)
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().justifyContent(FlexAlign.Center).onClick(() => {
              this.useShowDialog('邮箱', 'email')
            })

            Row() {
              Text('生日').flexGrow(1)
              Text(this.userData.birthday)
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().justifyContent(FlexAlign.Center).onClick(() => {
              DatePickerDialog.show({
                start: new Date("1970-1-1"),
                end: new Date("2100-12-31"),
                selected: new Date(this.userData.birthday),
                onChange: (value: DatePickerResult) => {
                  this.userData.birthday = `${value.year}-${value.month}-${value.day}`;
                }
              })
            })

            Row() {
              Text('个性签名').flexGrow(1)
              Text(this.userData.sign)
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().justifyContent(FlexAlign.Center).onClick(() => {
              this.useShowDialog('个性签名', 'sign')
            })

            Row() {
              Text('区域').flexGrow(1)
              Text(this.userData.region)
              Image($r('app.media.icon_arrow')).arrowStyle()
            }.rowStyle().border({ width: 0 }).justifyContent(FlexAlign.Center).onClick(() => {
              this.useShowDialog('区域', 'region')
            })

          }.blockStyle().padding({ top: 0, left: size.pagePadding, right: size.pagePadding })

          Text('修改密码')
            .padding(size.smallPadding)
            .border({
              width: 1,
              color: colors.borderColor,
              style: BorderStyle.Solid
            })
            .backgroundColor(colors.blockColor)
            .borderRadius(size.blockBorderRaduis * 2)
            .width('100%')
            .padding(size.pagePadding)
            .textAlign(TextAlign.Center)
            .margin({ top: size.pagePadding})
            .onClick(() => {
              router.pushUrl({
                url: 'pages/UpdatePasswordPage', // 目标url
              });
            })

          if(this.tenantList.length > 0){
            Text('切换租户')
              .padding(size.smallPadding)
              .border({
                width: 1,
                color: colors.borderColor,
                style: BorderStyle.Solid
              })
              .backgroundColor(colors.blockColor)
              .borderRadius(size.blockBorderRaduis * 2)
              .width('100%')
              .padding(size.pagePadding)
              .textAlign(TextAlign.Center)
              .margin({ top: size.pagePadding })
              .onClick(() => {
                this.dialogController = new CustomDialogController({
                  customStyle: true,
                  builder: OptionDialogComponent({
                    cancel: (): void => this.onCancel(),
                    confirm: (value,index): void => this.getTenantUser(this.tenantList[index].id),
                    options: this.tenantList.map((item)=>{
                      return item.name
                    }),
                  }),
                  alignment: DialogAlignment.Bottom,
                })
                this.dialogController.open()
              })
          }

          if(this.tenantUser.roleType > 1){
            Text('租户管理')
              .padding(size.smallPadding)
              .border({
                width: 1,
                color: colors.borderColor,
                style: BorderStyle.Solid
              })
              .backgroundColor(colors.blockColor)
              .borderRadius(size.blockBorderRaduis * 2)
              .width('100%')
              .padding(size.pagePadding)
              .textAlign(TextAlign.Center)
              .margin({ top: size.pagePadding})
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/TenantManagerPage', // 目标url
                });
              })
          }

          Button('退出登录')
            .width('100%')
            .padding(size.pagePadding)
            .backgroundColor(colors.warnColor)
            .margin({ top: size.pagePadding })
            .fontColor(Color.White)
            .borderRadius(size.blockBorderRaduis * 2)
            .onClick(() => {
              this.useShowDialog('logout', '');
            })


        }.padding({ left: size.pagePadding, right: size.pagePadding })
      }.layoutWeight(1).scrollable(ScrollDirection.Vertical).align(Alignment.Top)

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor(colors.pageBackgroundColor)
  }
}

/**
 * @description: 修改用户信息弹窗
 * @date: 2024-01-14 21:47
 * @author wuwenqiang
 */
@CustomDialog
struct CustomDialogComponent {
  controller: CustomDialogController
  cancel: () => void = () => {
  };
  confirm: (value: string) => void = () => {
  };
  title: string = '';
  text: string = '';
  value: string = '';

  aboutToAppear() {
    this.value = this.text
  }

  build() {
    Column({ space: size.pagePadding }) {
      Text("请输入")
        .margin({ top: size.pagePadding })
      Row() {
        Text(this.title)
          .margin({ right: size.smallIconSize })
        TextInput({ placeholder: '请输入', text: this.text })
          .layoutWeight(1)
          .backgroundColor(colors.pageBackgroundColor)
          .height(size.lineHeight * 2)
          .onChange((value: string) => {
            this.value = value
          })
      }.width('100%')
      .padding({ left: size.pagePadding, right: size.pagePadding })
      .alignItems(VerticalAlign.Center)

      Row() {
        Text('取消')
          .onClick(() => {
            this.controller.close()
            this.cancel()
          })
          .flexGrow(1)
          .textAlign(TextAlign.Center)
          .backgroundColor(colors.blockColor)
          .fontColor(Color.Black)
        Divider().width(1).height('100%').backgroundColor(colors.borderColor)
        Text('确定')
          .onClick(() => {
            this.confirm(this.value)
          })
          .flexGrow(1)
          .textAlign(TextAlign.Center)
          .backgroundColor(colors.blockColor)
          .fontColor(Color.Red)
      }.height(size.dialogBtnHeight).border({
        width: {
          top: 1,
        },
        color: {
          top: colors.borderColor
        },
        style: {
          top: BorderStyle.Solid
        }
      })
      .width('100%')
    }
    .backgroundColor(colors.blockColor)
    .borderRadius(size.blockBorderRaduis)
    .margin({ left: size.pagePadding, right: size.pagePadding })
  }
}
