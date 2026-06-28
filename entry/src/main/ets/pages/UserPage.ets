// ets/pages/UserPage.ets
import router from '@ohos.router';
import { UserDataType, TenantType, CompanyType } from "../type/Index";
import * as colors from '../theme/color';
import * as size from '../theme/size';
import { USER_DATA, HOST, COMPANY_DATA } from '../common/constant';
import { updateUserDataService } from '../service/Index';
import preference from '../utils/PreferenceModel';
import OptionDialogComponent from '../components/OptionDialogComponent';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import DialogComponent from '../components/DialogComponent';
import { SexValueMap } from '../common/config';
import { getTenantListService } from '../service/Index';

@Entry
@Component
struct UserPage {
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @StorageLink(COMPANY_DATA) companyData: CompanyType | null = null;
  /** 当前选中的租户 */
  @State currentTenant: TenantType | null = null;
  /** 租户列表 */
  @State tenantList: Array<TenantType> = [];
  title: string = '';
  @State field: string = '';
  dialogController: CustomDialogController | null = null

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  @Styles
  arrowStyle() {
    .margin({ left: size.smallGap })
    .height(size.smallIcon)
    .width(size.smallIcon)
  }

  @Styles
  rowStyle() {
    .border({
      width: {
        bottom: 1,
      },
      color: {
        bottom: colors.pageBackground
      },
      style: {
        bottom: BorderStyle.Solid
      }
    })
    .width('100%')
    .padding({ top: size.middleGap, bottom: size.middleGap })
  }

  async aboutToAppear() {
    // 获取当前租户信息
    await this.loadCurrentTenant();
  }

  /**
   * @description: 加载当前租户信息
   * @date: 2026-06-27
   * @author wuwenqiang
   */
  async loadCurrentTenant() {
    const companyId = this.companyData?.id || '';
    const userId = this.userData.id;

    if (!userId) {
      console.warn('[UserPage] 用户ID为空，无法加载租户信息');
      return;
    }

    try {
      // 获取租户列表
      const tenantListRes = await getTenantListService(companyId);
      if (tenantListRes.data && tenantListRes.data.length > 0) {
        this.tenantList = tenantListRes.data;

        // 从缓存获取上次保存的租户ID
        const cachedTenantId = await preference.getPreference(`${userId}:tenantId`);

        let selectedTenant: TenantType | null = null;

        // 如果缓存中有租户ID，在列表中查找
        if (cachedTenantId) {
          selectedTenant = this.tenantList.find(item => item.id === cachedTenantId) || null;
        }

        // 如果找不到或没有缓存，取第一条
        if (!selectedTenant) {
          selectedTenant = this.tenantList[0];
        }

        this.currentTenant = selectedTenant;
      }
    } catch (error) {
      console.error('[UserPage] 获取租户信息失败:', JSON.stringify(error));
    }
  }

  /**
   * @description: 显示修改信息弹窗
   * @date: 2024-01-10
   * @author wuwenqiang
   */
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

  /**
   * @description: 退出登录
   * @date: 2024-01-10
   * @author wuwenqiang
   */
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
   * @author: wuwenqiang
   * @description: 跳转到公司切换页面（带参数标识来源）
   * @date: 2026-06-26
   */
  goToCompanyPage() {
    router.pushUrl({
      url: 'pages/CompanyPage',
      params: {
        fromUserPage: true // 标识从UserPage跳转过来
      }
    });
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
                .height(size.bigAvater)
                .width(size.bigAvater)
                .borderRadius(size.bigAvater)
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

          }.blockStyle().padding({ top: 0, left: size.middleGap, right: size.middleGap })

          Text('修改密码')
            .padding(size.smallGap)
            .border({
              width: 1,
              color: colors.borderColor,
              style: BorderStyle.Solid
            })
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis * 2)
            .width('100%')
            .padding(size.middleGap)
            .textAlign(TextAlign.Center)
            .margin({ top: size.middleGap })
            .onClick(() => {
              router.pushUrl({
                url: 'pages/UpdatePasswordPage', // 目标url
              });
            })

          // 切换公司/个人空间按钮
          Text('切换公司/个人空间')
            .padding(size.smallGap)
            .border({
              width: 1,
              color: colors.borderColor,
              style: BorderStyle.Solid
            })
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis * 2)
            .width('100%')
            .padding(size.middleGap)
            .textAlign(TextAlign.Center)
            .margin({ top: size.middleGap })
            .onClick(() => {
              this.goToCompanyPage();
            })

          // 租户管理按钮 - 修改判断条件：使用 currentTenant?.role 替代 tenantUser.roleType
          if ((this.currentTenant?.role ?? 0) > 0) {
            Text('租户管理')
              .padding(size.smallGap)
              .border({
                width: 1,
                color: colors.borderColor,
                style: BorderStyle.Solid
              })
              .backgroundColor(colors.white)
              .borderRadius(size.middleBorderRaduis * 2)
              .width('100%')
              .padding(size.middleGap)
              .textAlign(TextAlign.Center)
              .margin({ top: size.middleGap })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/TenantManagerPage',
                  params: {
                    tenantId: this.currentTenant?.id,
                    tenantName: this.currentTenant?.name,
                    role: this.currentTenant?.role
                  }
                });
              })
          }

          // 用户管理按钮（根据角色显示）- 管理员或超级管理员可见
          if (this.companyData && this.companyData.role && this.companyData.role > 0) {
            Text('用户管理')
              .padding(size.smallGap)
              .border({
                width: 1,
                color: colors.borderColor,
                style: BorderStyle.Solid
              })
              .backgroundColor(colors.white)
              .borderRadius(size.middleBorderRaduis * 2)
              .width('100%')
              .padding(size.middleGap)
              .textAlign(TextAlign.Center)
              .margin({ top: size.middleGap })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/UserManagePage',
                  params: {
                    companyId: this.companyData?.id,
                    companyRole: this.companyData?.role
                  }
                });
              })
          }

          Button('退出登录')
            .width('100%')
            .padding(size.middleGap)
            .backgroundColor(colors.warn)
            .margin({ top: size.middleGap })
            .fontColor(Color.White)
            .borderRadius(size.middleBorderRaduis * 2)
            .onClick(() => {
              this.useShowDialog('logout', '');
            })

        }.padding({ left: size.middleGap, right: size.middleGap })
      }.layoutWeight(1).scrollable(ScrollDirection.Vertical).align(Alignment.Top)

    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .backgroundColor(colors.pageBackground)
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
    Column({ space: size.middleGap }) {
      Text("请输入")
        .margin({ top: size.middleGap })
      Row() {
        Text(this.title)
          .margin({ right: size.smallIcon })
        TextInput({ placeholder: '请输入', text: this.text })
          .layoutWeight(1)
          .backgroundColor(colors.pageBackground)
          .height(size.lineHeight * 2)
          .onChange((value: string) => {
            this.value = value
          })
      }.width('100%')
      .padding({ left: size.middleGap, right: size.middleGap })
      .alignItems(VerticalAlign.Center)

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
        Divider().width(1).height('100%').backgroundColor(colors.borderColor)
        Text('确定')
          .onClick(() => {
            this.confirm(this.value)
          })
          .flexGrow(1)
          .textAlign(TextAlign.Center)
          .backgroundColor(colors.white)
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
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .margin({ left: size.middleGap, right: size.middleGap })
  }
}