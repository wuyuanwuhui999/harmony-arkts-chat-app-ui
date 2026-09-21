// ets/pages/ChatPage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import {
  ChatModelType,
  ChatType,
  GroupedByChatIdType,
  GroupedByTimeAgoType,
  ChatHistoryType,
  ChatParamsType,
  DocumentType,
  UserDataType,
  TenantType,
  DirectoryType,
  DirectoryDocType,
  CreateDirectoryParamsType,
  UploadFileType,
  UploadDocParamsType,
  SelectOptionType,
  MyAwesomeData,
  PromptInterface,
  GetPromptListParamsType,
  CompanyType
} from '../type/Index';
import {
  getModelListService,
  getChatHistoryService,
  deleteMyDocumentService,
  getDirectoryListService,
  getDocListByDirIdService,
  createDirectoryService,
  updateDocPermissionService,
  uploadDocService,
  getPromptListService,
  deletePromptService,
  getTenantListService
} from '../service/Index';
import { PositionEnum } from '../common/enum';
import AvaterComponent from "../components/AvaterComponent";
import { USER_DATA, COMPANY_DATA, PAGE_SIZE, HOST, PROMPT_ID, DOC_PERMISSION_OPTIONS, DOC_SPLIT_METHOD_OPTIONS, DEFAULT_CHUNK_SIZE } from '../common/constant';
import { formatTimeAgo, generateSecureID } from "../utils/common";
import { pickDocumentFile } from "../utils/FileUtil";
import { display, promptAction } from '@kit.ArkUI';
import webSocket from '@ohos.net.webSocket';
import { BusinessError } from '@kit.BasicServicesKit';
import api from '../api';
import preference from '../utils/PreferenceModel';
import OptionDialogComponent from '../components/OptionDialogComponent';
import DialogComponent from "../components/DialogComponent";
import BottomDialogComponent from "../components/BottomDialogComponent";
import MarkdownRenderer from "../components/MarkdownRenderer";

// 文档设置对话框的权限下拉选项（label 用于界面显示，value 提交给后端）
const PERMISSION_SELECT_OPTIONS: Array<SelectOption> = DOC_PERMISSION_OPTIONS.map((item: SelectOptionType): SelectOption => {
  return { value: item.label };
});
// 文档设置对话框的分割模式下拉选项
const SPLIT_METHOD_SELECT_OPTIONS: Array<SelectOption> = DOC_SPLIT_METHOD_OPTIONS.map((item: SelectOptionType): SelectOption => {
  return { value: item.label };
});

@Entry
export default struct ChatPage {
  @State modelList: Array<ChatModelType> = []
  @State activeModelName: string = "";
  @State chatId: string = "";
  @State loading: boolean = false;
  @State showMenu: boolean = false;
  @State pageNum: number = 1;
  @State total: number = 0;
  @State historyList: GroupedByTimeAgoType = {};
  @State token: string = "";
  @State showHistory: boolean = false;
  private scroller: Scroller = new Scroller()
  @State chatList: Array<ChatType> = [
    {
      responseContent: "你好，我是智能音乐助手小吴同学，请问有什么可以帮助您？",
      position: PositionEnum.LEFT,
    }
  ];
  @State thinkContent: string = "";
  @State responseContent: string = "";
  @State showThink: boolean = false;
  @State type: string = "";
  @State language: string = "zh";
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @State checkedDocIds: string[] = [];
  @State docDirList: Array<DirectoryDocType> = []; // 选择文档对话框的目录及目录下的文档列表
  @State uploadDirectoryId: string = ''; // 上传文档对话框选中的目录id
  @State newDirectoryName: string = ''; // 创建目录输入的名称
  private docDialogController: CustomDialogController | null = null;
  private createDirDialogController: CustomDialogController | null = null;
  private uploadDialogController: CustomDialogController | null = null;
  private snapshotCheckedDocIds: string[] = []; // 打开选择文档对话框时的已选文档快照
  @State permissionIndex: number = 0; // 文档权限下拉选中项，默认 private（私密）
  @State splitMethodIndex: number = 0; // 分割模式下拉选中项，默认 recursive（递归字符分割）
  @State chunkSize: string = `${DEFAULT_CHUNK_SIZE}`; // 分割大小，默认1000，仅固定长度分割使用
  @State selectedFileName: string = ''; // 待上传的文件名称
  private pendingUploadFile: UploadFileType | null = null; // 待上传的文件（文档设置确定后再上传）
  private docSettingDialogController: CustomDialogController | null = null;
  @State docPermissionIndex: number = 0; // 修改文档权限下拉选中项
  private currentDocId: string = ''; // 当前操作的文档id
  private currentDocDirectoryId: string = ''; // 当前文档所在的目录id
  private currentDocPermission: string = ''; // 打开修改权限对话框时该文档的权限（失败回滚用）
  private docPermissionOverrides: Map<string, string> = new Map<string, string>(); // 文档权限本地覆盖（修改成功后记录，目录文档列表重新拉取时也回显最新权限）
  private updatePermissionDialogController: CustomDialogController | null = null;
  private deleteDocDialogController: CustomDialogController | null = null;
  private message: string = "";
  private dialogController: CustomDialogController | null = null
  private ws: webSocket.WebSocket | null = null;
  @State userInputValue: string = ""
  @State tenantList: Array<TenantType> = []
  @State currentTenant: TenantType | null = null;
  @StorageLink(COMPANY_DATA) companyData: CompanyType | null = null;
  @StorageLink(PROMPT_ID) promptId: string = ''; // 当前正在使用的提示词id（ViewModel 全局状态）
  @State promptList: Array<PromptInterface> = []; // 提示词列表
  @State promptKeyword: string = ''; // 提示词搜索关键字
  @State promptHasMore: boolean = false; // 提示词是否还有下一页
  private promptPageNum: number = 1; // 提示词当前页码
  private promptPageSize: number = PAGE_SIZE; // 提示词每页条数
  private promptTotal: number = 0; // 提示词总条数
  private promptSearchTimer: number = 0; // 提示词搜索防抖定时器
  private promptDialogController: CustomDialogController | null = null;
  private promptDeleteDialogController: CustomDialogController | null = null;
  private myDocDialogController: CustomDialogController | null = null;
  private historyDialogController: CustomDialogController | null = null;

  @Styles
  blockStyle(){
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  async aboutToAppear() {
    const companyData = AppStorage.get<CompanyType>(COMPANY_DATA);
    const companyId = companyData?.id || '';

    // 1. 获取租户列表并设置当前租户
    try {
      const tenantListRes = await getTenantListService(companyId);

      if (tenantListRes.data && tenantListRes.data.length > 0) {
        this.tenantList = tenantListRes.data;

        const cachedTenantId = await preference.getPreference(`${this.userData.id}:tenantId`);

        let selectedTenant: TenantType | null = null;

        if (cachedTenantId) {
          selectedTenant = this.tenantList.find(item => item.id === cachedTenantId) || null;
        }

        if (!selectedTenant) {
          selectedTenant = this.tenantList[0];
        }

        if (selectedTenant) {
          this.currentTenant = selectedTenant;
          await preference.putPreference(`${this.userData.id}:tenantId`, selectedTenant.id);
        }
      }
    } catch (error) {
      console.error('[ChatPage] 获取租户列表失败:', JSON.stringify(error));
    }

    // 6. 获取模型列表 - 传入 companyId
    getModelListService(companyId).then(async (res) => {
      if (res.data && res.data.length > 0) {
        this.modelList = res.data;
        this.activeModelName = res.data[0].modelName;

        // ===== 新增：保存默认模型ID到缓存 =====
        const defaultModel = res.data[0];
        if (defaultModel?.id) {
          await preference.putPreference(`${companyId}:currentModelId`, defaultModel.id);
          console.log('[ChatPage] 初始化保存默认模型ID:', defaultModel.id);
        }
        // ===== 新增结束 =====
      }
    }).catch((err: Error) => {
      console.error('[ChatPage] 获取模型列表失败:', JSON.stringify(err));
    });

    // 7. 在租户信息加载完成后恢复当前租户正在使用的提示词id
    await this.restorePromptId();
  }

  aboutToDisappear() {
    this.ws?.close();
  }

  onSend = async () => {
    if (this.userInputValue.trim() === "") {
      promptAction.showToast({
        message: "请输入要问的问题",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      })
    } else {
      if (!this.ws) {
        await this.connectWebSocket();
      }
      this.chatId = this.chatId || generateSecureID();
      const payload: ChatParamsType = {
        modelName: this.activeModelName,
        chatId: this.chatId, // 替换为实际聊天ID
        prompt: this.userInputValue.trim(),
        promptId: this.promptId,// 正在使用的提示词id
        type:this.type,
        docIds:this.type === "document" ? this.checkedDocIds : [],
        showThink:this.showThink,
        language: this.language // 如果需要上传文件，请根据实际情况调整
      };
      this.chatList.push({
        text: this.userInputValue.trim(),
        position: PositionEnum.RIGHT,
      });

      this.userInputValue = "";
      this.ws?.send(JSON.stringify(payload), () => {
        this.loading = true;
        console.log("发送消息成功")
      })
    }
  }

  connectWebSocket(): Promise<string> {
    return new Promise(async (resolve, reject) => {
      if (!this.token) {
        this.token = await preference.getToken() as string;
      }
      const url = `ws://${HOST.replace(/http[s]?:\/\//, "")}${api.chatWs}?token=${this.token}`; // 替换为实际API地址
      this.ws = webSocket.createWebSocket();
      // 设置事件监听
      this.ws.on('open', () => {
        resolve('')
      });
      this.ws.on('message', (error: BusinessError, data: string | ArrayBuffer) => {
        if (data !== "[completed]") {
          this.message += data;
          // 使用正则提取内容
          if (/^<think>/.test(this.message) && /<\/think>/.test(this.message) && !/<\/think>/.test(data.toString())) {
            this.responseContent += data;
          } else {
            this.thinkContent += data;
          }
        } else { //对话已完成
          this.message = "";
          this.loading = false;
          this.chatList.push({
            responseContent: this.responseContent,
            thinkContent: this.thinkContent,
            position: PositionEnum.LEFT,
          });
          this.thinkContent = this.responseContent = "";
        }
        this.scroller.scrollEdge(Edge.Bottom)
      });
      this.ws.on('close', () => {
        this.ws = null
        console.log('连接关闭')
      });
      this.ws.on('error', (err: Error) => {
        this.ws = null
        console.error('错误:', JSON.stringify(err))
      });
      // 发起连接
      this.ws.connect(url);
    });
  }

  /**
   * @author: system
   * @description: 切换租户
   * @date: 2026-06-26
   */
  switchTenant = async (tenant: TenantType): Promise<void> => {
    // 设置当前租户
    this.currentTenant = tenant;

    // 保存租户ID到缓存
    await preference.putPreference(`${this.userData.id}:tenantId`, tenant.id);

    // 获取公司ID，刷新模型列表
    const companyData = AppStorage.get<CompanyType>(COMPANY_DATA);
    const companyId = companyData?.id || '';
    this.refreshModelList(companyId);

    // 切换租户后重新恢复该租户下正在使用的提示词id
    await this.restorePromptId();
  }

  /**
   * @author: wuwenqiang
   * @description: 我的文档对话框内容构建器（样式与选择文档对话框相同，没有复选框和确定/取消按钮）
   * @date: 2026-09-19
   */
  @Builder
  myDocumentBuilder() {
    Column() {
      // 标题栏：左边刷新图标、中间标题、右边创建目录图标和上传图标
      Row() {
        Image($r("app.media.icon_refresh"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 重新加载文档目录
            this.loadDocDirectoryList();
          })
          .margin({ left: size.middleGap })
        Text('我的文档')
          .fontSize(size.middleFont)
          .fontWeight(FontWeight.Medium)
          .padding(size.middleGap)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_create_directory"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 创建目录
            this.showCreateDirDialog();
          })
        Image($r("app.media.icon_upload"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 上传文档
            this.showUploadDialog();
          })
          .margin({ left: size.middleGap, right: size.middleGap })
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })

      // 灰色背景内容区
      Column({ space: size.middleGap }) {
        // 目录列表卡片
        if (this.docDirList.length === 0) {
          Column() {
            Text('暂无目录')
              .fontColor(colors.gray)
              .padding(size.middleGap)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
        } else {
          List() {
            ForEach(this.docDirList, (directory: DirectoryDocType, index: number) => {
              ListItem() {
                Column() {
                  // 目录条目：目录名称 + 名称右边的展开箭头
                  Row() {
                    Text(directory.directoryName)
                      .fontSize(size.middleFont)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Image($r("app.media.icon_arrow"))
                      .width(size.smallIcon)
                      .height(size.smallIcon)
                      .opacity(size.opacity)
                      // 展开时向右的箭头顺时针旋转90度方向向下
                      .rotate({ angle: directory.expanded ? 90 : 0 })
                  }
                  .width('100%')
                  .padding(size.middleGap)
                  .onClick(() => {
                    // 点击目录名称才加载该目录下的文档列表，再次点击则收起
                    this.toggleDirectory(index);
                  })

                  // 目录下的文档列表
                  if (directory.expanded) {
                    if (directory.docList.length === 0) {
                      Text('暂无文档')
                        .fontSize(size.middleFont)
                        .fontColor(colors.gray)
                        .padding({
                          left: size.middleGap,
                          right: size.middleGap,
                          top: size.smallGap,
                          bottom: size.smallGap
                        })
                    } else {
                      ForEach(directory.docList, (doc: DocumentType) => {
                        Row() {
                          Text(doc.name)
                            .fontSize(size.middleFont)
                            .maxLines(2)
                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                            .layoutWeight(1)
                          // 文档操作图标（三个点）：修改权限、删除
                          this.docMoreActionBuilder(doc, directory.directoryId)
                        }
                        .width('100%')
                        .padding({
                          left: size.middleGap,
                          right: size.middleGap,
                          top: size.smallGap,
                          bottom: size.smallGap
                        })
                      }, (doc: DocumentType) => `${doc.id}_${doc.permission}`)
                    }
                  }
                }
                .width('100%')
                // 每个目录用一条灰色横线隔开
                .border({
                  width: { bottom: index === this.docDirList.length - 1 ? 0 : 1 },
                  color: { bottom: colors.borderColor },
                  style: { bottom: BorderStyle.Solid }
                })
              }
            }, (directory: DirectoryDocType) => `${directory.directoryId}_${directory.expanded}_${directory.docList.length}`)
          }
          .width('100%')
          // 目录列表卡片高度自适应内容，最多占满内容区
          .constraintSize({ maxHeight: '100%' })
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
        }
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(colors.pageBackground)
      .padding(size.middleGap)
    }
    .height("100%")
    .width('100%')
    .backgroundColor(colors.white)
    .borderRadius({ topLeft: size.middleBorderRaduis, topRight: size.middleBorderRaduis })
  }

  /**
   * @author: wuwenqiang
   * @description: 显示提示词对话框（复用查询文档的底部弹窗组件）
   * @date: 2026-09-19
   */
  showPromptListDialog = () => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 每次打开对话框都重置搜索条件并重新加载第一页
    this.promptKeyword = '';
    this.loadPromptList(true);

    this.promptDialogController = new CustomDialogController({
      customStyle: true,
      builder: BottomDialogComponent({
        dialogHeight: '80%',
        builder: this.promptListDialogBuilder.bind(this)
      }),
      alignment: DialogAlignment.Bottom,
    })
    this.promptDialogController.open()
  }

  /**
   * @author: wuwenqiang
   * @description: 分页加载提示词列表
   * @param isRefresh true-从第一页重新加载；false-向上滚动到底部时追加下一页
   * @date: 2026-09-19
   */
  loadPromptList = (isRefresh: boolean): void => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      console.warn('[ChatPage] 获取提示词列表失败：租户ID为空');
      return;
    }

    // 重新加载时回到第一页
    if (isRefresh) {
      this.promptPageNum = 1;
      this.promptTotal = 0;
    }

    const params: GetPromptListParamsType = {
      tenantId: tenantId,
      keyword: this.promptKeyword.trim(),
      pageSize: this.promptPageSize,
      pageNum: this.promptPageNum
    };

    getPromptListService(params).then((res) => {
      const list: PromptInterface[] = res.data || [];
      this.promptList = isRefresh ? list : this.promptList.concat(list);
      this.promptTotal = res.total > 0 ? res.total : 0;
      // 总条数有效时按总条数判断，否则按本次返回的条数判断是否还有下一页
      if (this.promptTotal > 0) {
        this.promptHasMore = this.promptList.length < this.promptTotal;
      } else {
        this.promptHasMore = list.length >= this.promptPageSize;
      }
    }).catch((err: Error) => {
      console.error('[ChatPage] 获取提示词列表失败:', JSON.stringify(err));
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 向上滚动到底部时加载下一页提示词
   * @date: 2026-09-19
   */
  loadMorePromptList = (): void => {
    if (!this.promptHasMore) {
      return;
    }
    this.promptPageNum++;
    this.loadPromptList(false);
  }

  /**
   * @author: wuwenqiang
   * @description: 搜索关键字变化时实时加载提示词列表（防抖300ms）
   * @date: 2026-09-19
   */
  onPromptKeywordChange = (value: string): void => {
    this.promptKeyword = value;
    if (this.promptSearchTimer) {
      clearTimeout(this.promptSearchTimer);
      this.promptSearchTimer = 0;
    }
    this.promptSearchTimer = setTimeout(() => {
      this.loadPromptList(true);
    }, 300);
  }

  /**
   * @author: wuwenqiang
   * @description: 清空搜索关键字并重新加载提示词列表
   * @date: 2026-09-19
   */
  clearPromptKeyword = (): void => {
    this.promptKeyword = '';
    this.loadPromptList(true);
  }

  /**
   * @author: wuwenqiang
   * @description: 跳转到添加提示词页面
   * @date: 2026-09-19
   */
  goToAddPromptPage = (): void => {
    router.pushUrl({
      url: 'pages/AddPromptPage',
      params: {
        tenantId: this.currentTenant?.id
      }
    });
  }

  /**
   * @author: wuwenqiang
   * @description: 跳转到更新提示词页面，把提示词对象直接传递到目标页面
   * @date: 2026-09-19
   */
  goToUpdatePromptPage = (item: PromptInterface): void => {
    router.pushUrl({
      url: 'pages/UpdatePromptPage',
      params: {
        prompt: item
      }
    });
  }

  /**
   * @author: wuwenqiang
   * @description: 使用/取消使用提示词，把提示词id保存到ViewModel中
   * @date: 2026-09-19
   */
  toggleUsePrompt = async (item: PromptInterface): Promise<void> => {
    const isUsing: boolean = this.promptId === item.id;
    this.promptId = isUsing ? '' : item.id;
    await this.savePromptIdToCache();
    promptAction.showToast({
      message: isUsing ? '已取消使用该提示词' : '已选择该提示词',
      duration: 2000,
      bottom: px2vp(display.getDefaultDisplaySync().height) / 2
    });
  }

  /**
   * @author: wuwenqiang
   * @description: 删除提示词确认弹窗
   * @date: 2026-09-19
   */
  confirmDeletePrompt = (item: PromptInterface): void => {
    this.promptDeleteDialogController = new CustomDialogController({
      customStyle: false,
      builder: DialogComponent({
        title: '是否删除该提示词？',
        cancel: (): void => {
          this.promptDeleteDialogController?.close();
        },
        confirm: (): void => {
          this.doDeletePrompt(item);
        }
      }),
      alignment: DialogAlignment.Center,
    })
    this.promptDeleteDialogController.open()
  }

  /**
   * @author: wuwenqiang
   * @description: 删除提示词，删除成功后从提示词列表中移除该条提示词
   * @date: 2026-09-19
   */
  doDeletePrompt = (item: PromptInterface): void => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      return;
    }
    deletePromptService(item.id, tenantId).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '删除成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 从提示词列表中移除该条提示词
        const index: number = this.promptList.findIndex((aItem: PromptInterface) => aItem.id === item.id);
        if (index > -1) {
          this.promptList.splice(index, 1);
        }
        // 删除的是正在使用的提示词时，需要清空ViewModel中保存的提示词id
        if (this.promptId === item.id) {
          this.promptId = '';
          this.savePromptIdToCache();
        }
      } else {
        promptAction.showToast({
          message: res.msg || '删除失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
      this.promptDeleteDialogController?.close();
    }).catch((err: Error) => {
      console.error('[ChatPage] 删除提示词失败:', JSON.stringify(err));
      this.promptDeleteDialogController?.close();
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 提示词对话框内容构建器
   * @date: 2026-09-19
   */
  @Builder
  promptListDialogBuilder() {
    Column() {
      // 标题栏：左边刷新图标、中间标题、右边加号图标
      Row() {
        Image($r("app.media.icon_refresh"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 重新加载提示词列表
            this.loadPromptList(true);
          })
          .margin({ left: size.middleGap })
        Text('提示词')
          .fontSize(size.middleFont)
          .fontWeight(FontWeight.Medium)
          .padding(size.middleGap)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_add"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 跳转到添加提示词页面
            this.goToAddPromptPage();
          })
          .margin({ right: size.middleGap })
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })

      // 灰色背景内容区
      Column({ space: size.middleGap }) {
        // 提示词搜索框
        Row() {
          TextInput({
            placeholder: '请输入关键字搜索',
            text: this.promptKeyword
          })
            .height(size.inputHeight)
            .layoutWeight(1)
            .backgroundColor(Color.Transparent)
            .onChange((value: string) => {
              this.onPromptKeywordChange(value);
            })
            .onSubmit(() => {
              this.loadPromptList(true);
            })

          if (this.promptKeyword) {
            Image($r('app.media.icon_clear'))
              .width(size.smallIcon)
              .height(size.smallIcon)
              .margin({ left: size.smallGap })
              .onClick(() => {
                this.clearPromptKeyword();
              })
          }

          Image($r('app.media.icon_search'))
            .width(size.smallIcon)
            .height(size.smallIcon)
            .margin({ left: size.smallGap, right: size.middleGap })
            .onClick(() => {
              this.loadPromptList(true);
            })
        }
        .backgroundColor(colors.white)
        .borderRadius(size.inputHeight / 2)
        .width('100%')
        .padding({ left: size.middleGap })
        .alignItems(VerticalAlign.Center)

        // 提示词列表卡片
        if (this.promptList.length === 0) {
          Column() {
            Text('暂无提示词')
              .fontColor(colors.gray)
              .padding(size.middleGap)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
        } else {
          List() {
            ForEach(this.promptList, (item: PromptInterface, index: number) => {
              ListItem() {
                this.promptItemBuilder(item, index)
              }
              .swipeAction({
                end: () => {
                  return this.promptSwipeActionBuilder(item)
                }
              })
            }, (item: PromptInterface) => `${item.id}_${this.promptId === item.id}`)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
          .onReachEnd(() => {
            // 向上滚动到底部时加载下一页
            this.loadMorePromptList();
          })
        }

        // 取消/确定按钮
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
              // 取消：清空ViewModel中保存的提示词id，提示词按钮恢复灰色
              this.promptId = '';
              this.savePromptIdToCache();
              this.promptDialogController?.close();
            })

          Text('确定')
            .width('45%')
            .height(size.btnHeight)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .backgroundColor(this.promptId ? colors.primary : colors.gray)
            .borderRadius(size.btnHeight / 2)
            .enabled(!!this.promptId)
            .onClick(() => {
              // 已经使用了一条提示词才能确定，确定后提示词按钮变成激活状态
              if (this.promptId) {
                this.savePromptIdToCache();
                this.promptDialogController?.close();
              }
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(colors.pageBackground)
      .padding(size.middleGap)
    }
    .height("100%")
    .width('100%')
    .backgroundColor(colors.white)
    .borderRadius({ topLeft: size.middleBorderRaduis, topRight: size.middleBorderRaduis })
  }

  /**
   * @author: wuwenqiang
   * @description: 提示词条目构建器，最多显示三行，超出显示省略号
   * @date: 2026-09-19
   */
  @Builder
  promptItemBuilder(item: PromptInterface, index: number) {
    Column() {
      Text(item.prompt)
        .fontSize(size.middleFont)
        .fontColor(this.promptId === item.id ? colors.primary : colors.black)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(size.middleGap)
    .border({
      width: { bottom: index === this.promptList.length - 1 ? 0 : 1 },
      color: { bottom: colors.borderColor },
      style: { bottom: BorderStyle.Solid }
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 提示词条目向左滑动弹出的删除、编辑、使用按钮
   * @date: 2026-09-19
   */
  @Builder
  promptSwipeActionBuilder(item: PromptInterface) {
    Row() {
      // 使用/取消使用按钮
      Column() {
        Text(this.promptId === item.id ? '取消使用' : '使用')
          .fontColor(Color.White)
          .fontSize(size.middleFont)
      }
      .justifyContent(FlexAlign.Center)
      .width(size.btnHeight * 2)
      .height('100%')
      .backgroundColor(this.promptId === item.id ? colors.gray : colors.primary)
      .onClick(() => {
        this.toggleUsePrompt(item);
      })

      // 编辑按钮
      Column() {
        Text('编辑')
          .fontColor(Color.White)
          .fontSize(size.middleFont)
      }
      .justifyContent(FlexAlign.Center)
      .width(size.btnHeight * 2)
      .height('100%')
      .backgroundColor(colors.gray)
      .onClick(() => {
        this.goToUpdatePromptPage(item);
      })

      // 删除按钮
      Column() {
        Text('删除')
          .fontColor(Color.White)
          .fontSize(size.middleFont)
      }
      .justifyContent(FlexAlign.Center)
      .width(size.btnHeight * 2)
      .height('100%')
      .backgroundColor(colors.warn)
      .onClick(() => {
        this.confirmDeletePrompt(item);
      })
    }
  }

  /**
   * @author: wuwenqiang
   * @description: 显示我的文档对话框（先获取文档目录，点击目录才加载该目录下的文档列表）
   * @date: 2026-09-19
   */
  showMyDocumentDialog = () => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 先获取文档目录
    this.loadDocDirectoryList();

    // 打开对话框
    this.myDocDialogController = new CustomDialogController({
      customStyle: true,
      builder: BottomDialogComponent({
        dialogHeight: '80%',
        builder: this.myDocumentBuilder.bind(this)
      }),
      alignment: DialogAlignment.Bottom,
    })
    this.myDocDialogController.open()
  }

  // popup构造器定义弹框内容
  @Builder
  popupBuilder() {
    Column() {
      Text("提示词管理").height(size.btnHeight).onClick(() => {
        this.showMenu = false;
        // 跳转到提示词管理页面
        router.pushUrl({
          url: 'pages/PromptManagePage',
          params: {
            tenantId: this.currentTenant?.id,
            tenantName: this.currentTenant?.name
          }
        });
      })
      Divider().height(1).color(colors.borderColor)
      if ((this.companyData?.role ?? 0) > 0) {
        Text("模型管理").height(size.btnHeight).onClick(() => {
          this.showMenu = false;
          router.pushUrl({
            url: 'pages/ModelManagePage'
          });
        })
        Divider().height(1).color(colors.borderColor)
      }
      // ===== 新增结束 =====
      Text("我的文档").height(size.btnHeight).onClick(()=>{
        this.showMenu = false;
        this.showMyDocumentDialog();
      })
      Divider().height(1).color(colors.borderColor)
      Text("历史记录").height(size.btnHeight).onClick(()=>{
        this.showMenu = false;
        this.showHistoryDialog();
      })
      Divider().height(1).color(colors.borderColor)
      Text("切换模型").height(size.btnHeight).onClick(this.onTabModel)
    }
    .width(size.popupMenuWidth)
  }

  /**
   * @author: system
   * @description: 显示历史记录对话框
   * @date: 2026-04-28
   */
  showHistoryDialog = () => {
    // 清空并重新加载历史记录数据
    this.historyList = {};
    this.pageNum = 1;
    this.loadHistoryData();

    // 打开对话框
    this.historyDialogController = new CustomDialogController({
      customStyle: true,
      builder: BottomDialogComponent({
        dialogHeight: '80%',
        builder: this.historyDialogBuilder.bind(this)
      }),
      alignment: DialogAlignment.Bottom,
    })
    this.historyDialogController.open()
  }

  /**
   * @author: system
   * @description: 加载历史记录数据
   * @date: 2026-04-28
   */
  loadHistoryData = () => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      console.warn('[ChatPage] 加载历史记录失败：租户ID为空');
      return;
    }

    getChatHistoryService(tenantId, this.pageNum, PAGE_SIZE).then((res) => {
      this.total = res.total
      const result: GroupedByChatIdType = {}
      res.data.forEach((aItem) => {
        aItem.timeAgo = formatTimeAgo(aItem.createTime);
        if (!result[aItem.chatId]) {
          result[aItem.chatId] = [];
        }
        result[aItem.chatId].push(aItem);
      });

      const keys: string[] = Object.keys(result);
      keys.forEach((key) => {
        const timeAgo = result[key][0].timeAgo;
        if (!this.historyList[timeAgo]) {
          this.historyList[timeAgo] = [];
        }
        this.historyList[timeAgo].push(result[key])
      });
    })
  }

  /**
   * @author: system
   * @description: 加载更多历史记录
   * @date: 2026-04-28
   */
  loadMoreHistory = () => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      console.warn('[ChatPage] 加载更多历史记录失败：租户ID为空');
      return;
    }

    if (this.total > this.pageNum * PAGE_SIZE) {
      this.pageNum++;
      getChatHistoryService(tenantId, this.pageNum, PAGE_SIZE).then((res) => {
        const result: GroupedByChatIdType = {}
        res.data.forEach((aItem) => {
          aItem.timeAgo = formatTimeAgo(aItem.createTime);
          if (!result[aItem.chatId]) {
            result[aItem.chatId] = [];
          }
          result[aItem.chatId].push(aItem);
        });

        const keys: string[] = Object.keys(result);
        keys.forEach((key) => {
          const timeAgo = result[key][0].timeAgo;
          if (!this.historyList[timeAgo]) {
            this.historyList[timeAgo] = [];
          }
          this.historyList[timeAgo].push(result[key])
        });
      })
    }
  }

  /**
   * @author: system
   * @description: 历史记录对话框内容构建器
   * @date: 2026-04-28
   */
  @Builder
  historyDialogBuilder() {
    Column() {
      // 标题栏
      Row() {
        Blank().width(size.smallIcon).height(size.smallIcon)
        Text('历史记录')
          .fontSize(size.middleFont)
          .fontWeight(FontWeight.Medium)
          .padding(size.middleGap)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_close"))
          .width(size.middleFont)
          .height(size.middleFont)
          .opacity(0.5)
          .onClick(() => {
            this.historyDialogController?.close()
          })
          .margin({ right: size.middleGap })
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })

      // 历史记录内容区
      Scroll() {
        Column({ space: size.middleGap }) {
          ForEach(Object.keys(this.historyList), (key: string) => {
            Column({ space: size.miniGap }) {
              Text(key).fontColor(colors.gray)
              ForEach(this.historyList[key], (items: ChatHistoryType[]) => {
                Column() {
                  Text(items[0].prompt)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .padding({
                      top: size.smallGap,
                      bottom: size.smallGap,
                      left: size.smallGap,
                      right: size.smallGap
                    })
                    .onClick(() => {
                      // 关闭对话框
                      this.historyDialogController?.close();
                      // 清空当前聊天列表
                      this.chatList.length = 0;
                      // 设置当前聊天ID
                      this.chatId = items[0].chatId;
                      // 加载历史聊天记录
                      items.forEach((item) => {
                        this.chatList.push({
                          text: item.prompt,
                          position: PositionEnum.RIGHT
                        }, {
                          thinkContent: item.thinkContent,
                          responseContent: item.responseContent,
                          position: PositionEnum.LEFT
                        })
                      })
                    })
                }
                .width('100%')
                .backgroundColor(colors.white)
                .borderRadius(size.smallBorderRaduis)
                .margin({ bottom: size.smallGap })
              })
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
          })
        }
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.Start)
        .padding(size.middleGap)
        .width('100%')
      }
      .layoutWeight(1)
      .scrollable(ScrollDirection.Vertical)
      .onScrollEdge((side: Edge) => {
        if (side === Edge.Bottom) {
          this.loadMoreHistory();
        }
      })
      .backgroundColor(colors.pageBackground)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.white)
    .borderRadius({ topLeft: size.middleBorderRaduis, topRight: size.middleBorderRaduis })
  }

  onTabModel=()=>{
    this.dialogController = new CustomDialogController({
      customStyle: true,
      builder: OptionDialogComponent({
        cancel: (): void => this.onModelDialogCancel(),
        confirm: (value: string, index: number):Promise<void> => this.onModelConfirm(value),
        options: this.modelList.map((item) => item.modelName),
      }),
      alignment: DialogAlignment.Bottom,
    });
    this.dialogController.open();
  }

  /**
   * @author: system
   * @description: 模型对话框取消
   * @date: 2026-04-29
   */
  onModelDialogCancel = () => {
    this.dialogController?.close();
  }

  /**
   * @author: wuwenqiang
   * @description: 确认切换模型
   * @date: 2026-04-29
   */
  onModelConfirm = async (value: string) => {
    this.activeModelName = value;
    this.dialogController?.close();

    // 查找选中模型的ID并保存到缓存
    const selectedModel = this.modelList.find(item => item.modelName === value);
    if (selectedModel && this.companyData?.id) {
      await preference.putPreference(`${this.companyData.id}:currentModelId`, selectedModel.id);
      console.log('[ChatPage] 保存当前模型ID:', selectedModel.id);
    }
  }

  /**
   * @author: wuwenqiang
   * @description: 从缓存恢复当前租户正在使用的提示词id（ViewModel 初始化）
   * @date: 2026-09-19
   */
  restorePromptId = async (): Promise<void> => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId || !this.userData.id) {
      this.promptId = '';
      return;
    }
    // 读取缓存中该用户在该租户下正在使用的提示词id
    const cachedPromptId = await preference.getPreference(`${this.userData.id}:${tenantId}:promptId`) || '';
    this.promptId = cachedPromptId;
  }

  /**
   * @author: wuwenqiang
   * @description: 把ViewModel中正在使用的提示词id同步到缓存
   * @date: 2026-09-19
   */
  savePromptIdToCache = async (): Promise<void> => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId || !this.userData.id) {
      return;
    }
    await preference.putPreference(`${this.userData.id}:${tenantId}:promptId`, this.promptId);
  }

  /**
   * @author: wuwenqiang
   * @description: 文档操作图标（三个点），点击弹出修改权限和删除选项
   * @date: 2026-09-19
   */
  @Builder
  docMoreActionBuilder(doc: DocumentType, directoryId: string) {
    Row({ space: size.miniGap }) {
      Circle({ width: size.miniGap, height: size.miniGap })
        .fill(colors.gray)
      Circle({ width: size.miniGap, height: size.miniGap })
        .fill(colors.gray)
      Circle({ width: size.miniGap, height: size.miniGap })
        .fill(colors.gray)
    }
    .width(size.middleIcon)
    .height(size.middleIcon)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .bindMenu([
      {
        value: '修改权限',
        action: () => {
          this.showUpdateDocPermissionDialog(doc, directoryId);
        }
      },
      {
        value: '删除',
        action: () => {
          this.confirmDeleteDoc(doc, directoryId);
        }
      }
    ])
  }

  /**
   * @author: wuwenqiang
   * @description: 显示修改文档权限对话框，权限下拉框默认回显该文档当前的权限
   * @date: 2026-09-19
   */
  showUpdateDocPermissionDialog = (doc: DocumentType, directoryId: string): void => {
    this.currentDocId = doc.id;
    this.currentDocDirectoryId = directoryId;
    // 本地覆盖的权限优先（接口成功后记录），否则用文档条目中的 permission 字段回显
    const currentPermission: string = this.docPermissionOverrides.get(doc.id) || (doc.permission ? doc.permission : '');
    // 记录该文档当前的权限，接口失败时用于回滚
    this.currentDocPermission = currentPermission;
    const permissionIndex: number = DOC_PERMISSION_OPTIONS.findIndex((item: SelectOptionType) => item.value === currentPermission);
    this.docPermissionIndex = permissionIndex > -1 ? permissionIndex : 0;
    this.updatePermissionDialogController = new CustomDialogController({
      customStyle: true,
      builder: this.updatePermissionDialogBuilder.bind(this),
      alignment: DialogAlignment.Center,
    })
    this.updatePermissionDialogController.open()
  }

  /**
   * @author: wuwenqiang
   * @description: 修改权限对话框点击确定：先同步关闭对话框并本地回显最新权限，再调用接口，失败时回滚
   * @date: 2026-09-19
   */
  confirmUpdateDocPermission = (): void => {
    const docId: string = this.currentDocId;
    const directoryId: string = this.currentDocDirectoryId;
    const permission: string = DOC_PERMISSION_OPTIONS[this.docPermissionIndex].value;
    const oldPermission: string = this.currentDocPermission;

    // 1.在点击事件里同步关闭对话框（在接口回调里关闭可能不生效，导致对话框关不掉）
    this.updatePermissionDialogController?.close();
    this.updatePermissionDialogController = null;

    // 2.先按所选权限更新列表，保证再次打开修改权限对话框时回显的是最新权限
    this.applyDocPermission(docId, directoryId, permission);

    // 3.调用修改接口，成功/失败都提示后端返回的 msg
    updateDocPermissionService(docId, permission).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: res.msg || '修改成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      } else {
        // 接口返回失败时提示后端 msg 并回滚本地权限
        promptAction.showToast({
          message: res.msg || '修改失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        this.applyDocPermission(docId, directoryId, oldPermission);
      }
    }).catch((err: MyAwesomeData<number>) => {
      // status 不为 SUCCESS 时 httpRequest 会 reject 并已提示后端 msg，
      // 只有明确拿到“失败”的 data（非空且不大于0）时才回滚，避免后端返回体差异把成功的修改误判为失败
      if (err && err.data !== undefined && err.data !== null && !(err.data > 0)) {
        console.error('[ChatPage] 修改文档权限失败:', JSON.stringify(err));
        this.applyDocPermission(docId, directoryId, oldPermission);
      } else {
        console.warn('[ChatPage] 修改文档权限未拿到明确的失败结果，保留本地已选权限:', JSON.stringify(err));
      }
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 应用文档权限：记录本地权限覆盖并同步到文档列表，保证列表重新拉取后回显的仍是最新权限
   * @date: 2026-09-19
   */
  applyDocPermission = (docId: string, directoryId: string, permission: string): void => {
    // 记录/清除本地覆盖，接口重新拉取目录下文档列表时以它为准
    if (permission) {
      this.docPermissionOverrides.set(docId, permission);
    } else {
      this.docPermissionOverrides.delete(docId);
    }
    const directoryIndex: number = this.docDirList.findIndex((item: DirectoryDocType) => item.directoryId === directoryId);
    if (directoryIndex < 0) {
      return;
    }
    const directory: DirectoryDocType = this.docDirList[directoryIndex];
    const docIndex: number = directory.docList.findIndex((item: DocumentType) => item.id === docId);
    if (docIndex < 0) {
      return;
    }
    // ArkUI 只观察 @State 的第一层，修改字段后需要替换数组元素才能触发列表刷新
    directory.docList[docIndex].permission = permission;
    const updatedDirectory: DirectoryDocType = {
      directoryId: directory.directoryId,
      directoryName: directory.directoryName,
      expanded: directory.expanded,
      docList: directory.docList.slice()
    };
    this.docDirList.splice(directoryIndex, 1, updatedDirectory);
  }

  /**
   * @author: wuwenqiang
   * @description: 删除文档确认弹窗
   * @date: 2026-09-19
   */
  confirmDeleteDoc = (doc: DocumentType, directoryId: string): void => {
    this.currentDocId = doc.id;
    this.currentDocDirectoryId = directoryId;
    this.deleteDocDialogController = new CustomDialogController({
      customStyle: false,
      builder: DialogComponent({
        title: '是否确认删除',
        cancel: (): void => {
          this.deleteDocDialogController?.close();
        },
        confirm: (): void => {
          this.doDeleteDoc();
        }
      }),
      alignment: DialogAlignment.Center,
    })
    this.deleteDocDialogController.open()
  }

  /**
   * @author: wuwenqiang
   * @description: 删除文档，并从当前目录的文档列表中移除
   * @date: 2026-09-19
   */
  doDeleteDoc = (): void => {
    deleteMyDocumentService(this.currentDocId).then((res) => {
      if (res.data > 0) {
        // 成功提示后端返回的 msg
        promptAction.showToast({
          message: res.msg || '删除成功',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 从所属目录的文档列表中移除该条文档
        const directoryIndex: number = this.docDirList.findIndex((item: DirectoryDocType) => item.directoryId === this.currentDocDirectoryId);
        if (directoryIndex > -1) {
          const directory: DirectoryDocType = this.docDirList[directoryIndex];
          const removedDirectory: DirectoryDocType = {
            directoryId: directory.directoryId,
            directoryName: directory.directoryName,
            expanded: directory.expanded,
            docList: directory.docList.filter((item: DocumentType) => item.id !== this.currentDocId)
          };
          this.docDirList.splice(directoryIndex, 1, removedDirectory);
        }
        // 被删除的文档如果已被勾选，同步清理勾选状态
        this.checkedDocIds = this.checkedDocIds.filter((item: string) => item !== this.currentDocId);
      } else {
        promptAction.showToast({
          message: res.msg || '删除失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
      this.deleteDocDialogController?.close();
    }).catch((err: Error) => {
      // 失败时后端返回的 msg 由 httpRequest 统一提示
      console.error('[ChatPage] 删除文档失败:', JSON.stringify(err));
      this.deleteDocDialogController?.close();
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 修改文档权限对话框内容构建器
   * @date: 2026-09-19
   */
  @Builder
  updatePermissionDialogBuilder() {
    Column({ space: size.middleGap }) {
      Text('修改权限')
        .fontSize(size.bigFont)
        .fontWeight(FontWeight.Medium)
        .margin({ top: size.middleGap })

      // 文档权限下拉框，选项来自 DOC_PERMISSION_OPTIONS
      Row({ space: size.smallGap }) {
        Text('权限')
          .fontSize(size.middleFont)
          .width('25%')
        Select(PERMISSION_SELECT_OPTIONS)
          .selected(this.docPermissionIndex)
          .value(DOC_PERMISSION_OPTIONS[this.docPermissionIndex].label)
          .font({ size: size.middleFont })
          .optionFont({ size: size.middleFont })
          .layoutWeight(1)
          .onSelect((index: number) => {
            this.docPermissionIndex = index;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 取消/确定按钮
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
            this.updatePermissionDialogController?.close();
          })

        Text('确定')
          .width('45%')
          .height(size.btnHeight)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .backgroundColor(colors.primary)
          .borderRadius(size.btnHeight / 2)
          .onClick(() => {
            this.confirmUpdateDocPermission();
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
   * @author: wuwenqiang
   * @description: 显示选择文档对话框
   * @date: 2026-09-19
   */
  showDocSelectDialog = () => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 记录进入对话框时的已选文档，取消时回滚
    this.snapshotCheckedDocIds = this.checkedDocIds.slice();
    // 重新加载文档目录
    this.loadDocDirectoryList();

    this.docDialogController = new CustomDialogController({
      customStyle: true,
      builder: BottomDialogComponent({
        dialogHeight: '80%',
        builder: this.docSelectDialogBuilder.bind(this)
      }),
      alignment: DialogAlignment.Bottom,
    })
    this.docDialogController.open()
  }

  /**
   * @author: wuwenqiang
   * @description: 加载文档目录列表，目录默认全部收起
   * @date: 2026-09-19
   */
  loadDocDirectoryList = (): void => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      console.warn('[ChatPage] 获取目录列表失败：租户ID为空');
      return;
    }
    getDirectoryListService(tenantId).then((res) => {
      const directoryList: DirectoryType[] = res.data || [];
      this.docDirList = directoryList.map((item: DirectoryType): DirectoryDocType => {
        return {
          directoryId: item.id || '',
          directoryName: item.directory,
          expanded: false,
          docList: []
        };
      });
    }).catch((err: Error) => {
      console.error('[ChatPage] 获取目录列表失败:', JSON.stringify(err));
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 获取指定目录下的文档列表，并展开该目录
   * @date: 2026-09-19
   */
  loadDirectoryDocList = (index: number): void => {
    const tenantId = this.currentTenant?.id;
    const directory = this.docDirList[index];
    if (!tenantId || !directory) {
      return;
    }
    getDocListByDirIdService(tenantId, directory.directoryId).then((res) => {
      const docList: DocumentType[] = res.data || [];
      // 回显已经勾选过的文档，并用本地权限覆盖修正回显的权限
      docList.forEach((item: DocumentType) => {
        item.checked = this.checkedDocIds.includes(item.id);
        const permission: string | undefined = this.docPermissionOverrides.get(item.id);
        if (permission) {
          item.permission = permission;
        }
      });
      const expandedDirectory: DirectoryDocType = {
        directoryId: directory.directoryId,
        directoryName: directory.directoryName,
        expanded: true,
        docList: docList
      };
      this.docDirList.splice(index, 1, expandedDirectory);
    }).catch((err: Error) => {
      console.error('[ChatPage] 获取目录下的文档列表失败:', JSON.stringify(err));
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 点击目录条目，未展开时拉取文档列表并展开，已展开时收起
   * @date: 2026-09-19
   */
  toggleDirectory = (index: number): void => {
    const directory = this.docDirList[index];
    if (!directory) {
      return;
    }
    if (directory.expanded) {
      // 再次点击目录则收起文档列表，箭头恢复原样
      const collapsedDirectory: DirectoryDocType = {
        directoryId: directory.directoryId,
        directoryName: directory.directoryName,
        expanded: false,
        docList: directory.docList
      };
      this.docDirList.splice(index, 1, collapsedDirectory);
    } else {
      this.loadDirectoryDocList(index);
    }
  }

  /**
   * @author: wuwenqiang
   * @description: 勾选/取消勾选文档
   * @date: 2026-09-19
   */
  toggleDocChecked = (docId: string, checked: boolean): void => {
    if (checked) {
      if (!this.checkedDocIds.includes(docId)) {
        this.checkedDocIds = this.checkedDocIds.concat([docId]);
      }
    } else {
      this.checkedDocIds = this.checkedDocIds.filter((item: string) => item !== docId);
    }
  }

  /**
   * @author: wuwenqiang
   * @description: 确定选择文档，关闭对话框
   * @date: 2026-09-19
   */
  confirmDocSelect = (): void => {
    // 选中了文档则按知识库文档方式提问
    this.type = this.checkedDocIds.length > 0 ? 'document' : '';
    this.docDialogController?.close();
  }

  /**
   * @author: wuwenqiang
   * @description: 取消选择文档，回滚到打开对话框前的已选状态
   * @date: 2026-09-19
   */
  cancelDocSelect = (): void => {
    this.checkedDocIds = this.snapshotCheckedDocIds.slice();
    this.docDialogController?.close();
  }

  /**
   * @author: wuwenqiang
   * @description: 显示创建目录对话框
   * @date: 2026-09-19
   */
  showCreateDirDialog = (): void => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }
    this.newDirectoryName = '';
    this.createDirDialogController = new CustomDialogController({
      customStyle: true,
      builder: this.createDirDialogBuilder.bind(this),
      alignment: DialogAlignment.Center,
    })
    this.createDirDialogController.open()
  }

  /**
   * @author: wuwenqiang
   * @description: 创建目录
   * @date: 2026-09-19
   */
  createDirectory = (): void => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId || !this.newDirectoryName.trim()) {
      return;
    }
    const params: CreateDirectoryParamsType = {
      directory: this.newDirectoryName.trim(),
      tenantId: tenantId
    };
    createDirectoryService(params).then((res) => {
      if (res.data > 0) {
        promptAction.showToast({
          message: '创建成功，点击刷新可查看最新目录',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 关闭创建目录对话框，用户点击刷新按钮后会自动加载最新的目录列表
        this.createDirDialogController?.close();
      } else {
        promptAction.showToast({
          message: res.msg || '创建失败',
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((err: Error) => {
      console.error('[ChatPage] 创建目录失败:', JSON.stringify(err));
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 显示上传文档对话框
   * @date: 2026-09-19
   */
  showUploadDialog = (): void => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }
    // 还没有加载过目录时先加载目录列表
    if (this.docDirList.length === 0) {
      this.loadDocDirectoryList();
    }
    this.uploadDirectoryId = '';
    this.uploadDialogController = new CustomDialogController({
      customStyle: true,
      builder: BottomDialogComponent({
        dialogHeight: '80%',
        builder: this.uploadDialogBuilder.bind(this)
      }),
      alignment: DialogAlignment.Bottom,
    })
    this.uploadDialogController.open()
  }

  /**
   * @author: wuwenqiang
   * @description: 选择上传的目标目录
   * @date: 2026-09-19
   */
  selectUploadDirectory = (directoryId: string): void => {
    this.uploadDirectoryId = directoryId;
  }

  /**
   * @author: wuwenqiang
   * @description: 选择系统文件，选好文件后弹出文档设置对话框
   * @date: 2026-09-19
   */
  confirmUpload = (): void => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId || !this.uploadDirectoryId) {
      return;
    }
    // 拉起系统文件选择器（只允许选择 txt、pdf、word）
    pickDocumentFile(getContext(this).cacheDir).then((file: UploadFileType | null) => {
      if (!file) {
        return;
      }
      // 暂存选中的文件，关闭选择目录对话框，弹出文档设置对话框
      this.pendingUploadFile = file;
      this.selectedFileName = file.fileName;
      this.permissionIndex = 0;
      this.splitMethodIndex = 0;
      this.chunkSize = `${DEFAULT_CHUNK_SIZE}`;
      this.uploadDialogController?.close();
      this.docSettingDialogController = new CustomDialogController({
        customStyle: true,
        builder: this.docSettingDialogBuilder.bind(this),
        alignment: DialogAlignment.Center,
      })
      this.docSettingDialogController.open()
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 确定文档设置后上传文档，把文件与 permission、splitMethod、chunkSize 一起提交
   * @date: 2026-09-19
   */
  uploadDocument = (): void => {
    const tenantId = this.currentTenant?.id;
    const file = this.pendingUploadFile;
    if (!tenantId || !file || !this.uploadDirectoryId) {
      return;
    }
    const splitMethod: string = DOC_SPLIT_METHOD_OPTIONS[this.splitMethodIndex].value;
    // 固定长度分割必须填写分割大小
    if (splitMethod === 'fixed' && !(Number(this.chunkSize) > 0)) {
      promptAction.showToast({
        message: '请输入正确的分割大小',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }
    const params: UploadDocParamsType = {
      tenantId: tenantId,
      directoryId: this.uploadDirectoryId,
      permission: DOC_PERMISSION_OPTIONS[this.permissionIndex].value,
      splitMethod: splitMethod,
      chunkSize: this.chunkSize.trim()
    };
    const directoryId: string = this.uploadDirectoryId;
    uploadDocService(params, file).then((res) => {
      this.docSettingDialogController?.close();
      this.pendingUploadFile = null;
      this.selectedFileName = '';
      promptAction.showToast({
        message: '上传成功',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      // 目标目录已经展开时刷新该目录下的文档列表
      const index: number = this.docDirList.findIndex((item: DirectoryDocType) => item.directoryId === directoryId);
      if (index > -1 && this.docDirList[index].expanded) {
        this.loadDirectoryDocList(index);
      }
    }).catch((err: Error) => {
      console.error('[ChatPage] 上传文档失败:', JSON.stringify(err));
    })
  }

  /**
   * @author: wuwenqiang
   * @description: 文档设置对话框内容构建器（权限、分割模式、分割大小）
   * @date: 2026-09-19
   */
  @Builder
  docSettingDialogBuilder() {
    Column({ space: size.middleGap }) {
      Text('文档设置')
        .fontSize(size.bigFont)
        .fontWeight(FontWeight.Medium)
        .margin({ top: size.middleGap })

      // 待上传的文件名称
      Text(this.selectedFileName)
        .fontSize(size.middleFont)
        .fontColor(colors.gray)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')

      // 权限下拉框
      Row({ space: size.smallGap }) {
        Text('权限')
          .fontSize(size.middleFont)
          .width('25%')
        Select(PERMISSION_SELECT_OPTIONS)
          .selected(this.permissionIndex)
          .value(DOC_PERMISSION_OPTIONS[this.permissionIndex].label)
          .font({ size: size.middleFont })
          .optionFont({ size: size.middleFont })
          .layoutWeight(1)
          .onSelect((index: number) => {
            this.permissionIndex = index;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分割模式下拉框
      Row({ space: size.smallGap }) {
        Text('分割模式')
          .fontSize(size.middleFont)
          .width('25%')
        Select(SPLIT_METHOD_SELECT_OPTIONS)
          .selected(this.splitMethodIndex)
          .value(DOC_SPLIT_METHOD_OPTIONS[this.splitMethodIndex].label)
          .font({ size: size.middleFont })
          .optionFont({ size: size.middleFont })
          .layoutWeight(1)
          .onSelect((index: number) => {
            this.splitMethodIndex = index;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // 分割大小输入框：只对固定长度分割可见
      if (DOC_SPLIT_METHOD_OPTIONS[this.splitMethodIndex].value === 'fixed') {
        Row({ space: size.smallGap }) {
          Text('分割大小')
            .fontSize(size.middleFont)
            .width('25%')
          TextInput({
            text: this.chunkSize,
            placeholder: '请输入分割大小'
          })
            .type(InputType.Number)
            .height(size.inputHeight)
            .layoutWeight(1)
            .backgroundColor(colors.pageBackground)
            .borderRadius(size.inputHeight / 2)
            .padding({ left: size.middleGap, right: size.middleGap })
            .onChange((value: string) => {
              this.chunkSize = value;
            })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }

      // 取消/确定按钮
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
            // 取消本次上传
            this.pendingUploadFile = null;
            this.selectedFileName = '';
            this.docSettingDialogController?.close();
          })

        Text('确定')
          .width('45%')
          .height(size.btnHeight)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .backgroundColor(colors.primary)
          .borderRadius(size.btnHeight / 2)
          .onClick(() => {
            this.uploadDocument();
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
   * @author: wuwenqiang
   * @description: 选择文档对话框内容构建器（复用查询文档的底部弹窗组件）
   * @date: 2026-09-19
   */
  @Builder
  docSelectDialogBuilder() {
    Column() {
      // 标题栏：左边刷新图标、中间标题、右边创建目录图标和上传图标
      Row() {
        Image($r("app.media.icon_refresh"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 重新加载文档目录
            this.loadDocDirectoryList();
          })
          .margin({ left: size.middleGap })
        Text('选择文档')
          .fontSize(size.middleFont)
          .fontWeight(FontWeight.Medium)
          .padding(size.middleGap)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_create_directory"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 创建目录
            this.showCreateDirDialog();
          })
        Image($r("app.media.icon_upload"))
          .width(size.smallIcon)
          .height(size.smallIcon)
          .opacity(size.opacity)
          .onClick(() => {
            // 上传文档
            this.showUploadDialog();
          })
          .margin({ left: size.middleGap, right: size.middleGap })
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })

      // 灰色背景内容区
      Column({ space: size.middleGap }) {
        // 目录列表卡片
        if (this.docDirList.length === 0) {
          Column() {
            Text('暂无目录')
              .fontColor(colors.gray)
              .padding(size.middleGap)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
        } else {
          List() {
            ForEach(this.docDirList, (directory: DirectoryDocType, index: number) => {
              ListItem() {
                Column() {
                  // 目录条目：目录名称 + 箭头
                  Row() {
                    Text(directory.directoryName)
                      .fontSize(size.middleFont)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)
                    Image($r("app.media.icon_arrow"))
                      .width(size.smallIcon)
                      .height(size.smallIcon)
                      .opacity(size.opacity)
                      // 展开时箭头顺时针旋转90度变成向下
                      .rotate({ angle: directory.expanded ? 90 : 0 })
                  }
                  .width('100%')
                  .padding(size.middleGap)
                  .onClick(() => {
                    this.toggleDirectory(index);
                  })

                  // 目录下的文档列表
                  if (directory.expanded) {
                    ForEach(directory.docList, (doc: DocumentType) => {
                      Row() {
                        Text(doc.name)
                          .fontSize(size.middleFont)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                        // 文档复选框，勾选后确定按钮激活
                        Checkbox({ name: doc.id, group: 'docSelectGroup' })
                          .select(this.checkedDocIds.includes(doc.id))
                          .width(size.middleIcon)
                          .height(size.middleIcon)
                          .onChange((value: boolean) => {
                            this.toggleDocChecked(doc.id, value);
                          })
                      }
                      .width('100%')
                      .padding({
                        left: size.middleGap,
                        right: size.middleGap,
                        top: size.smallGap,
                        bottom: size.smallGap
                      })
                    }, (doc: DocumentType) => `${doc.id}_${this.checkedDocIds.includes(doc.id)}`)
                  }
                }
                .width('100%')
                // 每个目录用一条灰色横线隔开
                .border({
                  width: { bottom: index === this.docDirList.length - 1 ? 0 : 1 },
                  color: { bottom: colors.borderColor },
                  style: { bottom: BorderStyle.Solid }
                })
              }
            }, (directory: DirectoryDocType) => `${directory.directoryId}_${directory.expanded}_${directory.docList.length}`)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
        }

        // 取消/确定按钮
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
              this.cancelDocSelect();
            })

          Text('确定')
            .width('45%')
            .height(size.btnHeight)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .backgroundColor(this.checkedDocIds.length > 0 ? colors.primary : colors.gray)
            .borderRadius(size.btnHeight / 2)
            .enabled(this.checkedDocIds.length > 0)
            .onClick(() => {
              // 勾选了文档才能确定
              if (this.checkedDocIds.length > 0) {
                this.confirmDocSelect();
              }
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(colors.pageBackground)
      .padding(size.middleGap)
    }
    .height("100%")
    .width('100%')
    .backgroundColor(colors.white)
    .borderRadius({ topLeft: size.middleBorderRaduis, topRight: size.middleBorderRaduis })
  }

  /**
   * @author: wuwenqiang
   * @description: 创建目录对话框内容构建器
   * @date: 2026-09-19
   */
  @Builder
  createDirDialogBuilder() {
    Column({ space: size.middleGap }) {
      Text('创建目录')
        .fontSize(size.bigFont)
        .fontWeight(FontWeight.Medium)
        .margin({ top: size.middleGap })

      // 目录名称输入框
      TextInput({
        text: this.newDirectoryName,
        placeholder: '请输入目录名称'
      })
        .height(size.inputHeight)
        .width('100%')
        .backgroundColor(colors.pageBackground)
        .borderRadius(size.inputHeight / 2)
        .padding({ left: size.middleGap, right: size.middleGap })
        .onChange((value: string) => {
          this.newDirectoryName = value;
        })

      // 取消/确定按钮
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
            this.createDirDialogController?.close();
          })

        Text('确定')
          .width('45%')
          .height(size.btnHeight)
          .textAlign(TextAlign.Center)
          .fontColor(Color.White)
          .backgroundColor(this.newDirectoryName.trim() ? colors.primary : colors.gray)
          .borderRadius(size.btnHeight / 2)
          .enabled(!!this.newDirectoryName.trim())
          .onClick(() => {
            // 目录名称不为空才能确定
            if (this.newDirectoryName.trim()) {
              this.createDirectory();
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
   * @author: wuwenqiang
   * @description: 上传文档对话框内容构建器
   * @date: 2026-09-19
   */
  @Builder
  uploadDialogBuilder() {
    Column() {
      // 标题栏
      Row() {
        Blank().width(size.smallIcon).height(size.smallIcon)
        Text('上传文档')
          .fontSize(size.middleFont)
          .fontWeight(FontWeight.Medium)
          .padding(size.middleGap)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_close"))
          .width(size.middleFont)
          .height(size.middleFont)
          .opacity(0.5)
          .onClick(() => {
            this.uploadDialogController?.close()
          })
          .margin({ right: size.middleGap })
      }
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })

      // 灰色背景内容区
      Column({ space: size.middleGap }) {
        // 目录列表卡片，目录名称后面是单选按钮
        if (this.docDirList.length === 0) {
          Column() {
            Text('暂无目录')
              .fontColor(colors.gray)
              .padding(size.middleGap)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
        } else {
          List() {
            ForEach(this.docDirList, (directory: DirectoryDocType, index: number) => {
              ListItem() {
                Row() {
                  Text(directory.directoryName)
                    .fontSize(size.middleFont)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Radio({ value: directory.directoryId, group: 'uploadDirectoryGroup' })
                    .checked(this.uploadDirectoryId === directory.directoryId)
                    .width(size.middleIcon)
                    .height(size.middleIcon)
                    .onChange((isChecked: boolean) => {
                      if (isChecked) {
                        this.selectUploadDirectory(directory.directoryId);
                      }
                    })
                }
                .width('100%')
                .padding(size.middleGap)
                .border({
                  width: { bottom: index === this.docDirList.length - 1 ? 0 : 1 },
                  color: { bottom: colors.borderColor },
                  style: { bottom: BorderStyle.Solid }
                })
                .onClick(() => {
                  this.selectUploadDirectory(directory.directoryId);
                })
              }
            }, (directory: DirectoryDocType) => `${directory.directoryId}_${this.uploadDirectoryId === directory.directoryId}`)
          }
          .width('100%')
          .layoutWeight(1)
          .backgroundColor(colors.white)
          .borderRadius(size.middleBorderRaduis)
        }

        // 取消/确定按钮
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
              this.uploadDialogController?.close();
            })

          Text('确定')
            .width('45%')
            .height(size.btnHeight)
            .textAlign(TextAlign.Center)
            .fontColor(Color.White)
            .backgroundColor(this.uploadDirectoryId ? colors.primary : colors.gray)
            .borderRadius(size.btnHeight / 2)
            .enabled(!!this.uploadDirectoryId)
            .onClick(() => {
              // 选择了目录才能确定上传
              if (this.uploadDirectoryId) {
                this.confirmUpload();
              }
            })
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(colors.pageBackground)
      .padding(size.middleGap)
    }
    .height("100%")
    .width('100%')
    .backgroundColor(colors.white)
    .borderRadius({ topLeft: size.middleBorderRaduis, topRight: size.middleBorderRaduis })
  }

  /**
   * @author: system
   * @description: 显示租户切换对话框
   * @date: 2026-04-29
   */
  showTenantDialog = () => {
    // 获取公司ID
    const companyData = AppStorage.get<CompanyType>(COMPANY_DATA);
    const companyId = companyData?.id || '';

    // 如果租户列表为空，重新获取
    if (this.tenantList.length === 0) {
      getTenantListService(companyId).then((res) => {
        this.tenantList = res.data || [];
        this.openTenantDialog();
      }).catch((error: Error) => {
        promptAction.showToast({
          message: "获取租户列表失败",
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      });
    } else {
      this.openTenantDialog();
    }
  }

  /**
   * @author: system
   * @description: 打开租户切换对话框
   * @date: 2026-06-26
   */
  openTenantDialog = () => {
    // 获取当前选中的租户ID
    const currentTenantId = this.currentTenant?.id || '';

    // 构建选项列表，标记当前选中的租户
    const options = this.tenantList.map(item => {
      return item.id === currentTenantId ? `${item.name} ✓` : item.name;
    });

    this.dialogController = new CustomDialogController({
      customStyle: true,
      builder: OptionDialogComponent({
        cancel: (): void => this.onTenantDialogCancel(),
        confirm: (value: string, index: number): void => this.onTenantSwitch(index),
        options: options,
      }),
      alignment: DialogAlignment.Bottom,
    });
    this.dialogController.open();
  }

  /**
   * @author: system
   * @description: 租户对话框取消
   * @date: 2026-04-29
   */
  onTenantDialogCancel = () => {
    this.dialogController?.close();
  }

  /**
   * @author: system
   * @description: 刷新模型列表
   * @date: 2026-06-26
   */
  refreshModelList = (companyId: string) => {
    getModelListService(companyId).then((res) => {
      if (res.data && res.data.length > 0) {
        this.modelList = res.data;
        this.activeModelName = res.data[0].modelName;
      }
    })
  }

  /**
   * @author: system
   * @description: 切换租户
   * @date: 2026-04-29
   */
  onTenantSwitch = (index: number) => {
    const selectedTenant = this.tenantList[index];

    if (!selectedTenant) {
      this.dialogController?.close();
      return;
    }

    this.dialogController?.close();

    // 切换租户
    this.switchTenant(selectedTenant);
  }

  build() {
    Stack() {
      Column() {
        Row() {
          AvaterComponent({dimensions:size.middleAvater,avater:this.userData.avater}).onClick(()=>{
            router.pushUrl({
              url: 'pages/UserPage'
            });
          })
          // 中间标题区域 - 显示租户名称和模型名称
          Row() {
            // 租户名称 - 可点击切换
            Text(this.currentTenant?.name || "私人空间")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.showTenantDialog();
              })

            Text(" | ")
              .fontSize(16)
              .fontColor(colors.gray)

            // 模型名称 - 可点击切换
            Text(this.activeModelName || "选择模型")
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .onClick(() => {
                this.onTabModel();
              })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          Image($r('app.media.icon_menu'))
            .width(size.smallIcon)
            .height(size.smallIcon)
            .opacity(size.opacity)
            .onClick(() => {
              this.showMenu = true;
            })
            .bindPopup(this.showMenu, {
              builder: this.popupBuilder, // 气泡的内容
              placement: Placement.Bottom, // 气泡的弹出位置
              popupColor: colors.gray // 气泡的背景色
            })
        }
        .alignItems(VerticalAlign.Center)
        .padding(size.middleGap)
        .backgroundColor(colors.white)

        Scroll(this.scroller) {
          Column({ space: size.middleGap }) {
            ForEach(this.chatList, (item: ChatType, index: number) => {
              if (item.position == PositionEnum.LEFT) {
                if (item.thinkContent || item.responseContent) {
                  Row() {
                    Image($r("app.media.icon_ai"))
                      .width(size.middleIcon)
                      .height(size.middleIcon)
                      .margin({ right: size.smallIcon })
                    Row() {
                      Image($r("app.media.icon_triangle"))
                        .width(size.smallIcon)
                        .height(size.smallIcon)
                        .alignSelf(ItemAlign.Start)
                        .position({ x: -size.smallIcon / 1.5, y: size.smallIcon / 2 })
                      Row() {
                        Row(){
                          Column(){
                            if (item.thinkContent) {
                              Text(item.thinkContent?.replace(/^(<think>)|(<\/think>)$/g, ""))
                                .fontColor(colors.gray)
                            }
                            if (item.responseContent) {
                              // Text(item.responseContent)
                              MarkdownRenderer({markdownText:item.responseContent})
                            }
                          }.alignItems(HorizontalAlign.Start)
                        }
                        .justifyContent(FlexAlign.Start)
                        .backgroundColor(colors.white)
                        .justifyContent(FlexAlign.Start)
                        .borderRadius(size.middleBorderRaduis)
                        .padding(size.middleGap)
                      }.layoutWeight(1)
                    }.layoutWeight(1)
                  }
                  .width("100%")
                  .alignItems(VerticalAlign.Top)
                  .justifyContent(FlexAlign.Start)
                }
              } else {
                Row() {
                  Row() {
                    Text(item.text)
                      .backgroundColor(colors.white)
                      .borderRadius(size.middleBorderRaduis)
                      .padding(size.middleGap)
                    Image($r("app.media.icon_triangle"))
                      .width(size.smallIcon)
                      .height(size.smallIcon)
                      .alignSelf(ItemAlign.Start)
                      .rotate({ angle: 180 })
                      .position({ right: -size.smallIcon / 1.5, top: size.smallIcon / 2 })
                  }.layoutWeight(1).justifyContent(FlexAlign.End)

                  AvaterComponent({ dimensions: size.middleIcon,avater:this.userData.avater }).margin({ left: size.smallIcon })
                }
                .width("100%")
              }
            })
            if (this.loading) {
              Row() {
                Image($r("app.media.icon_ai"))
                  .width(size.middleIcon)
                  .height(size.middleIcon)
                  .margin({ right: size.smallIcon })
                Row() {
                  Image($r("app.media.icon_triangle"))
                    .width(size.smallIcon)
                    .height(size.smallIcon)
                    .alignSelf(ItemAlign.Start)
                    .position({ x: -size.smallIcon / 1.5, y: size.smallIcon / 2 })
                  Column() {
                    if (!this.thinkContent && !this.responseContent) {
                      Text("正在思考中").fontColor(colors.gray)
                    } else {
                      if (this.thinkContent) {
                        Text(this.thinkContent.replace(/^(<think>)[\s\s\n]?|(<\/think>[\s\S\n]?)$/gi, ""))
                          .fontColor(colors.gray)
                      }
                      if (this.responseContent) {
                        MarkdownRenderer({markdownText:this.responseContent})
                        // Text(this.responseContent)
                      }
                    }
                  }
                }.backgroundColor(colors.white)
                .borderRadius(size.middleBorderRaduis)
                .padding(size.middleGap)
                .layoutWeight(1)
              }
              .width("100%")
              .alignItems(VerticalAlign.Top)
            }
          }
          .width("100%")
          .justifyContent(FlexAlign.Start)
          .alignItems(HorizontalAlign.Start)
        }
        .padding(size.middleGap)
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .layoutWeight(1)
        Scroll(){
          Row({space:size.middleGap}){
            Text("深度思考")
              .fontColor(this.showThink ? colors.primary :colors.gray)
              .borderRadius(size.inputHeight)
              .border({
                width:1,
                color:this.showThink ? colors.primary :colors.gray,
                style:BorderStyle.Solid
              })
              .padding({
                top:size.smallGap,
                bottom:size.smallGap,
                left:size.middleGap,
                right:size.middleGap
              })
              .backgroundColor(colors.white)
              .onClick(()=>{
                this.showThink = !this.showThink
              })
            // 提示词按钮，默认非激活状态，样式与深度思考按钮保持一致
            Text("提示词")
              .fontColor(this.promptId ? colors.primary : colors.gray)
              .borderRadius(size.inputHeight)
              .border({
                width:1,
                color:this.promptId ? colors.primary : colors.gray,
                style:BorderStyle.Solid
              })
              .padding({
                top:size.smallGap,
                bottom:size.smallGap,
                left:size.middleGap,
                right:size.middleGap
              })
              .backgroundColor(colors.white)
              .onClick(()=>{
                this.showPromptListDialog()
              })
            // 查询文档按钮，默认非激活状态，样式与提示词按钮保持一致
            Text("查询文档")
              .fontColor(this.checkedDocIds.length > 0 ? colors.primary : colors.gray)
              .borderRadius(size.inputHeight)
              .border({
                width:1,
                color:this.checkedDocIds.length > 0 ? colors.primary : colors.gray,
                style:BorderStyle.Solid
              })
              .padding({
                top:size.smallGap,
                bottom:size.smallGap,
                left:size.middleGap,
                right:size.middleGap
              })
              .backgroundColor(colors.white)
              .onClick(()=>{
                this.showDocSelectDialog()
              })

            Row({space:size.smallGap}){
              Text(this.language == "zh" ? "中文" : "英文")
              Image($r('app.media.icon_switch')).width(size.smallIcon).height(size.smallGap)
            }
            .padding(size.smallGap)
            .onClick(()=>{
              this.language = this.language == "zh" ? "en" : "zh";
            })
            .borderRadius(size.inputHeight)
            .border({
              width:1,
              color: colors.black,
              style:BorderStyle.Solid
            })
          }
        }
        .backgroundColor(colors.pageBackground)
        .padding(size.middleGap)
        .scrollable(ScrollDirection.Horizontal)
        Row({ space: size.middleGap }) {
          Image($r("app.media.icon_chat"))
            .opacity(size.opacity)
            .width(size.middleIcon)
            .height(size.middleIcon)
            .onClick(() => {
              this.chatId = "";
            })
          Row() {
            TextInput({
              text: this.userInputValue,
              placeholder: "有问题，尽管问"
            })
              .height(size.middleAvater)
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value) => {
                this.userInputValue = value.trim();
              })

            if (this.userInputValue) {
              Image($r('app.media.icon_clear'))
                .width(size.smallIcon)
                .height(size.smallIcon)
                .onClick(() => {
                  this.userInputValue = '';
                })
                .margin({ right: size.middleGap })
            }
          }
          .borderRadius(size.middleAvater)
          .backgroundColor(colors.pageBackground)
          .layoutWeight(1)

          Row() {
            if (this.loading) {
              Row()
                .height(size.smallIcon)
                .width(size.smallIcon)
                .backgroundColor(colors.gray)
                .borderRadius(size.smallBorderRaduis / 2)
            } else {
              Image($r("app.media.icon_send"))
                .opacity(size.opacity)
                .width(size.middleIcon)
                .height(size.middleIcon)
                .onClick(this.onSend)
            }

          }
          .width(size.middleAvater)
          .height(size.middleAvater)
          .borderRadius(size.middleAvater)
          .backgroundColor(colors.pageBackground)
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .backgroundColor(colors.white)
        .padding(size.middleGap)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(colors.pageBackground)

    }.width("100%").height("100%")
  }
}