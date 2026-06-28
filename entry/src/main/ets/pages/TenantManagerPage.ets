// ets/pages/TenantManagerPage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import {
  deleteTenantUserService,
  getTenantUserListService,
  addAdminService,
  deleteAdminService
} from '../service/Index';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import { TenantUserType, UserDataType, TenantType, CompanyType } from '../type/Index';
import AvaterComponent from '../components/AvaterComponent';
import { PAGE_SIZE, USER_DATA,COMPANY_DATA } from "../common/constant";
import DialogComponent from '../components/DialogComponent';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import router from '@ohos.router';

@Entry
@Component
struct TenantManagerPage {
  @State tenantUserList: Array<TenantUserType> = [];
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @State total: number = 0;
  /** 当前租户信息 - 从路由参数获取 */
  @State currentTenant: TenantType | null = null;
  private loadingController: LoadingController = new LoadingController()
  dialogController: CustomDialogController | null = null;
  deleteIndex: number = -1;
  pageNum: number = 1;

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  aboutToAppear(): void {
    // 从路由参数获取当前租户
    const params = router.getParams() as Record<string, Object>;
    const tenantId = (params?.tenantId as string) || '';

    if (!tenantId) {
      promptAction.showToast({
        message: '获取租户信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 构建当前租户对象（仅用于显示名称和角色判断）
    this.currentTenant = {
      id: tenantId,
      name: params?.tenantName as string || '租户',
      code: '',
      role: (params?.role as number) || 0,
      status: 1,
      created_by: '',
    };

    // 加载租户用户列表
    this.loadTenantUserList();
  }

  /**
   * @description: 加载租户用户列表
   * @date: 2025-09-20
   * @author wuwenqiang
   */
  loadTenantUserList() {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) return;

    this.loadingController.showLoading();
    getTenantUserListService(tenantId, this.pageNum, PAGE_SIZE).then((res) => {
      if (this.pageNum === 1) {
        this.tenantUserList = res.data || [];
      } else {
        this.tenantUserList = this.tenantUserList.concat(res.data || []);
      }
      this.total = res.total;
    }).catch((err: Error) => {
      console.error('获取租户用户列表失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '获取租户用户列表失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 刷新租户用户列表
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  refreshTenantUserList() {
    this.pageNum = 1;
    this.tenantUserList = [];
    this.loadTenantUserList();
  }

  /**
   * @author: wuwenqiang
   * @description: 关闭弹窗
   * @date: 2025-09-20 13:21
   */
  onCancel() {
    this.dialogController?.close();
  }

  /**
   * @author: wuwenqiang
   * @description: 删除租户用户
   * @date: 2025-09-20 13:21
   */
  onDeleteTenantUser() {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) return;

    deleteTenantUserService(tenantId, this.tenantUserList[this.deleteIndex].userId!).then((res) => {
      promptAction.showToast({
        message: `删除租户${res.data ? '成功' : '失败'}`,
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      if (res.data) {
        this.tenantUserList.splice(this.deleteIndex, 1);
        this.dialogController?.close()
      }
    });
  }

  @Builder
  AddIcon() {
    Image($r('app.media.icon_add'))
      .width(size.smallIcon)
      .height(size.smallIcon)
      .onClick(() => {
        const companyData = AppStorage.get(COMPANY_DATA) as CompanyType;
        router.pushUrl({
          url: 'pages/AddTenantUserPage',
          params: {
            tenantId: this.currentTenant?.id,
            tenantName: this.currentTenant?.name,
            companyId: companyData?.id || ''
          }
        });
      })
  }

  /**
   * @author: wuwenqiang
   * @description: 设为管理员
   * @date: 2026-06-28
   */
  onSetAdmin(index: number) {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: '获取租户信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    const user = this.tenantUserList[index];
    if (!user) return;

    if (user.userId === this.userData.id) {
      promptAction.showToast({
        message: '不能修改自己的权限',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    addAdminService(tenantId, user.userId!).then((res) => {
      if (res.data) {
        promptAction.showToast({
          message: '设为管理员成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        user.role = 1;
        this.tenantUserList.splice(index, 1, JSON.parse(JSON.stringify(user)));
      } else {
        promptAction.showToast({
          message: res.msg || '操作失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      console.error('设为管理员失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '设为管理员失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    });
  }

  /**
   * @author: wuwenqiang
   * @description: 取消管理员
   * @date: 2026-06-28
   */
  onCancelAdmin(index: number) {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: '获取租户信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    const user = this.tenantUserList[index];
    if (!user) return;

    if (user.userId === this.userData.id) {
      promptAction.showToast({
        message: '不能修改自己的权限',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    deleteAdminService(tenantId, user.userId!).then((res) => {
      if (res.data) {
        promptAction.showToast({
          message: '取消管理员成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        user.role = 0;
        this.tenantUserList.splice(index, 1, JSON.parse(JSON.stringify(user)));
      } else {
        promptAction.showToast({
          message: res.msg || '操作失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      console.error('取消管理员失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '取消管理员失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    });
  }

  /**
   * @description: 构建用户列表项
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  @Builder
  UserItemBuilder(item: TenantUserType, index: number) {
    Row() {
      // 头像
      AvaterComponent({
        dimensions: size.middleAvater,
        avater: item.avater
      })
        .margin({ right: size.middleGap })

      // 用户信息：用户名 + 工号（纵向排列）
      Column({ space: size.miniGap }) {
        Row({ space: size.smallGap }) {
          Text(item.username)
            .fontSize(size.middleFont)
            .fontColor(colors.black)

          // 管理员标签
          if (item.role === 2) {
            Text('超级管理员')
              .fontSize(10)
              .fontColor(colors.primary)
              .padding({ left: size.smallGap, right: size.smallGap, top: 2, bottom: 2 })
              .border({
                width: 1,
                color: colors.primary,
                style: BorderStyle.Solid
              })
              .borderRadius(4)
          } else if (item.role === 1) {
            Text('管理员')
              .fontSize(10)
              .fontColor(colors.primary)
              .padding({ left: size.smallGap, right: size.smallGap, top: 2, bottom: 2 })
              .border({
                width: 1,
                color: colors.primary,
                style: BorderStyle.Solid
              })
              .borderRadius(4)
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        // 工号 - 灰色显示
        Text(item.userAccount || '暂无工号')
          .fontSize(12)
          .fontColor(colors.gray)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({
      top: index === 0 ? 0 : size.middleGap,
      bottom: index === this.tenantUserList.length - 1 ? 0 : size.middleGap
    })
    .border({
      width: { bottom: index === this.tenantUserList.length - 1 ? 0 : 1 },
      color: { bottom: colors.pageBackground },
      style: { bottom: BorderStyle.Solid }
    })
  }

  /**
   * @description: 滑动操作按钮（只有超级管理员 role===2 才显示）
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  @Builder
  SwipeActionBuilder(item: TenantUserType, index: number) {
    Row() {
      // 只有超级管理员 (role === 2) 才显示管理员操作按钮
      if ((this.currentTenant?.role ?? 0) === 2) {
        if (item.role > 0) {
          // 取消管理员
          Column() {
            Text('取消管理员')
              .fontColor(Color.White)
              .fontSize(14)
          }
          .justifyContent(FlexAlign.Center)
          .width(100)
          .height('100%')
          .backgroundColor(colors.gray)
          .onClick(() => {
            this.onCancelAdmin(index);
          })
        } else {
          // 设为管理员
          Column() {
            Text('设为管理员')
              .fontColor(Color.White)
              .fontSize(14)
          }
          .justifyContent(FlexAlign.Center)
          .width(100)
          .height('100%')
          .backgroundColor(colors.primary)
          .onClick(() => {
            this.onSetAdmin(index);
          })
        }
      }

      // 删除按钮 - 红色背景
      Column() {
        Text('删除')
          .fontColor(Color.White)
          .fontSize(14)
      }
      .justifyContent(FlexAlign.Center)
      .width(80)
      .height('100%')
      .backgroundColor(colors.warn)
      .onClick(() => {
        // 检查删除权限
        if ((this.currentTenant?.role ?? 0) !== 2) {
          promptAction.showToast({
            message: '只有超级管理员可以删除用户',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
          return;
        }
        if (item.userId === this.userData.id) {
          promptAction.showToast({
            message: '不能删除自己',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
          return;
        }
        this.deleteIndex = index;
        this.dialogController = new CustomDialogController({
          customStyle: false,
          builder: DialogComponent({
            title: `是否删除用户 "${item.username}"？`,
            cancel: (): void => this.onCancel(),
            confirm: (): void => this.onDeleteTenantUser(),
          }),
          alignment: DialogAlignment.Center,
        })
        this.dialogController?.open();
      })
    }
  }

  build() {
    Column() {
      GlobalLoading({ controller: this.loadingController })
      NavigatorTitleComponent({
        title: "租户管理",
        rightContent: this.AddIcon.bind(this)
      })
      Scroll() {
        List() {
          ForEach(this.tenantUserList, (item: TenantUserType, index: number) => {
            ListItem() {
              this.UserItemBuilder(item, index)
            }
            .swipeAction({
              end: () => {
                // 只有超级管理员 (role===2) 才显示滑动操作
                if ((this.currentTenant?.role ?? 0) === 2) {
                  return this.SwipeActionBuilder(item, index)
                }
                return this.EmptyBuilder()
              }
            })
          })
        }
        .blockStyle()
        .margin(size.middleGap)
        .width("auto")
      }
      .layoutWeight(1)
      .backgroundColor(colors.pageBackground)
      .scrollable(ScrollDirection.Vertical)
      .align(Alignment.Top)
    }
  }

  /**
   * @description: 空构建器（用于禁用滑动操作）
   * @date: 2026-06-27
   * @author wuwenqiang
   */
  @Builder
  EmptyBuilder() {
    Column()
      .width(0)
      .height('100%')
  }
}

export default TenantManagerPage;