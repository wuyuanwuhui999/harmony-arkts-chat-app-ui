// ets/pages/PromptManagePage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { PromptInterface, UserDataType } from '../type/Index';
import {
  getPromptListService,
  deletePromptService,
  updatePromptService
} from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import DialogComponent from '../components/DialogComponent';
import preference from '../utils/PreferenceModel';
import { USER_DATA } from '../common/constant';

@Entry
@Component
struct PromptManagePage {
  @State promptList: PromptInterface[] = [];
  @State keyword: string = '';
  @State showLoading: boolean = false;
  @State currentPromptId: string = ''; // 当前正在使用的提示词ID
  private loadingController: LoadingController = new LoadingController();
  private dialogController: CustomDialogController | null = null;
  private editDialogController: CustomDialogController | null = null;
  private tenantId: string = '';
  private tenantName: string = '';
  private editPromptId: string = '';
  private editPromptContent: string = '';
  private searchTimer: number = 0;
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;

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

    if (!this.tenantId) {
      promptAction.showToast({
        message: '获取租户信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 获取当前使用的提示词ID
    this.loadCurrentPromptId();
    // 加载提示词列表
    this.loadPromptList();
  }

  /**
   * @description: 加载当前使用的提示词ID
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  async loadCurrentPromptId() {
    this.currentPromptId = await preference.getPreference(`${this.userData.id}:${this.tenantId}:promptId`) || '';
  }

  /**
   * @description: 加载提示词列表
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  loadPromptList() {
    this.loadingController.showLoading();
    getPromptListService(this.tenantId, this.keyword.trim())
      .then((res) => {
        this.promptList = res.data || [];
      })
      .catch((err: Error) => {
        console.error('获取提示词列表失败:', JSON.stringify(err));
        promptAction.showToast({
          message: '获取提示词列表失败，请重试',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      })
      .finally(() => {
        this.loadingController.hideLoading();
      });
  }

  /**
   * @description: 防抖搜索
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  private debounceSearch(): void {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer);
      this.searchTimer = 0;
    }

    this.searchTimer = setTimeout(() => {
      this.loadPromptList();
    }, 300);
  }

  /**
   * @description: 清空搜索关键词
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  private clearSearch(): void {
    this.keyword = '';
    this.loadPromptList();
  }

  /**
   * @description: 跳转到添加提示词页面
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  goToAddPrompt() {
    router.pushUrl({
      url: 'pages/AddPromptPage',
      params: {
        tenantId: this.tenantId
      }
    });
  }

  /**
   * @description: 删除提示词
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  deletePrompt(index: number) {
    const prompt = this.promptList[index];
    if (!prompt) return;

    this.dialogController = new CustomDialogController({
      customStyle: false,
      builder: DialogComponent({
        title: `确定要删除提示词吗？`,
        cancel: (): void => this.dialogController?.close(),
        confirm: (): void => {
          this.doDeletePrompt(index);
        }
      }),
      alignment: DialogAlignment.Center,
    });
    this.dialogController.open();
  }

  /**
   * @description: 执行删除提示词
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  doDeletePrompt(index: number) {
    const prompt = this.promptList[index];
    if (!prompt) return;

    this.loadingController.showLoading();
    deletePromptService(prompt.id).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '删除成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        this.promptList.splice(index, 1);
        this.dialogController?.close();

        // 如果删除的是当前使用的提示词，清空缓存中的提示词ID
        if (this.currentPromptId === prompt.id) {
          this.currentPromptId = '';
          preference.putPreference(`${this.userData.id}:${this.tenantId}:promptId`, '');
        }
      } else {
        promptAction.showToast({
          message: res.msg || '删除失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      console.error('删除提示词失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '删除失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 显示编辑提示词弹窗
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  showEditDialog(index: number) {
    const prompt = this.promptList[index];
    if (!prompt) return;

    this.editPromptId = prompt.id;
    this.editPromptContent = prompt.prompt;

    this.editDialogController = new CustomDialogController({
      customStyle: true,
      builder: this.editPromptDialogBuilder.bind(this),
      alignment: DialogAlignment.Center,
      autoCancel: true,
    });
    this.editDialogController.open();
  }

  /**
   * @description: 编辑提示词弹窗构建器
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  @Builder
  editPromptDialogBuilder() {
    Column({ space: size.middleGap }) {
      Text('编辑提示词')
        .fontSize(size.bigFont)
        .fontWeight(FontWeight.Medium)
        .margin({ top: size.middleGap })

      // 提示词编辑框
      TextArea({
        text: this.editPromptContent,
        placeholder: '请输入提示词内容'
      })
        .height(size.textareaHeight)
        .width('100%')
        .backgroundColor(colors.pageBackground)
        .borderRadius(size.middleBorderRaduis)
        .padding(size.middleGap)
        .onChange((value: string) => {
          this.editPromptContent = value;
        })

      // 确定/取消按钮
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
            this.editDialogController?.close();
          })

        Text('确定')
          .width('45%')
          .height(size.btnHeight)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .backgroundColor(this.editPromptContent.trim() ? colors.primary : colors.gray)
          .borderRadius(size.btnHeight / 2)
          .enabled(!!this.editPromptContent.trim())
          .onClick(() => {
            if (this.editPromptContent.trim()) {
              this.doUpdatePrompt();
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
      right: size.middleGap
    })
  }

  /**
   * @description: 执行更新提示词
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  doUpdatePrompt() {
    if (!this.editPromptContent.trim()) {
      promptAction.showToast({
        message: '提示词不能为空',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    this.loadingController.showLoading();
    const promptData: PromptInterface = {
      id: this.editPromptId,
      tenantId: this.tenantId,
      userId: '',
      prompt: this.editPromptContent.trim()
    };

    updatePromptService(promptData).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '更新成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        this.editDialogController?.close();
        // 刷新列表
        this.loadPromptList();
      } else {
        promptAction.showToast({
          message: res.msg || '更新失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      console.error('更新提示词失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '更新失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 使用提示词
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  async usePrompt(index: number) {
    const prompt = this.promptList[index];
    if (!prompt) return;

    // 保存提示词ID到缓存
    await preference.putPreference(`${this.userData.id}:${this.tenantId}:promptId`, prompt.id);
    this.currentPromptId = prompt.id;

    promptAction.showToast({
      message: '已切换到该提示词',
      duration: 2000,
      bottom: px2vp(display.getDefaultDisplaySync().height) / 2
    });

    // 刷新列表
    this.loadPromptList();
  }

  /**
   * @description: 提示词列表项构建器
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  @Builder
  promptItemBuilder(item: PromptInterface, index: number) {
    Column({ space: size.smallGap }) {
      // 提示词内容 - 最多显示两行
      Text(item.prompt)
        .fontSize(size.middleFont)
        .fontColor(colors.black)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 当前使用中标签
      if (this.currentPromptId === item.id) {
        Text('当前使用中')
          .fontSize(12)
          .fontColor(colors.primary)
          .padding({
            left: size.smallGap,
            right: size.smallGap,
            top: 2,
            bottom: 2
          })
          .border({
            width: 1,
            color: colors.primary,
            style: BorderStyle.Solid
          })
          .borderRadius(4)
          .margin({ top: size.miniGap })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({
      top: size.middleGap,
      bottom: size.middleGap
    })
    .border({
      width: { bottom: index === this.promptList.length - 1 ? 0 : 1 },
      color: { bottom: colors.pageBackground },
      style: { bottom: BorderStyle.Solid }
    })
  }

  /**
   * @description: 滑动操作按钮
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  @Builder
  swipeActionBuilder(item: PromptInterface, index: number) {
    Row() {
      // 使用按钮
      Column() {
        Text('使用')
          .fontColor(Color.White)
          .fontSize(14)
      }
      .justifyContent(FlexAlign.Center)
      .width(80)
      .height('100%')
      .backgroundColor(colors.primary)
      .onClick(() => {
        this.usePrompt(index);
      })

      // 编辑按钮
      Column() {
        Text('编辑')
          .fontColor(Color.White)
          .fontSize(14)
      }
      .justifyContent(FlexAlign.Center)
      .width(80)
      .height('100%')
      .backgroundColor(colors.gray)
      .onClick(() => {
        this.showEditDialog(index);
      })

      // 删除按钮
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
        this.deletePrompt(index);
      })
    }
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        NavigatorTitleComponent({
          title: '提示词管理',
          rightContent: this.AddIconBuilder.bind(this)
        })

        // 内容区
        Column({ space: size.middleGap }) {
          // 搜索框
          Row() {
            TextInput({
              placeholder: '请输入关键字搜索',
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
                this.loadPromptList();
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
                this.loadPromptList();
              })
          }
          .margin({ top: size.middleGap })
          .backgroundColor(colors.white)
          .borderRadius(size.inputHeight / 2)
          .width('100%')
          .padding({ left: size.middleGap })
          .alignItems(VerticalAlign.Center)

          // 提示词列表
          if (this.promptList.length === 0) {
            Column() {
              Text('暂无提示词')
                .fontColor(colors.gray)
                .padding(size.middleGap)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.promptList, (item: PromptInterface, index: number) => {
                ListItem() {
                  this.promptItemBuilder(item, index)
                }
                .swipeAction({
                  end: () => {
                    return this.swipeActionBuilder(item, index);
                  }
                })
              })
            }
            .width('100%')
            .padding({ left: size.middleGap, right: size.middleGap })
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis)
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
        this.goToAddPrompt();
      })
  }
}

export default PromptManagePage;