// ets/pages/ModelManagePage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { ChatModelType, CompanyType } from '../type/Index';
import {
  getModelListService,
  deleteModelService
} from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';
import NavigatorTitleComponent from '../components/NavigatorTitleComponent';
import DialogComponent from '../components/DialogComponent';
import { COMPANY_DATA } from '../common/constant';
import preference from '../utils/PreferenceModel';

@Entry
@Component
struct ModelManagePage {
  @State modelList: ChatModelType[] = [];
  @State keyword: string = '';
  @State showLoading: boolean = false;
  @State currentModelId: string = ''; // 当前正在使用的模型ID
  private loadingController: LoadingController = new LoadingController();
  private dialogController: CustomDialogController | null = null;
  private searchTimer: number = 0;
  private companyId: string = '';

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  aboutToAppear() {
    // 获取公司信息
    const companyData = AppStorage.get<CompanyType>(COMPANY_DATA);
    this.companyId = companyData?.id || '';

    if (!this.companyId) {
      promptAction.showToast({
        message: '获取公司信息失败',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 加载当前使用的模型ID
    this.loadCurrentModelId();
    // 加载模型列表
    this.loadModelList();
  }

  /**
   * @description: 加载当前使用的模型ID
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  async loadCurrentModelId() {
    try {
      // 从缓存获取当前使用的模型ID - 使用公司ID作为缓存key的一部分
      const cachedId = await preference.getPreference(`${this.companyId}:currentModelId`);
      if (cachedId) {
        this.currentModelId = cachedId;
        console.log('[ModelManagePage] 加载当前模型ID成功:', this.currentModelId);
      } else {
        console.log('[ModelManagePage] 未找到缓存的模型ID');
      }
    } catch (error) {
      console.error('[ModelManagePage] 加载当前模型ID失败:', JSON.stringify(error));
    }
  }

  /**
   * @description: 加载模型列表
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  loadModelList() {
    if (!this.companyId) return;

    this.loadingController.showLoading();
    getModelListService(this.companyId, this.keyword.trim())
      .then((res) => {
        this.modelList = res.data || [];
        console.log('[ModelManagePage] 加载模型列表成功，数量:', this.modelList.length);
        // 加载完成后，检查当前模型是否在列表中
        this.checkCurrentModelInList();
      })
      .catch((err: Error) => {
        console.error('获取模型列表失败:', JSON.stringify(err));
        promptAction.showToast({
          message: '获取模型列表失败，请重试',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      })
      .finally(() => {
        this.loadingController.hideLoading();
      });
  }

  /**
   * @description: 检查当前模型是否在列表中，如果不在则清空缓存
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  private checkCurrentModelInList() {
    if (!this.currentModelId) return;

    const exists = this.modelList.some(item => item.id === this.currentModelId);
    if (!exists) {
      // 如果当前模型不在列表中，清空缓存
      this.currentModelId = '';
      preference.putPreference(`${this.companyId}:currentModelId`, '');
      console.log('[ModelManagePage] 当前模型不在列表中，已清空缓存');
    }
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
      this.loadModelList();
    }, 300);
  }

  /**
   * @description: 清空搜索关键词
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  private clearSearch(): void {
    this.keyword = '';
    this.loadModelList();
  }

  /**
   * @description: 跳转到添加模型页面
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  goToAddModel() {
    router.pushUrl({
      url: 'pages/AddModelPage',
      params: {
        companyId: this.companyId
      }
    });
  }

  /**
   * @description: 删除模型
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  deleteModel(index: number) {
    const model = this.modelList[index];
    if (!model) return;

    // 检查是否当前使用中
    if (this.currentModelId === model.id) {
      promptAction.showToast({
        message: '当前使用中的模型不能删除',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    this.dialogController = new CustomDialogController({
      customStyle: false,
      builder: DialogComponent({
        title: `确定要删除模型 "${model.modelName}" 吗？`,
        cancel: (): void => this.dialogController?.close(),
        confirm: (): void => {
          this.doDeleteModel(index);
        }
      }),
      alignment: DialogAlignment.Center,
    });
    this.dialogController.open();
  }

  /**
   * @description: 执行删除模型
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  doDeleteModel(index: number) {
    const model = this.modelList[index];
    if (!model) return;

    this.loadingController.showLoading();
    deleteModelService(model.id).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '删除成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        this.modelList.splice(index, 1);
        this.dialogController?.close();

        // 如果删除的是当前使用的模型，清空缓存
        if (this.currentModelId === model.id) {
          this.currentModelId = '';
          preference.putPreference(`${this.companyId}:currentModelId`, '');
        }
      } else {
        promptAction.showToast({
          message: res.msg || '删除失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      console.error('删除模型失败:', JSON.stringify(err));
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
   * @description: 跳转到编辑模型页面
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  goToUpdateModel(index: number) {
    const model = this.modelList[index];
    if (!model) return;

    router.pushUrl({
      url: 'pages/UpdateModelPage',
      params: {
        modelId: model.id,
        modelName: model.modelName,
        type: model.type,
        baseUrl: model.baseUrl,
        apiKey: model.apiKey || '',
        companyId: model.companyId
      }
    });
  }

  /**
   * @description: 使用模型
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  async useModel(index: number) {
    const model = this.modelList[index];
    if (!model) return;

    // 保存模型ID到缓存
    await preference.putPreference(`${this.companyId}:currentModelId`, model.id);
    this.currentModelId = model.id;
    console.log('[ModelManagePage] 切换到模型:', model.modelName, 'ID:', model.id);

    promptAction.showToast({
      message: `已切换到模型: ${model.modelName}`,
      duration: 2000,
      bottom: px2vp(display.getDefaultDisplaySync().height) / 2
    });

    // 刷新列表
    this.loadModelList();
  }

  /**
   * @description: 模型列表项构建器
   * @date: 2026-07-06
   * @author wuwenqiang
   */
  @Builder
  modelItemBuilder(item: ChatModelType, index: number) {
    Column({ space: size.smallGap }) {
      // 模型名称
      Text(item.modelName)
        .fontSize(size.middleFont)
        .fontColor(colors.black)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 模型类型
      Text(item.type === 'ollama' ? 'Ollama' : '在线模型')
        .fontSize(12)
        .fontColor(colors.gray)
        .width('100%')

      // 当前使用中标签
      if (this.currentModelId === item.id) {
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
      width: { bottom: index === this.modelList.length - 1 ? 0 : 1 },
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
  swipeActionBuilder(item: ChatModelType, index: number) {
    Row() {
      // 使用按钮 - 当前使用中禁用
      Column() {
        Text('使用')
          .fontColor(Color.White)
          .fontSize(14)
      }
      .justifyContent(FlexAlign.Center)
      .width(80)
      .height('100%')
      .backgroundColor(this.currentModelId === item.id ? colors.gray : colors.primary)
      .onClick(() => {
        if (this.currentModelId === item.id) {
          promptAction.showToast({
            message: '当前模型已在使用中',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
          return;
        }
        this.useModel(index);
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
        this.goToUpdateModel(index);
      })

      // 删除按钮 - 当前使用中禁用
      Column() {
        Text('删除')
          .fontColor(Color.White)
          .fontSize(14)
      }
      .justifyContent(FlexAlign.Center)
      .width(80)
      .height('100%')
      .backgroundColor(this.currentModelId === item.id ? colors.gray : colors.warn)
      .onClick(() => {
        if (this.currentModelId === item.id) {
          promptAction.showToast({
            message: '当前使用中的模型不能删除',
            duration: 2000,
            bottom: px2vp(display.getDefaultDisplaySync().height) / 2
          });
          return;
        }
        this.deleteModel(index);
      })
    }
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        NavigatorTitleComponent({
          title: '模型管理',
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
                this.loadModelList();
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
                this.loadModelList();
              })
          }
          .margin({ top: size.middleGap })
          .backgroundColor(colors.white)
          .borderRadius(size.inputHeight / 2)
          .width('100%')
          .padding({ left: size.middleGap })
          .alignItems(VerticalAlign.Center)

          // 模型列表
          if (this.modelList.length === 0) {
            Column() {
              Text('暂无模型')
                .fontColor(colors.gray)
                .padding(size.middleGap)
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            List() {
              ForEach(this.modelList, (item: ChatModelType, index: number) => {
                ListItem() {
                  this.modelItemBuilder(item, index)
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
        this.goToAddModel();
      })
  }
}

export default ModelManagePage;