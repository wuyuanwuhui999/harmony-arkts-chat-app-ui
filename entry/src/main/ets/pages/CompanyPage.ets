// ets/pages/CompanyPage.ets
import * as colors from '../theme/color';
import * as size from '../theme/size';
import router from '@ohos.router';
import { CompanyType, UserDataType } from '../type/Index';
import { USER_DATA, COMPANY_ID, COMPANY_DATA } from '../common/constant';
import { getCompanyListService } from '../service/Index';
import { display, promptAction } from '@kit.ArkUI';
import preference from '../utils/PreferenceModel';
import GlobalLoading from '../components/GlobalLoading';
import LoadingController from '../controller/LoadingController';

@Entry
@Component
struct CompanyPage {
  @StorageLink(USER_DATA) userData: UserDataType = {} as UserDataType;
  @State companyList: CompanyType[] = [];
  @State selectedCompanyId: string = '';
  @State loading: boolean = false;
  private loadingController: LoadingController = new LoadingController();

  aboutToAppear() {
    // 从缓存获取已选择的公司ID
    this.getCachedCompanyId();
    // 加载公司列表
    this.loadCompanyList();
  }

  /**
   * @description: 从缓存获取公司ID
   * @date: 2026-06-25
   * @author wuwenqiang
   */
  async getCachedCompanyId() {
    const userId = this.userData.id;
    if (userId) {
      const cachedId = await preference.getPreference(`${userId}:${COMPANY_ID}`);
      if (cachedId) {
        this.selectedCompanyId = cachedId;
      }
    }
  }

  /**
   * @description: 加载公司列表
   * @date: 2026-06-25
   * @author wuwenqiang
   */
  loadCompanyList() {
    this.loadingController.showLoading();
    getCompanyListService().then((res) => {
      this.companyList = res.data || [];
      // 如果缓存中有companyId，并且能在列表中找到，则自动选中
      if (this.selectedCompanyId) {
        const found = this.companyList.some(item => item.id === this.selectedCompanyId);
        if (!found) {
          this.selectedCompanyId = '';
        }
      }
    }).catch((err: Error) => {
      console.error('获取公司列表失败:', JSON.stringify(err));
      promptAction.showToast({
        message: '获取公司列表失败，请重试',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
    }).finally(() => {
      this.loadingController.hideLoading();
    });
  }

  /**
   * @description: 选择公司
   * @date: 2026-06-25
   * @author wuwenqiang
   */
  selectCompany(companyId: string) {
    this.selectedCompanyId = companyId;
  }

  /**
   * @description: 确定选择，跳转到ChatPage
   * @date: 2026-06-25
   * @author wuwenqiang
   */
  async confirmSelection() {
    if (!this.selectedCompanyId) {
      return;
    }

    // 查找选中的公司
    const selectedCompany = this.companyList.find(item => item.id === this.selectedCompanyId);
    if (!selectedCompany) {
      promptAction.showToast({
        message: '请选择有效的公司',
        duration: 2000,
        bottom: px2vp(display.getDefaultDisplaySync().height) / 2
      });
      return;
    }

    // 保存公司ID到缓存（带userId）
    const userId = this.userData.id;
    if (userId) {
      await preference.putPreference(`${userId}:${COMPANY_ID}`, this.selectedCompanyId);
    }
    // 保存公司信息到全局
    AppStorage.SetOrCreate<CompanyType>(COMPANY_DATA, selectedCompany);

    // 跳转到ChatPage
    router.replaceUrl({
      url: 'pages/ChatPage'
    });
  }

  @Styles
  blockStyle() {
    .backgroundColor(colors.white)
    .borderRadius(size.middleBorderRaduis)
    .padding(size.middleGap)
    .width('100%')
    .margin({ top: size.middleGap })
  }

  @Builder
  CompanyItem(item: CompanyType) {
    Row() {
      // 公司名称
      Text(item.name)
        .fontSize(size.middleFont)
        .fontColor(colors.black)
        .layoutWeight(1)

      // 单选按钮
      Stack({ alignContent: Alignment.Center }) {
        Circle({ width: size.middleIcon, height: size.middleIcon })
          .fill(this.selectedCompanyId === item.id ? colors.primary : Color.Transparent)
          .stroke(this.selectedCompanyId === item.id ? colors.primary : colors.gray)
          .strokeWidth(2)

        if (this.selectedCompanyId === item.id) {
          Circle({ width: size.smallIcon, height: size.smallIcon })
            .fill(colors.white)
        }
      }
    }
    .width('100%')
    .padding({
      top: size.middleGap,
      bottom: size.middleGap
    })
    .onClick(() => {
      this.selectCompany(item.id);
    })
  }

  build() {
    Stack() {
      Column() {
        // 标题栏
        Row() {
          Text('选择公司/个人空间')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding(size.middleGap)
        .backgroundColor(colors.white)

        // 内容区
        Column() {
          // 公司列表卡片
          Column({space: size.middleGap}) {
            ForEach(this.companyList, (item: CompanyType) => {
              this.CompanyItem(item)
            })
          }
          .blockStyle()
          .margin({ top: size.middleGap })

          // 底部确定按钮
          Row() {
            Text('确定')
              .width('100%')
              .height(size.btnHeight)
              .textAlign(TextAlign.Center)
              .fontColor(Color.White)
              .backgroundColor(this.selectedCompanyId ? colors.primary : colors.gray)
              .borderRadius(size.btnHeight / 2)
              .enabled(!!this.selectedCompanyId)
              .onClick(() => {
                if (this.selectedCompanyId) {
                  this.confirmSelection();
                }
              })
          }
          .width('100%')
          .padding({
            top: size.middleGap,
            bottom: size.middleGap
          })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(colors.pageBackground)
        .padding({
          left: size.middleGap,
          right: size.middleGap
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