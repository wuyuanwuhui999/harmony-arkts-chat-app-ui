import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import {
  SearchUserType,
  DepartmentType,
  PositionType,
  AddCompanyUserParams,
  CompanyType
} from '../type/Index';
import {
  searchUsersByCompanyService,
  addCompanyUserService,
  getDepartmentsService,
  getPositionsService
} from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import AvaterComponent from '../components/AvaterComponent';
import OptionDialogComponent from '../components/OptionDialogComponent';
import { COMPANY_DATA, PAGE_SIZE } from '../common/constant';

@Entry
@Component
struct AddCompanyUserPage {
  @State searchUserList: SearchUserType[] = [];
  @State keyword: string = '';
  @State pageNum: number = 1;
  @State total: number = 0;
  @State showLoading: boolean = false;
  @State isSuperAdmin: boolean = false;
  private loadingController: LoadingController = new LoadingController();
  private dialogController: CustomDialogController | null = null;
  private companyId: string = '';
  private companyRole: number = 0;
  // 添加用户弹窗相关状态
  private selectedUserId: string = '';
  private selectedRole: number = 0;
  private departmentList: DepartmentType[] = [];
  private positionList: PositionType[] = [];
  private selectedDepartmentId: string = '';
  private selectedPositionId: string = '';

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
    const params = router.getParams() as Record<string, Object>;
    this.companyId = (params?.companyId as string) || this.companyData?.id || '';
    this.companyRole = (params?.companyRole as number) || this.companyData?.role || 0;
    this.isSuperAdmin = this.companyRole === 2;

    if (!this.companyId) {
      promptAction.showToast({
        message: '获取公司信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }
  }

  /**
   * @description: 搜索用户
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  searchUsers() {
    if (!this.keyword.trim()) {
      promptAction.showToast({
        message: '请输入搜索关键字',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    this.pageNum = 1;
    this.loadingController.showLoading();
    searchUsersByCompanyService(this.companyId, this.keyword.trim(), this.pageNum, PAGE_SIZE)
      .then((res) => {
        this.total = res.total;
        this.searchUserList = res.data || [];
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

  /**
   * @description: 加载更多搜索结果
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  loadMore() {
    if (this.total > this.pageNum * PAGE_SIZE) {
      this.pageNum++;
      this.loadingController.showLoading();
      searchUsersByCompanyService(this.companyId, this.keyword.trim(), this.pageNum, PAGE_SIZE)
        .then((res) => {
          this.searchUserList = this.searchUserList.concat(res.data || []);
        })
        .catch((err: Error) => {
          console.error('加载更多失败:', JSON.stringify(err));
        })
        .finally(() => {
          this.loadingController.hideLoading();
        });
    }
  }

  /**
   * @description: 加载部门列表
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  loadDepartments() {
    getDepartmentsService(this.companyId).then((res) => {
      this.departmentList = res.data || [];
    }).catch((err: Error) => {
      console.error('获取部门列表失败:', JSON.stringify(err));
    });
  }

  /**
   * @description: 加载职位列表
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  loadPositions(departmentId: string) {
    this.selectedDepartmentId = departmentId;
    this.selectedPositionId = '';
    this.positionList = [];
    getPositionsService(departmentId).then((res) => {
      this.positionList = res.data || [];
    }).catch((err: Error) => {
      console.error('获取职位列表失败:', JSON.stringify(err));
    });
  }

  /**
   * @description: 显示添加用户对话框
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  showAddUserDialog(user: SearchUserType) {
    this.selectedUserId = user.id || '';
    this.selectedRole = 0;
    this.selectedDepartmentId = '';
    this.selectedPositionId = '';
    this.positionList = [];

    // 加载部门列表
    this.loadDepartments();

    // 如果是超级管理员，显示带角色选项的对话框
    if (this.isSuperAdmin) {
      this.dialogController = new CustomDialogController({
        customStyle: true,
        builder: this.addUserDialogBuilder(),
        alignment: DialogAlignment.Center,
      });
    } else {
      // 普通管理员直接添加
      this.addUserDirect(0);
    }
    this.dialogController?.open();
  }

  /**
   * @description: 添加用户对话框构建器
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  @Builder
  addUserDialogBuilder() {
    Column({ space: size.middleGap }) {
      Text('添加用户')
        .fontSize(size.bigFont)
        .fontWeight(FontWeight.Medium)
        .margin({ top: size.middleGap })

      // 角色选择（仅超级管理员显示）
      if (this.isSuperAdmin) {
        Column({ space: size.smallGap }) {
          Text('角色')
            .fontSize(size.middleFont)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .textAlign(TextAlign.Start)

          Row({ space: size.middleGap }) {
            this.roleOption('普通用户', 0)
            this.roleOption('管理员', 1)
          }
          .width('100%')
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
      }

      // 部门选择
      Column({ space: size.smallGap }) {
        Text('部门')
          .fontSize(size.middleFont)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .textAlign(TextAlign.Start)

        Row() {
          Text(this.selectedDepartmentId ?
            this.departmentList.find(d => d.id === this.selectedDepartmentId)?.departmentName || '请选择部门' :
            '请选择部门')
            .fontColor(this.selectedDepartmentId ? colors.black : colors.gray)
            .layoutWeight(1)
          Image($r('app.media.icon_arrow'))
            .width(size.smallIcon)
            .height(size.smallIcon)
            .opacity(size.opacity)
        }
        .width('100%')
        .padding({
          top: size.middleGap,
          bottom: size.middleGap,
          left: size.middleGap,
          right: size.middleGap
        })
        .border({
          width: 1,
          color: colors.borderColor,
          style: BorderStyle.Solid
        })
        .borderRadius(size.middleBorderRaduis)
        .onClick(() => {
          this.showDepartmentDialog();
        })
      }
      .width('100%')

      // 职位选择
      Column({ space: size.smallGap }) {
        Text('职位')
          .fontSize(size.middleFont)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .textAlign(TextAlign.Start)

        Row() {
          Text(this.selectedPositionId ?
            this.positionList.find(p => p.id === this.selectedPositionId)?.positionName || '请选择职位' :
            '请选择职位')
            .fontColor(this.selectedPositionId ? colors.black : colors.gray)
            .layoutWeight(1)
          Image($r('app.media.icon_arrow'))
            .width(size.smallIcon)
            .height(size.smallIcon)
            .opacity(size.opacity)
        }
        .width('100%')
        .padding({
          top: size.middleGap,
          bottom: size.middleGap,
          left: size.middleGap,
          right: size.middleGap
        })
        .border({
          width: 1,
          color: colors.borderColor,
          style: BorderStyle.Solid
        })
        .borderRadius(size.middleBorderRaduis)
        .onClick(() => {
          if (!this.selectedDepartmentId) {
            promptAction.showToast({
              message: '请先选择部门',
              duration: 2000,
              bottom: px2vp(display.getDefaultDisplaySync().height) / 2
            });
            return;
          }
          this.showPositionDialog();
        })
      }
      .width('100%')

      Row({ space: size.middleGap }) {
        Text('取消')
          .width('45%')
          .height(size.btnHeight)
          .textAlign(TextAlign.Center)
          .fontColor(colors.gray)
          .border({
            width: 1,
            color: colors.gray,
            style: BorderStyle.Solid
          })
          .borderRadius(size.btnHeight / 2)
          .onClick(() => {
            this.dialogController?.close();
          })

        Text('确定')
          .width('45%')
          .height(size.btnHeight)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .backgroundColor(colors.primary)
          .borderRadius(size.btnHeight / 2)
          .enabled(!!(this.selectedDepartmentId && this.selectedPositionId))
          .onClick(() => {
            if (this.selectedDepartmentId && this.selectedPositionId) {
              this.addUserDirect(this.selectedRole);
              this.dialogController?.close();
            } else {
              promptAction.showToast({
                message: '请选择部门和职位',
                duration: 2000,
                bottom: px2vp(display.getDefaultDisplaySync().height) / 2
              });
            }
          })
      }
      .width('100%')
      .margin({ bottom: size.middleGap })
    }
    .width('90%')
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding({
      left: size.middleGap,
      right: size.middleGap,
      bottom: size.middleGap
    })
  }

  /**
   * @description: 角色选项
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  @Builder
  roleOption(label: string, value: number) {
    Row({ space: size.smallGap }) {
      Circle({ width: 20, height: 20 })
        .fill(this.selectedRole === value ? colors.primary : Color.Transparent)
        .stroke(this.selectedRole === value ? colors.primary : colors.gray)
        .strokeWidth(2)
      Text(label)
        .fontSize(size.middleFont)
    }
    .onClick(() => {
      this.selectedRole = value;
    })
  }

  /**
   * @description: 显示部门选择对话框
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  showDepartmentDialog() {
    if (this.departmentList.length === 0) {
      promptAction.showToast({
        message: '暂无部门可选',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    const options = this.departmentList.map(d => d.departmentName);
    const tempDialog = new CustomDialogController({
      customStyle: true,
      builder: OptionDialogComponent({
        cancel: (): void => tempDialog.close(),
        confirm: (value: string, index: number) => {
          const department = this.departmentList[index];
          if (department) {
            this.loadPositions(department.id);
            tempDialog.close();
          }
        },
        options: options
      }),
      alignment: DialogAlignment.Bottom,
    });
    tempDialog.open();
  }

  /**
   * @description: 显示职位选择对话框
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  showPositionDialog() {
    if (this.positionList.length === 0) {
      promptAction.showToast({
        message: '暂无职位可选',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    const options = this.positionList.map(p => p.positionName);
    const tempDialog = new CustomDialogController({
      customStyle: true,
      builder: OptionDialogComponent({
        cancel: (): void => tempDialog.close(),
        confirm: (value: string, index: number) => {
          const position = this.positionList[index];
          if (position) {
            this.selectedPositionId = position.id;
            tempDialog.close();
          }
        },
        options: options
      }),
      alignment: DialogAlignment.Bottom,
    });
    tempDialog.open();
  }

  /**
   * @description: 直接添加用户
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  addUserDirect(role: number) {
    // 普通管理员只能添加普通用户
    if (!this.isSuperAdmin) {
      role = 0;
    }

    const params: AddCompanyUserParams = {
      userId: this.selectedUserId,
      companyId: this.companyId,
      role: role,
      positionId: this.selectedPositionId || ''
    };

    this.loadingController.showLoading();
    addCompanyUserService(params).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '添加用户成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 更新列表中的状态
        const index = this.searchUserList.findIndex(u => u.id === this.selectedUserId);
        if (index !== -1) {
          this.searchUserList[index].checked = 1;
          this.searchUserList.splice(index, 1, JSON.parse(JSON.stringify(this.searchUserList[index])));
        }
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
   * @date: 2026-06-26
   * @author wuwenqiang
   */
  @Builder
  userItemBuilder(item: SearchUserType, index: number) {
    Column() {
      Row() {
        AvaterComponent({
          dimensions: size.middleIcon,
          avater: item.avater
        })
          .margin({ right: size.middleGap })

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

        // 添加按钮
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
              this.showAddUserDialog(item);
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

  build() {
    Stack() {
      Column() {
        // 标题栏
        NavigatorTitleComponent({
          title: '添加用户'
        })

        // 内容区
        Column({space:size.middleGap}) {
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
              .onSubmit(() => {
                this.searchUsers();
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
          .margin({top:size.middleGap})
          .backgroundColor(colors.white)
          .borderRadius(size.inputHeight / 2)
          .width('100%')
          .padding({ left: size.middleGap })
          .alignItems(VerticalAlign.Center)

          // 用户列表
          if (this.searchUserList.length === 0) {
            Column() {
              Text(this.keyword ? '未找到相关用户' : '请输入关键字搜索用户')
                .fontColor(colors.gray)
                .padding(size.middleGap)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.searchUserList, (item: SearchUserType, index: number) => {
                ListItem() {
                  this.userItemBuilder(item, index)
                }
              })
            }
            .width('100%')
            .padding({left:size.middleGap,right:size.middleGap})
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis)
            .onScrollIndex((start: number, end: number) => {
              if (end >= this.searchUserList.length - 3) {
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
}

export default AddCompanyUserPage;