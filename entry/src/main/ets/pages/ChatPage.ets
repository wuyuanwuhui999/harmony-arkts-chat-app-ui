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
  TenantUserType,
  DirectoryType
} from '../type/Index';
import { getModelListService, getChatHistoryService,getMyDocumentService,deleteMyDocumentService, getTenantUserService,
  getDirectoryListService} from '../service/Index';
import { PositionEnum } from '../common/enum';
import AvaterComponent from "../components/AvaterComponent";
import { HOST, PAGE_SIZE, USER_DATA, DEFAULT_TENANT_USER,TENANT_USER_DATA} from '../common/constant';
import { formatTimeAgo, generateSecureID, formatTime} from "../utils/common";
import { display, promptAction } from '@kit.ArkUI';
import webSocket from '@ohos.net.webSocket';
import { BusinessError } from '@kit.BasicServicesKit';
import api from '../api';
import preference from '../utils/PreferenceModel';
import OptionDialogComponent from '../components/OptionDialogComponent';
import DialogComponent from "../components/DialogComponent";
import BottomDialogComponent from "../components/BottomDialogComponent";

@Entry
@Component
export default struct ChatPage {
  @State modelList: Array<ChatModelType> = []
  @State activeModelName: string = "";
  @State prompt: string = "请你自我介绍一下"; // 提示词
  @State chatId: string = "";
  @State loading: boolean = false;
  @State showMenu: boolean = false;
  @State pageNum: number = 1;
  @State total: number = 0;
  @State chatHistoryGroup: GroupedByTimeAgoType = {};
  @State token: string = "";
  @State showHistory:boolean = false;
  private scroller: Scroller = new Scroller()
  private myDocList:DocumentType[] = [];
  @State chatList: Array<ChatType> = [
    {
      responseContent: "你好，我是智能音乐助手小吴同学，请问有什么可以帮助您？",
      position: PositionEnum.LEFT,
    }
  ];
  @State thinkContent: string = "";
  @State responseContent: string = "";
  @State showMyDoc:boolean = false;
  @State showThink:boolean = false;
  @State type:string = "";
  @State language:string = "zh";
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @StorageLink(TENANT_USER_DATA) tenantUser: TenantUserType = {} as TenantUserType;
  @State directoryList:Array<DirectoryType> = [];
  private message: string = "";
  private dialogController: CustomDialogController | null = null
  private ws: webSocket.WebSocket | null = null;

  async aboutToAppear() {
    await this.getStorageTenant();
    getModelListService().then((res) => {
      this.modelList = res.data;
      this.activeModelName = res.data[0].modelName;
    })
  }

  aboutToDisappear() {
    this.ws?.close();
  }

  useChatHistory() {
    const chatHistoryGroup: GroupedByTimeAgoType = JSON.parse(JSON.stringify(this.chatHistoryGroup))
    getChatHistoryService(this.pageNum, PAGE_SIZE).then((res) => {
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
        if (!chatHistoryGroup[timeAgo]) {
          chatHistoryGroup[timeAgo] = [];
        }
        chatHistoryGroup[timeAgo].push(result[key])
      });
      this.chatHistoryGroup = chatHistoryGroup;
    })
  }

  onSend = async () => {
    if (this.prompt.trim() === "") {
      promptAction.showToast({
        message: "请输入要问的问题",
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      })
    } else {
      if (!this.ws) {
        await this.connectWebSocket();
      }
      if (!this.token) {
        this.token = await preference.getToken() as string;
      }
      this.chatId = this.chatId || generateSecureID();
      const payload: ChatParamsType = {
        modelName: this.activeModelName,
        token: this.token, // 替换为实际用户ID
        chatId: this.chatId, // 替换为实际聊天ID
        prompt: this.prompt.trim(),
        type:this.type,
        showThink:this.showThink,
        language: this.language // 如果需要上传文件，请根据实际情况调整
      };
      this.chatList.push({
        text: this.prompt.trim(),
        position: PositionEnum.RIGHT,
      });

      this.prompt = "";
      this.ws?.send(JSON.stringify(payload), () => {
        this.loading = true;
        console.log("发送消息成功")
      })
    }
  }

  connectWebSocket(): Promise<string> {
    return new Promise((resolve, reject) => {
      const url = `ws://${HOST.replace(/http[s]?:\/\//, "")}${api.chatWs}`; // 替换为实际API地址
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
   * @author: wuwenqiang
   * @description: 获取租户i
   * @date: 2025-8-10 18:06
   */
  getStorageTenant = ():Promise<void>=>{
    return preference.getTenantId(this.userData.id!).then(async (res)=>{
      if(res !== undefined && res !== null && res !== ""){
        await getTenantUserService(res).then((respone)=>{
          if(respone.data){
            AppStorage.SetOrCreate<TenantUserType>(TENANT_USER_DATA,respone.data as TenantUserType);
          }else{
            AppStorage.SetOrCreate<TenantUserType>(TENANT_USER_DATA,this.getDefaultTenantUser());
          }
        })
      }else{
        AppStorage.SetOrCreate<TenantUserType>(TENANT_USER_DATA,this.getDefaultTenantUser());
      }
    }).catch(()=>{
      AppStorage.SetOrCreate<TenantUserType>(TENANT_USER_DATA,this.getDefaultTenantUser());
    });
  }

  getDefaultTenantUser():TenantUserType{
    const defaultTenantUser:TenantUserType = JSON.parse(JSON.stringify(DEFAULT_TENANT_USER));
    defaultTenantUser.userId = defaultTenantUser.tenantId = this.userData.id!;
    defaultTenantUser.username = this.userData.username;
    return defaultTenantUser
  }

  /**
   * @author: wuwenqiang
   * @description: 打开文件目录对话框
   * @date: 2025-9-17 10:19
   */
  onShowDirectoryDialog = () => {
    getDirectoryListService(this.tenantUser.tenantId || this.tenantUser.id).then((res)=>{
      this.directoryList.splice(1,this.directoryList.length);
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
   * @author: wuwenqiang
   * @description: 收藏夹
   * @date: 2024-07-01 21:45
   */
  @Builder
  directoryListBuilder() {
    Column() {
      Row() {
        Image($r("app.media.icon_add"))
          .width(size.normalFontSize)
          .height(size.normalFontSize)
          .opacity(0.5)
          .onClick(() => {

          })
          .margin({ left: size.pagePadding })
        Text('选择文件夹')
          .padding(size.pagePadding)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
        Image($r("app.media.icon_close"))
          .width(size.normalFontSize)
          .height(size.normalFontSize)
          .opacity(0.5)
          .onClick(() => {
            this.dialogController?.close()
          })
          .margin({ right: size.pagePadding })
      }
      .justifyContent(FlexAlign.Center)
      .border({
        width: { bottom: 1 },
        color: { bottom: colors.borderColor },
        style: { bottom: BorderStyle.Solid }
      })
    }
    Column(){

    }.backgroundColor(colors.pageBackgroundColor).padding({
      left: size.pagePadding,
      right: size.pagePadding,
      top: size.pagePadding
    }).flexGrow(1)
  }

  // popup构造器定义弹框内容
  @Builder
  popupBuilder() {
    Column() {
      Text("上传文档").height(size.popupMenuHeight).onClick(this.onShowDirectoryDialog)
      Divider().height(1).color(colors.borderColor)
      Text("我的文档").height(size.popupMenuHeight).onClick(()=>{
        this.showMyDoc = true;
        this.showMenu = false;
        getMyDocumentService(this.tenantUser.tenantId).then((res)=>{
          this.myDocList = res.data
        });
      })
      Divider().height(1).color(colors.borderColor)
      Text("历史记录").height(size.popupMenuHeight).onClick(()=>{
        this.showMenu = false;
        this.showHistory = true;
        this.chatHistoryGroup = {};
        this.useChatHistory();
      })
      Divider().height(1).color(colors.borderColor)
      Text("切换模型").height(size.popupMenuHeight).onClick(this.onTabModel)
    }
    .width(size.popupMenuWidth)
  }

  onTabModel=()=>{
    this.dialogController = new CustomDialogController({
      customStyle: true,
      builder: OptionDialogComponent({
        cancel: (): void => this.onCancel(),
        confirm: (value): void => this.onConfirm(value),
        options: this.modelList.map((item)=>item.modelName),
      }),
      alignment: DialogAlignment.Bottom,
    })
  }

  /**
   * @description: 修改用户信息
   * @date: 2024-01-10 23:01
   * @author wuwenqiang
   */
  onConfirm(value: string) {
    this.activeModelName = value;
  }

  onCancel(){
    this.dialogController?.close()
  }

  /**
   * @author: wuwenqiang
   * @description: 删除弹窗
   * @date: 2025-04-13 12:07
   */
  @Builder
  DeleteButton(docItem:DocumentType) {
    Column() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(16)
    }
    .justifyContent(FlexAlign.Center)
    .width(80)
    .height('100%')
    .backgroundColor(colors.warnColor)
    .onClick(() => {
      this.dialogController = new CustomDialogController({
        customStyle: false,
        builder: DialogComponent({
          title: `是否删除文档：${docItem.name}`,
          cancel: () => {
            this.dialogController?.close();
          },
          confirm: () => {
            deleteMyDocumentService(docItem.id).then((res)=>{
              promptAction.showToast({
                message: "删除文档成功",
                duration: 2000,
                bottom: px2vp(display.getDefaultDisplaySync().height) / 2
              })
              this.dialogController?.close()
            }).catch(()=>{
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

  build() {
    Stack() {
      if (this.showHistory) {
        Row() {
          Scroll() {
            Column({ space: size.pagePadding }) {
              ForEach(Object.keys(this.chatHistoryGroup), (key: string) => {
                Column({ space: size.miniPadding }) {
                  Text(key).fontColor(colors.disableTextColor)
                  ForEach(this.chatHistoryGroup[key], (items: ChatHistoryType[]) => {
                    Text(items[0].prompt)
                      .maxLines(1)// 限制最大行数为1
                      .textOverflow({ overflow: TextOverflow.Ellipsis })// 溢出时显示省略号
                      .width('100%') // 必须设置宽度（或固定宽度）触发溢出判断
                      .onClick(()=>{
                        this.showMenu = false;
                        this.chatList.length = 0;
                        this.chatId = items[0].chatId;
                        items.forEach((item)=>{
                          this.chatList.push({
                            text:item.prompt,
                            position:PositionEnum.RIGHT
                          },{
                            thinkContent:item.thinkContent,
                            responseContent:item.responseContent,
                            position:PositionEnum.LEFT
                          })
                        })
                      })
                  })
                }.alignItems(HorizontalAlign.Start)
              })
            }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
          }
          .onScrollEdge((side: Edge) => {
            if (this.total > this.pageNum * PAGE_SIZE) {
              this.pageNum++;
              this.useChatHistory();
            }
          })
          .align(Alignment.TopStart)
          .padding(size.pagePadding)
          .width("70%")
          .backgroundColor(colors.blockColor)
          .height("100%")

          Row()
            .height("100%")
            .layoutWeight(1)
            .backgroundColor(colors.tabNormalColor)
            .opacity(0.5)
            .onClick(() => {
              this.showHistory = false
            })
        }
        .height("100%")
        .width("100%")
        .zIndex(1)
      }else if(this.showMyDoc){
        Row() {
          Scroll() {
            List() {
              ForEach(this.myDocList, (item: DocumentType, index: number) => {
                ListItem() {
                  Column({ space: size.miniPadding }) {
                    Text(formatTime(item.createTime)).fontColor(colors.disableTextColor)
                    Text(item.name)
                      .maxLines(2)// 限制最大行数为1
                      .textOverflow({ overflow: TextOverflow.Ellipsis })// 溢出时显示省略号
                      .width('100%') // 必须设置宽度（或固定宽度）触发溢出判断
                  }.alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Start)
                }.swipeAction({
                  end: () => {
                    return this.DeleteButton(item)
                  }
                })
              })
            }
          }
          .align(Alignment.TopStart)
          .padding(size.pagePadding)
          .width("70%")
          .backgroundColor(colors.blockColor)
          .height("100%")

          Row()
            .height("100%")
            .layoutWeight(1)
            .backgroundColor(colors.tabNormalColor)
            .opacity(0.5)
            .onClick(() => {
              this.showMyDoc = false
            })
        }
        .height("100%")
        .width("100%")
        .zIndex(1)
      }
      Column() {
        Row() {
          AvaterComponent({dimensions:size.middleAvaterSize,avater:this.userData.avater}).onClick(()=>{
            router.pushUrl({
              url: 'pages/UserPage'
            });
          })
          Text("当前接入模型：" + this.activeModelName).layoutWeight(1).textAlign(TextAlign.Center)
          Image($r('app.media.icon_menu'))
            .width(size.smallIconSize)
            .height(size.smallIconSize)
            .opacity(size.opacity)
            .onClick(() => {
              this.showMenu = true;
            })
            .bindPopup(this.showMenu, {
              builder: this.popupBuilder, // 气泡的内容
              placement: Placement.Bottom, // 气泡的弹出位置
              popupColor: colors.disableTextColor // 气泡的背景色
            })
        }
        .alignItems(VerticalAlign.Center)
        .padding(size.pagePadding)
        .backgroundColor(colors.blockColor)

        Scroll(this.scroller) {
          Column({ space: size.pagePadding }) {
            ForEach(this.chatList, (item: ChatType, index: number) => {
              if (item.position == PositionEnum.LEFT) {
                if (item.thinkContent || item.responseContent) {
                  Row() {
                    Image($r("app.media.icon_ai"))
                      .width(size.middlIconSize)
                      .height(size.middlIconSize)
                      .margin({ right: size.smallIconSize })
                    Row() {
                      Image($r("app.media.icon_triangle"))
                        .width(size.smallIconSize)
                        .height(size.smallIconSize)
                        .alignSelf(ItemAlign.Start)
                        .position({ x: -size.smallIconSize / 1.5, y: size.smallIconSize / 2 })
                      Row() {
                        Row(){
                          Column(){
                            if (item.thinkContent) {
                              Text(item.thinkContent?.replace(/^(<think>)|(<\/think>)$/g, ""))
                                .fontColor(colors.disableTextColor)
                            }
                            if (item.responseContent) {
                              Text(item.responseContent)
                            }
                          }.alignItems(HorizontalAlign.Start)
                        }
                        .justifyContent(FlexAlign.Start)
                        .backgroundColor(colors.blockColor)
                        .justifyContent(FlexAlign.Start)
                        .borderRadius(size.blockBorderRaduis)
                        .padding(size.pagePadding)
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
                      .backgroundColor(colors.blockColor)
                      .borderRadius(size.blockBorderRaduis)
                      .padding(size.pagePadding)
                    Image($r("app.media.icon_triangle"))
                      .width(size.smallIconSize)
                      .height(size.smallIconSize)
                      .alignSelf(ItemAlign.Start)
                      .rotate({ angle: 180 })
                      .position({ right: -size.smallIconSize / 1.5, top: size.smallIconSize / 2 })
                  }.layoutWeight(1).justifyContent(FlexAlign.End)

                  AvaterComponent({ dimensions: size.middlIconSize,avater:this.userData.avater }).margin({ left: size.smallIconSize })
                }
                .width("100%")
              }
            })
            if (this.loading) {
              Row() {
                Image($r("app.media.icon_ai"))
                  .width(size.middlIconSize)
                  .height(size.middlIconSize)
                  .margin({ right: size.smallIconSize })
                Row() {
                  Image($r("app.media.icon_triangle"))
                    .width(size.smallIconSize)
                    .height(size.smallIconSize)
                    .alignSelf(ItemAlign.Start)
                    .position({ x: -size.smallIconSize / 1.5, y: size.smallIconSize / 2 })
                  Column() {
                    if (!this.thinkContent && !this.responseContent) {
                      Text("正在思考中").fontColor(colors.disableTextColor)
                    } else {
                      if (this.thinkContent) {
                        Text(this.thinkContent.replace(/^(<think>)[\s\s\n]?|(<\/think>[\s\S\n]?)$/gi, ""))
                          .fontColor(colors.disableTextColor)
                      }
                      if (this.responseContent) {
                        Text(this.responseContent)
                      }
                    }
                  }
                }.backgroundColor(colors.blockColor)
                .borderRadius(size.blockBorderRaduis)
                .padding(size.pagePadding)
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
        .padding(size.pagePadding)
        .align(Alignment.Top)
        .scrollable(ScrollDirection.Vertical)
        .layoutWeight(1)
        Scroll(){
          Row({space:size.pagePadding}){
            Text("深度思考")
              .fontColor(this.showThink ? colors.tabSelectedColor :colors.disableTextColor)
              .borderRadius(size.inputHeight)
              .border({
                width:1,
                color:this.showThink ? colors.tabSelectedColor :colors.disableTextColor,
                style:BorderStyle.Solid
              })
              .padding({
                top:size.smallPadding,
                bottom:size.smallPadding,
                left:size.pagePadding,
                right:size.pagePadding
              })
              .backgroundColor(colors.blockColor)
              .onClick(()=>{
                this.showThink = !this.showThink
              })
            Text("查询文档")
              .fontColor(this.type == "document" ? colors.tabSelectedColor :colors.disableTextColor)
              .borderRadius(size.inputHeight)
              .border({
                width:1,
                color:this.type == "document" ? colors.tabSelectedColor :colors.disableTextColor,
                style:BorderStyle.Solid
              })
              .padding({
                top:size.smallPadding,
                bottom:size.smallPadding,
                left:size.pagePadding,
                right:size.pagePadding
              })
              .backgroundColor(colors.blockColor)
              .onClick(()=>{
                this.type = this.type === "document" ? "" : "document"
              })
            Text("查询数据库")
              .fontColor(this.type == "db" ? colors.tabSelectedColor :colors.disableTextColor)
              .borderRadius(size.inputHeight)
              .border({
                width:1,
                color:this.type == "db" ? colors.tabSelectedColor :colors.disableTextColor,
                style:BorderStyle.Solid
              })
              .padding(size.smallPadding)
              .backgroundColor(colors.blockColor)
              .onClick(()=>{
                this.type = this.type === "db" ? "" : "db"
              })
            Row({space:size.smallPadding}){
              Text(this.language == "zh" ? "中文" : "英文")
              Image($r('app.media.icon_switch')).width(size.smallIconSize).height(size.smallPadding)
            }
            .padding(size.smallPadding)
            .onClick(()=>{
              this.language = this.language == "zh" ? "en" : "zh";
            })
            .borderRadius(size.inputHeight)
            .border({
              width:1,
              color: colors.tabNormalColor,
              style:BorderStyle.Solid
            })
          }
        }
        .backgroundColor(colors.pageBackgroundColor)
        .padding(size.pagePadding)
        .scrollable(ScrollDirection.Horizontal)
        Row({ space: size.pagePadding }) {
          Image($r("app.media.icon_chat"))
            .opacity(size.opacity)
            .width(size.middlIconSize)
            .height(size.middlIconSize)
            .onClick(() => {
              this.chatId = "";
            })
          Row() {
            TextInput({
              text: this.prompt,
              placeholder: "有问题，尽管问"
            })
              .height(size.middleAvaterSize)
              .layoutWeight(1)
              .backgroundColor(Color.Transparent)
              .onChange((value) => {
                this.prompt = value.trim();
              })

            if (this.prompt) {
              Image($r('app.media.icon_clear'))
                .width(size.smallIconSize)
                .height(size.smallIconSize)
                .onClick(() => {
                  this.prompt = '';
                })
                .margin({ right: size.pagePadding })
                .onClick(() => {
                  this.prompt = '';
                })
            }
          }
          .borderRadius(size.middleAvaterSize)
          .backgroundColor(colors.pageBackgroundColor)
          .layoutWeight(1)

          Row() {
            if (this.loading) {
              Row()
                .height(size.smallIconSize)
                .width(size.smallIconSize)
                .backgroundColor(colors.disableTextColor)
                .borderRadius(size.smallBorderRaduis / 2)
            } else {
              Image($r("app.media.icon_send"))
                .opacity(size.opacity)
                .width(size.middlIconSize)
                .height(size.middlIconSize)
                .onClick(this.onSend)
            }

          }
          .width(size.middleAvaterSize)
          .height(size.middleAvaterSize)
          .borderRadius(size.middleAvaterSize)
          .backgroundColor(colors.pageBackgroundColor)
          .alignItems(VerticalAlign.Center)
          .justifyContent(FlexAlign.Center)
        }
        .backgroundColor(colors.blockColor)
        .padding(size.pagePadding)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .backgroundColor(colors.pageBackgroundColor)

    }.width("100%").height("100%")
  }
}