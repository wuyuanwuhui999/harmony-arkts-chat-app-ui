// ets/pages/TenantManagerPage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import {
  addTenantUserService,
  deleteTenantUserService,
  getTenantUserListService,
  searchUserListService,
  addAdminService,
  deleteAdminService
} from '../service/Index';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import { TenantUserType, UserDataType, UserWithChecked, TenantType } from '../type/Index';
import AvaterComponent from '../components/AvaterComponent';
import { PAGE_SIZE, USER_DATA } from "../common/constant";
import DialogComponent from '../components/DialogComponent';
import { display, promptAction } from '@kit.ArkUI';
import BottomDialogComponent from '../components/BottomDialogComponent';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import router from '@ohos.router';

@Entry
@Component
struct TenantManagerPage {
  @State tenantUserList: Array<TenantUserType> = [];
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @State keyword: string = "";
  @State searchUserList: UserWithChecked[] = [];
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
   * @description: 删除弹窗
   * @date: 2025-04-13 12:07
   */
  @Builder
  DeleteButton(tenantUser: TenantUserType, index: number) {
    Column() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(14)
    }
    .justifyContent(FlexAlign.Center)
    .width(80)
    .height('100%')
    // 修改：使用 currentTenant.role 判断权限，只有超级管理员(role===2)才能删除管理员
    .backgroundColor(((tenantUser.role == 1 && (this.currentTenant?.role ?? 0) === 2 || tenantUser.role === 0) && tenantUser.userId !== this.userData.id) ? colors.warn : colors.gray)
    .onClick(() => {
      // 只有超级管理员才能删除，且不能删除自己
      if (this.currentTenant?.role !== 2) {
        promptAction.showToast({
          message: '只有超级管理员可以删除用户',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        return;
      }
      if (tenantUser.userId === this.userData.id) {
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
          title: `是否删除用户 "${tenantUser.username}"？`,
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

  onDeleteSearchCheckedUser() {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) return;

    deleteTenantUserService(tenantId, this.searchUserList[this.deleteIndex].id!).then((res) => {
      promptAction.showToast({
        message: `删除租户${res.data ? '成功' : '失败'}`,
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      if (res.data) {
        const item: UserWithChecked = JSON.parse(JSON.stringify(this.searchUserList[this.deleteIndex]));
        item.checked = 0;
        this.searchUserList.splice(this.deleteIndex, 1, item);
        this.dialogController?.close()
      }
    });
  }

  /**
   * @author: wuwenqiang
   * @description: 添加用户图标
   * @date: 2025-09-20
   */
  @Builder
  AddIcon() {
    Image($r('app.media.icon_add'))
      .width(size.smallIcon)
      .height(size.smallIcon)
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

  /**
   * @author: wuwenqiang
   * @description: 添加租户用户
   * @date: 2025-09-20
   */
  onAddTenantUser(index: number) {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) return;

    if (this.searchUserList[index].checked === 0) {
      addTenantUserService(tenantId, this.searchUserList[index].id!).then(() => {
        this.searchUserList[index].checked = 1;
        const item: UserWithChecked = JSON.parse(JSON.stringify(this.searchUserList[index]));
        this.searchUserList.splice(index, 1, item)
        promptAction.showToast({
          message: `添加用户成功`,
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      })
    } else {
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

  /**
   * @author: wuwenqiang
   * @description: 添加租户用户对话框构建器
   * @date: 2025-09-20
   */
  @Builder
  addTenantUserBuilder() {
    Column() {
      Row() {
        Blank()
          .width(size.smallIcon)
          .height(size.smallIcon)
          .margin({ left: size.smallIcon })
        Text('添加用户')
          .padding(size.middleGap)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_close"))
          .width(size.middleFont)
          .height(size.middleFont)
          .opacity(0.5)
          .onClick(() => {
            this.dialogController?.close()
          })
          .margin({ right: size.middleGap })
      }
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })
    }
    Scroll() {
      Column() {
        Row() {
          Row() {
            TextInput({
              placeholder: "请输入用户姓名/工号/电话/邮箱",
              text: this.keyword
            })
              .height(size.middleAvater)
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value) => {
                this.keyword = value;
              }).layoutWeight(1)
            if (this.keyword) {
              Image($r("app.media.icon_clear"))
                .margin({ left: size.smallGap })
                .width(size.smallIcon)
                .height(size.smallIcon)
                .onClick(() => {
                  this.keyword = ""
                })
            }
            Image($r("app.media.icon_search"))
              .margin({ left: size.smallGap, right: size.middleGap })
              .width(size.smallIcon)
              .height(size.smallIcon)
              .onClick(() => {
                const tenantId = this.currentTenant?.id;
                if (!tenantId) return;
                this.pageNum = 1;
                this.searchUserList = [];
                this.loadingController.showLoading()
                searchUserListService(this.keyword, tenantId, this.pageNum, PAGE_SIZE).then((res) => {
                  this.total = res.total;
                  this.searchUserList.push(...res.data);
                }).finally(() => {
                  this.loadingController.hideLoading()
                })
              })
          }
          .backgroundColor(colors.pageBackground)
          .borderRadius(size.bigAvater)
          .width("100%")
          .alignItems(VerticalAlign.Center)
        }.blockStyle()
        Column() {
          if (this.searchUserList.length === 0) {
            Text("暂无数据").padding({ top: size.middleGap, bottom: size.middleGap }).textAlign(TextAlign.Center)
          } else {
            ForEach(this.searchUserList, (item: UserWithChecked, index: number) => {
              Column() {
                Row() {
                  Row() {
                    AvaterComponent({ dimensions: size.middleIcon, avater: item.avater })
                      .margin({ right: size.middleGap })
                    Text(item.username).layoutWeight(1)
                    Image(item.checked ? $r('app.media.icon_add_tenant_active') : $r('app.media.icon_add_tenant'))
                      .width(size.smallIcon)
                      .height(size.smallIcon)
                      .onClick(() => {
                        this.onAddTenantUser(index);
                      })
                  }
                  .border({
                    width: {
                      bottom: 1,
                    },
                    color: {
                      bottom: index === this.searchUserList.length - 1 ? Color.Transparent : colors.pageBackground
                    },
                    style: {
                      bottom: BorderStyle.Solid
                    }
                  })
                  .padding({
                    top: index === 0 ? 0 : size.middleGap,
                    bottom: index === this.searchUserList.length - 1 ? 0 : size.middleGap
                  })

                }
              }
            })
          }
        }.blockStyle().margin({ bottom: size.middleGap, top: size.middleGap })
      }
    }
    .backgroundColor(colors.pageBackground)
    .padding({
      left: size.middleGap,
      right: size.middleGap,
    })
    .layoutWeight(1)
    .align(Alignment.TopStart)
    .onScrollEdge(() => {
      const tenantId = this.currentTenant?.id;
      if (!tenantId) return;
      if (this.total <= this.pageNum * PAGE_SIZE) {
        this.pageNum++
        searchUserListService(this.keyword, tenantId, this.pageNum, PAGE_SIZE).then((res) => {
          this.total = res.total;
          this.searchUserList.push(...res.data);
        })
      }
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

    // 修改：使用路径参数调用接口
    addAdminService(tenantId, user.userId!).then((res) => {
      if (res.data) {
        promptAction.showToast({
          message: '设为管理员成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 更新本地数据 - 修改：role字段
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

    // 修改：使用路径参数调用接口
    deleteAdminService(tenantId, user.userId!).then((res) => {
      if (res.data) {
        promptAction.showToast({
          message: '取消管理员成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 更新本地数据 - 修改：role字段
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