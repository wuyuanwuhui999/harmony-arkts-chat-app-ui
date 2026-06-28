import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { CompanyUserType, UserDataType, CompanyType } from '../type/Index';
import { getCompanyUsersService, removeCompanyUserService, setAdminService, cancelAdminService } from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import AvaterComponent from '../components/AvaterComponent';
import DialogComponent from '../components/DialogComponent';
import { USER_DATA, COMPANY_DATA, PAGE_SIZE } from '../common/constant';

@Entry
@Component
struct UserManagePage {
  @State userList: CompanyUserType[] = [];
  @State keyword: string = '';
  @State loading: boolean = false;
  @State pageNum: number = 1;
  @State total: number = 0;
  @State showLoading: boolean = false;
  private loadingController: LoadingController = new LoadingController();
  private dialogController: CustomDialogController | null = null;
  private deleteIndex: number = -1;
  private companyId: string = '';
  private companyRole: number = 0;

  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @StorageLink(COMPANY_DATA) companyData: CompanyType | null = null;

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  aboutToAppear() {
    // 获取传递的参数
    const params = router.getParams() as Record<string, Object>;
    this.companyId = (params?.companyId as string) || this.companyData?.id || '';
    this.companyRole = (params?.companyRole as number) || this.companyData?.role || 0;

    if (!this.companyId) {
      promptAction.showToast({
        message: '获取公司信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    this.loadUserList();
  }

  /**
   * @description: 加载用户列表
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  loadUserList() {
    this.loadingController.showLoading();
    getCompanyUsersService({
      companyId: this.companyId,
      pageNum: this.pageNum,
      pageSize: PAGE_SIZE,
      keyword: this.keyword || undefined
    }).then((res) => {
      this.total = res.total;
      if (this.pageNum === 1) {
        this.userList = res.data || [];
      } else {
        this.userList = this.userList.concat(res.data || []);
      }
    }).catch((err: Error) => {
      console.error('获取用户列表失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '获取用户列表失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 搜索用户
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  searchUsers() {
    this.pageNum = 1;
    this.loadUserList();
  }

  /**
   * @description: 加载更多（分页）
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  loadMore() {
    if (this.total > this.pageNum * PAGE_SIZE) {
      this.pageNum++;
      this.loadUserList();
    }
  }

  /**
   * @description: 删除用户确认弹窗
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  showDeleteDialog(index: number) {
    this.deleteIndex = index;
    const user = this.userList[index];
    this.dialogController = new CustomDialogController({
      customStyle: false,
      builder: DialogComponent({
        title: `确定要删除用户 "${user.username}" 吗？`,
        cancel: (): void => this.dialogController?.close(),
        confirm: (): void => this.deleteUser()
      }),
      alignment: DialogAlignment.Center,
    });
    this.dialogController.open();
  }

  /**
   * @description: 删除用户
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  deleteUser() {
    const user = this.userList[this.deleteIndex];
    this.loadingController.showLoading();
    removeCompanyUserService(user.userId || user.id, this.companyId).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '删除用户成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        this.userList.splice(this.deleteIndex, 1);
        this.dialogController?.close();
      } else {
        promptAction.showToast({
          message: res.msg || '删除用户失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      promptAction.showToast({
        message: '删除用户失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 设为管理员
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  setAdmin(index: number) {
    const user = this.userList[index];
    this.loadingController.showLoading();
    setAdminService(user.userId || user.id, this.companyId).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '设为管理员成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        user.role = 1;
        this.userList.splice(index, 1, JSON.parse(JSON.stringify(user)));
      } else {
        promptAction.showToast({
          message: res.msg || '设为管理员失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch(() => {
      promptAction.showToast({
        message: '设为管理员失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 取消管理员
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  cancelAdmin(index: number) {
    const user = this.userList[index];
    this.loadingController.showLoading();
    cancelAdminService(user.userId || user.id, this.companyId).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '取消管理员成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        user.role = 0;
        this.userList.splice(index, 1, JSON.parse(JSON.stringify(user)));
      } else {
        promptAction.showToast({
          message: res.msg || '取消管理员失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch(() => {
      promptAction.showToast({
        message: '取消管理员失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 跳转到添加用户页面
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  goToAddUser() {
    router.pushUrl({
      url: 'pages/AddCompanyUserPage',
      params: {
        companyId: this.companyId,
        companyRole: this.companyRole
      }
    });
  }

  /**
   * @description: 渲染用户列表项
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  @Builder
  userItemBuilder(item: CompanyUserType, index: number) {
    Row() {
      // 头像
      AvaterComponent({
        dimensions: size.middleAvater,
        avater: item.avater
      })
        .margin({ right: size.middleGap })

      // 用户信息
      Column({ space: size.miniGap }) {
        Row() {
          Text(item.username)
            .fontSize(size.middleFont)
            .fontColor(colors.black)

          // 管理员标签
          if (item.role > 0) {
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
              .margin({ left: size.smallGap })
          }
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Text(item.userAccount || '暂无工号')
          .fontSize(12)
          .fontColor(colors.gray)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({
      top: index == 0 ? 0 : size.middleGap,
      bottom: index == this.userList.length - 1  ?  0 : size.middleGap
    })
    .border({
      width: { bottom: index == this.userList.length - 1 ? 0 : 1 },
      color: { bottom: colors.pageBackground },
      style: { bottom: BorderStyle.Solid }
    })
  }

  /**
   * @description: 用户列表项滑动操作按钮
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  @Builder
  swipeActionBuilder(item: CompanyUserType, index: number) {
    Row() {
      // 设为管理员/取消管理员按钮（仅超级管理员可操作）
      if (this.companyRole === 2) {
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
            this.cancelAdmin(index);
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
            this.setAdmin(index);
          })
        }
      }

      // 删除按钮（管理员和超级管理员都可以显示）
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
        this.showDeleteDialog(index);
      })
    }
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        NavigatorTitleComponent({
          title: '用户管理',
          rightContent: this.AddIconBuilder.bind(this)
        })

        // 内容区
        Column({space:size.middleGap}) {
          // 搜索框
          Row() {
            TextInput({
              placeholder: '请输入用户姓名/工号/电话/邮箱',
              text: this.keyword
            })
              .height(size.inputHeight)
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value) => {
                this.keyword = value;
              })

            if (this.keyword) {
              Image($r('app.media.icon_clear'))
                .width(size.smallIcon)
                .height(size.smallIcon)
                .margin({ left: size.smallGap })
                .onClick(() => {
                  this.keyword = '';
                })
            }

            Image($r('app.media.icon_search'))
              .width(size.smallIcon)
              .height(size.smallIcon)
              .margin({ left: size.smallGap, right: size.middleGap })
              .onClick(() => {
                this.searchUsers();
              })
          }
          .backgroundColor(colors.white)
          .borderRadius(size.inputHeight / 2)
          .width('100%')
          .margin({top:size.middleGap})
          .padding({ left: size.middleGap })
          .alignItems(VerticalAlign.Center)

          // 用户列表
          if (this.userList.length === 0) {
            Column() {
              Text('暂无用户')
                .fontColor(colors.gray)
                .padding(size.middleGap)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.userList, (item: CompanyUserType, index: number) => {
                ListItem() {
                  this.userItemBuilder(item, index)
                }
                .swipeAction({
                  end: () => {
                    // 只有当前登录人是管理员或超级管理员才显示滑动操作
                    if (this.companyRole > 0) {
                      return this.swipeActionBuilder(item, index);
                    }
                    return this.EmptyBuilder();
                  }
                })
              })
            }
            .padding(size.middleGap)
            .width('100%')
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis)
            .onScrollIndex((start: number, end: number) => {
              if (end >= this.userList.length - 3) {
                this.loadMore();
              }
            })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(colors.pageBackground)
        .padding({
          left: size.middleGap,
          right: size.middleGap,
          bottom: size.middleGap
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(colors.pageBackground)

      // 加载组件
      GlobalLoading({ controller: this.loadingController })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  AddIconBuilder() {
    Image($r('app.media.icon_add'))
      .width(size.smallIcon)
      .height(size.smallIcon)
      .onClick(() => {
        this.goToAddUser();
      })
  }

  @Builder
  EmptyBuilder() {
    Column()
      .width(0)
      .height('100%')
  }
}

export default UserManagePage;