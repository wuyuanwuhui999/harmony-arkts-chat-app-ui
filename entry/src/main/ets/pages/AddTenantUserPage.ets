import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { UserWithChecked } from '../type/Index';
import {
  searchUserListService,
  addTenantUserService
} from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import AvaterComponent from '../components/AvaterComponent';
import { PAGE_SIZE } from '../common/constant';

@Entry
@Component
struct AddTenantUserPage {
  @State searchUserList: UserWithChecked[] = [];
  @State keyword: string = '';
  @State pageNum: number = 1;
  @State total: number = 0;
  @State hasLoadedAll: boolean = false;
  private loadingController: LoadingController = new LoadingController();
  private searchTimer: number = 0;
  private tenantId: string = '';
  private tenantName: string = '';
  private companyId: string = '';  // 新增：公司ID

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    this.tenantId = (params?.tenantId as string) || '';
    this.tenantName = (params?.tenantName as string) || '';
    this.companyId = (params?.companyId as string) || '';  // 新增：获取公司ID

    if (!this.tenantId) {
      promptAction.showToast({
        message: '获取租户信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    if (!this.companyId) {
      console.warn('[AddTenantUserPage] 未获取到公司ID，搜索用户可能受限');
    }
  }

  /**
   * @description: 防抖搜索
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  private debounceSearch(): void {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = 0;
    }

    if (!this.keyword.trim()) {
      this.searchUserList = [];
      this.total = 0;
      this.pageNum = 1;
      this.hasLoadedAll = false;
      return;
    }

    this.searchTimer = setTimeout(() => {
      this.pageNum = 1;
      this.hasLoadedAll = false;
      this.loadingController.showLoading();
      searchUserListService(encodeURIComponent(this.keyword.trim()), this.tenantId, this.companyId, this.pageNum, PAGE_SIZE)
        .then((res) => {
          this.total = res.total;
          this.searchUserList = res.data || [];
          this.hasLoadedAll = this.searchUserList.length >= this.total;
        })
        .catch((err: Error) => {
          console.error('搜索用户失败:', JSON.stringify(err));
          promptAction.showToast({
            message: '搜索用户失败，请重试',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
        })
        .finally(() => {
          this.loadingController.hideLoading();
        });
    }, 300);
  }

  /**
   * @description: 立即搜索（回车或点击搜索按钮触发）
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  private doSearch(): void {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = 0;
    }
    if (this.keyword.trim()) {
      this.pageNum = 1;
      this.hasLoadedAll = false;
      this.loadingController.showLoading();
      searchUserListService(this.keyword.trim(), this.tenantId, this.companyId, this.pageNum, PAGE_SIZE)
        .then((res) => {
          this.total = res.total;
          this.searchUserList = res.data || [];
          this.hasLoadedAll = this.searchUserList.length >= this.total;
        })
        .catch((err: Error) => {
          console.error('搜索用户失败:', JSON.stringify(err));
          promptAction.showToast({
            message: '搜索用户失败，请重试',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
        })
        .finally(() => {
          this.loadingController.hideLoading();
        });
    }
  }

  /**
   * @description: 清空搜索
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  private clearSearch(): void {
    this.keyword = '';
    this.searchUserList = [];
    this.total = 0;
    this.pageNum = 1;
    this.hasLoadedAll = false;
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = 0;
    }
  }

  /**
   * @description: 加载更多
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  private loadMore(): void {
    if (this.hasLoadedAll || this.total === 0) {
      return;
    }

    if (this.searchUserList.length >= this.total) {
      this.hasLoadedAll = true;
      return;
    }

    if (this.pageNum * PAGE_SIZE >= this.total) {
      this.hasLoadedAll = true;
      return;
    }

    this.pageNum++;
    this.loadingController.showLoading();
    searchUserListService(this.keyword.trim(), this.tenantId, this.companyId, this.pageNum, PAGE_SIZE)
      .then((res) => {
        const newData = res.data || [];
        this.searchUserList = this.searchUserList.concat(newData);
        this.hasLoadedAll = this.searchUserList.length >= this.total;
      })
      .catch((err: Error) => {
        console.error('加载更多失败:', JSON.stringify(err));
        promptAction.showToast({
          message: '加载更多失败，请重试',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        this.pageNum--;
      })
      .finally(() => {
        this.loadingController.hideLoading();
      });
  }

  /**
   * @description: 添加用户
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  onAddUser(index: number) {
    const user = this.searchUserList[index];
    if (!user) return;

    // 如果已经添加，提示
    if (user.checked === 1) {
      promptAction.showToast({
        message: '该用户已添加',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    this.loadingController.showLoading();
    addTenantUserService(this.tenantId, user.id!).then((res) => {
      if (res.data) {
        promptAction.showToast({
          message: '添加用户成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 更新状态
        user.checked = 1;
        this.searchUserList.splice(index, 1, JSON.parse(JSON.stringify(user)));
      } else {
        promptAction.showToast({
          message: res.msg || '添加用户失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      console.error('添加用户失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '添加用户失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 用户列表项构建器
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  @Builder
  UserItemBuilder(item: UserWithChecked, index: number) {
    Column() {
      Row() {
        // 头像
        AvaterComponent({
          dimensions: size.middleIcon,
          avater: item.avater
        })
          .margin({ right: size.middleGap })

        // 用户信息：用户名 + 工号（纵向排列）
        Column({ space: size.miniGap }) {
          Text(item.username)
            .fontSize(size.middleFont)
            .fontColor(colors.black)

          Text(item.userAccount || '')
            .fontSize(12)
            .fontColor(colors.gray)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        // 添加/已添加按钮
        if (item.checked === 1) {
          Text('已添加')
            .fontColor(Color.White)
            .backgroundColor(colors.gray)
            .padding({
              left: size.middleGap,
              right: size.middleGap,
              top: size.smallGap,
              bottom: size.smallGap
            })
            .borderRadius(size.btnHeight / 2)
        } else {
          Text('添加')
            .fontColor(Color.White)
            .backgroundColor(colors.primary)
            .padding({
              left: size.middleGap,
              right: size.middleGap,
              top: size.smallGap,
              bottom: size.smallGap
            })
            .borderRadius(size.btnHeight / 2)
            .onClick(() => {
              this.onAddUser(index);
            })
        }
      }
      .width('100%')
      .padding({
        top: size.middleGap,
        bottom: size.middleGap
      })

      // 分割线
      if (index !== this.searchUserList.length - 1) {
        Divider()
          .height(1)
          .color(colors.pageBackground)
      }
    }
  }

  /**
   * @description: 底部加载状态
   * @date: 2026-06-28
   * @author wuwenqiang
   */
  @Builder
  LoadMoreFooter() {
    if (this.searchUserList.length > 0) {
      Column() {
        Text(this.hasLoadedAll ? '已加载全部数据' : '加载中...')
          .fontColor(colors.gray)
          .fontSize(size.middleFont)
          .padding({
            top: size.middleGap,
            bottom: size.middleGap
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        NavigatorTitleComponent({
          title: `添加用户 - ${this.tenantName}`
        })

        // 内容区
        Column({ space: size.middleGap }) {
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
                this.debounceSearch();
              })
              .onSubmit(() => {
                this.doSearch();
              })

            if (this.keyword) {
              Image($r('app.media.icon_clear'))
                .width(size.smallIcon)
                .height(size.smallIcon)
                .margin({ left: size.smallGap })
                .onClick(() => {
                  this.clearSearch();
                })
            }

            Image($r('app.media.icon_search'))
              .width(size.smallIcon)
              .height(size.smallIcon)
              .margin({ left: size.smallGap, right: size.middleGap })
              .onClick(() => {
                this.doSearch();
              })
          }
          .margin({ top: size.middleGap })
          .backgroundColor(colors.white)
          .borderRadius(size.inputHeight / 2)
          .width('100%')
          .padding({ left: size.middleGap })
          .alignItems(VerticalAlign.Center)

          // 用户列表
          if (this.searchUserList.length === 0 && !this.keyword.trim()) {
            Column() {
              Text('请输入关键字搜索用户')
                .fontColor(colors.gray)
                .padding(size.middleGap)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else if (this.searchUserList.length === 0 && this.keyword.trim()) {
            Column() {
              Text('未找到相关用户')
                .fontColor(colors.gray)
                .padding(size.middleGap)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.searchUserList, (item: UserWithChecked, index: number) => {
                ListItem() {
                  this.UserItemBuilder(item, index)
                }
              })
            }
            .width('100%')
            .padding({ left: size.middleGap, right: size.middleGap })
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis)
            .onScrollIndex((start: number, end: number) => {
              if (end >= this.searchUserList.length - 1 && this.keyword.trim()) {
                this.loadMore();
              }
            })
            this.LoadMoreFooter()
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
}

export default AddTenantUserPage;