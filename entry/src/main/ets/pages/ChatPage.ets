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
  DocumentCheckType,
  PromptInterface,
  CompanyType
} from '../type/Index';
import {
  getModelListService,
  getChatHistoryService,
  getMyDocumentService,
  deleteMyDocumentService,
  getDirectoryListService,
  getPromptService,
  updatePromptService,
  getTenantListService,
  getPromptByIdService
} from '../service/Index';
import { PositionEnum } from '../common/enum';
import AvaterComponent from "../components/AvaterComponent";
import { USER_DATA, COMPANY_DATA, PAGE_SIZE, HOST } from '../common/constant';
import { formatTimeAgo, generateSecureID, formatTime} from "../utils/common";
import { display, promptAction } from '@kit.ArkUI';
import webSocket from '@ohos.net.webSocket';
import { BusinessError } from '@kit.BasicServicesKit';
import api from '../api';
import preference from '../utils/PreferenceModel';
import OptionDialogComponent from '../components/OptionDialogComponent';
import DialogComponent from "../components/DialogComponent";
import BottomDialogComponent from "../components/BottomDialogComponent";
import MarkdownRenderer from "../components/MarkdownRenderer";

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
  private myDocList: DocumentType[] = [];
  @State groupDocList: DocumentCheckType[] = [];
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
  @State directoryList: Array<DirectoryType> = [];
  @State checkedDocIds: string[] = [];
  private message: string = "";
  private dialogController: CustomDialogController | null = null
  private ws: webSocket.WebSocket | null = null;
  @State promptData: PromptInterface | null = null;
  @State userInputValue: string = ""
  @State tenantList: Array<TenantType> = []
  @State currentTenant: TenantType | null = null;
  @State promptInputValue: string = '';
  @StorageLink(COMPANY_DATA) companyData: CompanyType | null = null;
  private promptDialogController: CustomDialogController | null = null;
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

    // 7. 在租户信息加载完成后获取提示词
    await this.getPrompt();
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

    // 重新加载提示词（切换租户时重新获取）
    await this.getPrompt();
  }

  /**
   * @author: wuwenqiang
   * @description: 打开文件目录对话框
   * @date: 2025-9-17 10:19
   */
  onShowDirectoryDialog = () => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    getDirectoryListService(tenantId).then((res) => {
      this.directoryList.splice(1, this.directoryList.length);
      this.directoryList.push(...res.data);
      this.dialogController = new CustomDialogController({
        customStyle: true,
        builder: BottomDialogComponent({
          dialogHeight: '80%',
          builder: this.directoryListBuilder.bind(this)
        }),
        alignment: DialogAlignment.Bottom,
      })
      this.dialogController.open()
    })
  }

  /**
   * @author: system
   * @description: 我的文档对话框内容构建器
   * @date: 2026-04-28
   */
  @Builder
  myDocumentBuilder() {
    Column() {
      // 标题栏
      Row() {
        Blank().width(size.smallIcon).height(size.smallIcon)
        Text('我的文档')
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
            this.myDocDialogController?.close()
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

      // 文档列表内容区
      if (this.myDocList.length === 0) {
        Column() {
          Text("暂无文档")
            .fontColor(colors.gray)
            .padding(size.middleGap)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          List() {
            ForEach(this.myDocList, (item: DocumentType, index: number) => {
              ListItem() {
                Column({ space: size.miniGap }) {
                  Text(formatTime(item.createTime))
                    .fontColor(colors.gray)
                    .fontSize(12)
                    .width('100%')
                  Text(item.name)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .fontSize(size.middleFont)
                }
                .alignItems(HorizontalAlign.Start)
                .justifyContent(FlexAlign.Start)
                .width('100%')
                .padding({
                  top: size.middleGap,
                  bottom: size.middleGap,
                  left: size.middleGap,
                  right: size.middleGap
                })
              }
              .swipeAction({
                end: () => {
                  return this.DeleteButton(item)
                }
              })
            })
          }
          .width('100%')
        }
        .layoutWeight(1)
        .backgroundColor(colors.white)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.white)
    .borderRadius({ topLeft: size.middleBorderRaduis, topRight: size.middleBorderRaduis })
  }

  /**
   * @author: wuwenqiang
   * @description: 收藏夹
   * @date: 2024-07-01 21:45
   */
  @Builder
  directoryListBuilder() {
    Column() {
      Row() {
        Image($r("app.media.icon_add"))
          .width(size.middleFont)
          .height(size.middleFont)
          .opacity(0.5)
          .onClick(() => {

          })
          .margin({ left: size.middleGap })
        Text('选择文件夹')
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
    Column(){

    }.backgroundColor(colors.pageBackground).padding({
      left: size.middleGap,
      right: size.middleGap,
      top: size.middleGap
    }).flexGrow(1)
  }

  /**
   * @author: system
   * @description: 显示修改提示词对话框
   * @date: 2026-04-27
   */
  showPromptDialog = () => {
    // 获取当前租户ID
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 先获取最新的提示词
    getPromptService(tenantId).then((res) => {
      this.promptInputValue = res.data.prompt;

      // 打开对话框
      this.promptDialogController = new CustomDialogController({
        customStyle: true,
        builder: BottomDialogComponent({
          dialogHeight: 'auto',
          builder: this.promptDialogBuilder.bind(this)
        }),
        alignment: DialogAlignment.Bottom,
      })
      this.promptDialogController.open()
    }).catch(() => {
      this.promptDialogController = new CustomDialogController({
        customStyle: true,
        builder: BottomDialogComponent({
          dialogHeight: 'auto',
          builder: this.promptDialogBuilder.bind(this)
        }),
        alignment: DialogAlignment.Bottom,
      })
      this.promptDialogController.open()
    });
  }

  /**
   * @author: system
   * @description: 保存提示词
   * @date: 2026-04-27
   */
  savePrompt = () => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    const promptData: PromptInterface = {
      id: this.promptData?.id || '',
      tenantId: tenantId,
      userId: "",
      prompt: this.promptInputValue.trim(),
      createTime: "",
      updateTime: ""
    };

    updatePromptService(promptData).then((res) => {
      if (res.data !== null) {
        promptAction.showToast({
          message: "保存成功",
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
        // 更新本地提示词数据
        this.promptData = promptData;
        // 关闭对话框
        this.promptDialogController?.close();
      } else {
        promptAction.showToast({
          message: res.msg || "保存失败",
          duration: 2000,
          bottom: px2vp(display.getDefaultDisplaySync().height) / 2
        });
      }
    }).catch((error: Error) => {
      console.error('保存提示词失败:', JSON.stringify(error));
      promptAction.showToast({
        message: "保存失败，请重试",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    });
  }

  /**
   * @author: system
   * @description: 提示词对话框内容构建器
   * @date: 2026-04-27
   */
  @Builder
  promptDialogBuilder() {
    Column() {
      // 标题
      Text('修改提示词')
        .fontSize(size.middleFont)
        .fontWeight(FontWeight.Medium)
        .padding(size.middleGap)
        .width('100%')
        .textAlign(TextAlign.Center)
        .border({
          width: { bottom: 1 },
          color: { bottom: colors.borderColor },
          style: { bottom: BorderStyle.Solid }
        })

      // 灰色背景内容区
      Column() {
        // 白色卡片
        Column() {
          // 多行文本框
          TextArea({
            text: this.promptInputValue,
            placeholder: "请输入提示词"
          })
            .height(size.textareaHeight)
            .backgroundColor(colors.white)
            .borderRadius(size.middleBorderRaduis)
            .padding(size.middleGap)
            .onChange((value: string) => {
              this.promptInputValue = value;
            })
        }
        .width('100%')
        .backgroundColor(colors.white)
        .borderRadius(size.middleBorderRaduis)
        .padding(size.middleGap)

        // 保存按钮
        Text('保存')
          .width('100%')
          .height(size.btnHeight)
          .textAlign(TextAlign.Center)
          .borderRadius(size.btnHeight / 2)
          .margin({ top: size.middleGap, bottom: size.middleGap })
          .fontColor(Color.White)
          .backgroundColor(this.promptInputValue.trim() ? colors.primary : colors.gray)
          .enabled(this.promptInputValue.trim() ? true : false)
          .onClick(() => {
            if (this.promptInputValue.trim()) {
              this.savePrompt();
            }
          })
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor(colors.pageBackground)
      .padding(size.middleGap)
    }
    .height("80%")
    .width('100%')
    .backgroundColor(colors.white)
    .borderRadius({ topLeft: size.middleBorderRaduis, topRight: size.middleBorderRaduis })
  }

  /**
   * @author: system
   * @description: 显示我的文档对话框
   * @date: 2026-04-28
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

    // 加载我的文档列表
    getMyDocumentService(tenantId).then((res) => {
      this.myDocList = res.data;
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
    }).catch((error: Error) => {
      console.error('获取文档列表失败:', JSON.stringify(error));
      promptAction.showToast({
        message: "获取文档列表失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    });
  }

  // popup构造器定义弹框内容
  @Builder
  popupBuilder() {
    Column() {
      Text("修改提示词").height(size.btnHeight).onClick(() => {
        this.showMenu = false;
        this.showPromptDialog();
      })
      Divider().height(1).color(colors.borderColor)
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
      Text("上传文档").height(size.btnHeight).onClick(this.onShowDirectoryDialog)
      Divider().height(1).color(colors.borderColor)
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
   * @author: system
   * @description: 获取提示词（根据租户ID和缓存的提示词ID）
   * @date: 2026-04-27
   */
  getPrompt = async (): Promise<void> => {
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      console.warn('[ChatPage] 获取提示词失败：租户ID为空');
      return;
    }

    try {
      // 从缓存获取提示词ID
      const cachedPromptId = await preference.getPreference(`${this.userData.id}:${tenantId}:promptId`) || '';

      // 调用接口获取提示词
      const res = await getPromptByIdService(tenantId, cachedPromptId);
      if (res.data && res.data.prompt) {
        this.promptData = res.data;
        // 如果缓存中没有promptId，将返回的prompt.id写入缓存
        if (!cachedPromptId && res.data.id) {
          await preference.putPreference(`${this.userData.id}:${tenantId}:promptId`, res.data.id);
        }
      }
    } catch (error) {
      console.error('[ChatPage] 获取提示词失败:', JSON.stringify(error));
    }
  }

  /**
   * @author: wuwenqiang
   * @description: 删除弹窗
   * @date: 2025-04-13 12:07
   */
  @Builder
  DeleteButton(docItem: DocumentType) {
    Column() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(16)
    }
    .justifyContent(FlexAlign.Center)
    .width(80)
    .height('100%')
    .backgroundColor(colors.warn)
    .onClick(() => {
      this.dialogController = new CustomDialogController({
        customStyle: false,
        builder: DialogComponent({
          title: `是否删除文档：${docItem.name}`,
          cancel: () => {
            this.dialogController?.close();
          },
          confirm: () => {
            deleteMyDocumentService(docItem.id).then((res) => {
              promptAction.showToast({
                message: "删除文档成功",
                duration: 2000,
                bottom: px2vp(display.getDefaultDisplaySync().height) / 2
              })
              // 刷新文档列表
              const tenantId = this.currentTenant?.id;
              if (tenantId) {
                getMyDocumentService(tenantId).then((res) => {
                  this.myDocList = res.data;
                });
              }
              this.dialogController?.close()
            }).catch(() => {
              promptAction.showToast({
                message: "删除文档失败",
                duration: 2000,
                bottom: px2vp(display.getDefaultDisplaySync().height) / 2
              })
            })
          },
        }),
        alignment: DialogAlignment.Center,
      })
      this.dialogController.open()
    })
  }

  onClickDoc(){
    const tenantId = this.currentTenant?.id;
    if (!tenantId) {
      promptAction.showToast({
        message: "获取租户信息失败",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    getMyDocumentService(tenantId).then((res) => {
      this.groupDocList.length = 0;
      res.data.forEach((aItem) => {
        let docGroupItem: DocumentCheckType | undefined = this.groupDocList.find((bItem) => bItem.directoryId == aItem.directoryId)
        if (!docGroupItem) {
          docGroupItem = {
            checked: false,
            directoryName: aItem.directoryName,
            directoryId: aItem.directoryId,
            docList: []
          }
          this.groupDocList.push(docGroupItem);
        }
        aItem.checked = this.checkedDocIds.includes(aItem.id);
        docGroupItem.docList.push(aItem);
      })
      this.dialogController = new CustomDialogController({
        customStyle: true,
        builder: BottomDialogComponent({
          dialogHeight: '80%',
          builder: this.documentCheckBuilder.bind(this)
        }),
        alignment: DialogAlignment.Bottom,
      })
      this.dialogController.open()
    })
  }

  // popup构造器定义弹框内容
  @Builder
  documentCheckBuilder() {
    Column() {
      Row() {
        Blank().width(size.smallIcon).height(size.smallIcon)
        Text('知识库')
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
      .width("100%")
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })
      Scroll(){
        Column({space:size.middleGap}){
          ForEach(this.groupDocList,(aItem:DocumentCheckType,aIndex:number)=>{
            Column({space:size.middleGap}){
              Row({space:size.smallGap}){
                Text(aItem.directoryName)
                Image($r("app.media.icon_arrow"))
                  .height(size.smallGap)
              }.justifyContent(FlexAlign.Start)
              ForEach(aItem.docList,(bItem:DocumentType,bIndex)=>{
                Row(){
                  Text(bItem.name).layoutWeight(1)
                  Stack({ alignContent: Alignment.Center }) {
                    // 圆形背景
                    Circle({ width: size.middleIcon, height: size.middleIcon })
                      .fill(bItem.checked ? '#007DFF' : '#F2F2F2')
                      .stroke(bItem.checked ? '#007DFF' : '#999999')

                    // 使用文字对勾
                    if (bItem.checked) {
                      Text('✓')
                        .fontSize(size.middleIcon/2)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Bold)
                    }
                  }
                  .onClick(() => {
                    // 添加动画效果
                    animateTo({ duration: 200 }, () => {
                      bItem.checked = !bItem.checked;
                      this.groupDocList.splice(aIndex,1,JSON.parse(JSON.stringify(aItem)));
                      this.checkedDocIds.length = 0;
                      this.groupDocList.forEach((cItem)=>{
                        cItem.docList.forEach((dItem)=>{
                          if(dItem.checked){
                            this.checkedDocIds.push(dItem.id);
                          }
                        })
                      })
                    })
                  })
                }
              })
            }
            .padding({bottom:aIndex !== this.groupDocList.length - 1 ? size.middleGap : 0})
            .border({
              style: {
                bottom: BorderStyle.Solid
              },
              width:{
                bottom: aIndex !== this.groupDocList.length - 1 ? 1 : 0,
              },
              color:{
                bottom:colors.gray
              }
            }).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start)
          })
        }.blockStyle().width("auto").margin(size.middleGap).justifyContent(FlexAlign.Start).alignItems(HorizontalAlign.Start)
      }
      .align(Alignment.Top).layoutWeight(1).backgroundColor(colors.pageBackground)
    }
    .justifyContent(FlexAlign.Start)
    .width("100%").height("100%")
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
            Row({space:size.smallGap}){
              Text("知识库")
                .fontColor(this.type == "document" ? colors.primary :colors.gray)
                .onClick(()=>{
                  this.type = this.type === "document" ? "" : "document";
                })
              Image(this.type === "document" ? $r("app.media.icon_setting_active") : $r("app.media.icon_setting_disabled"))
                .width(size.smallIcon)
                .height(size.smallIcon)
                .onClick(()=>{
                  if(this.type !== "document"){
                    this.type = "document";
                  }else{
                    this.onClickDoc()
                  }
                })
            }
            .backgroundColor(colors.white)
            .borderRadius(size.inputHeight)
            .border({
              width:1,
              color:this.type == "document" ? colors.primary :colors.gray,
              style:BorderStyle.Solid
            })
            .padding({
              top:size.smallGap,
              bottom:size.smallGap,
              left:size.middleGap,
              right:size.middleGap
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