import httpRequest from '../utils/HttpUtil';
import deviceInfo from '@ohos.deviceInfo'; //设备信息
import { DeviceInterface, UserDataInterface } from '../interface/Index'
import preference from '../utils/PreferenceModel';
import { DEVICE_INFO, USER_DATA } from '../common/constant';
import { getUserDataService } from '../service/Index';
import router from '@ohos.router';

@Preview
@Entry
@Component
struct LaunchPage {
  @State activeIndex: number = 0;
  @State isInitPage: Array<boolean> = [true, false, false, false];
  @State isInitIndex: boolean = false;

  build() {
    Column() {
      Text('欢迎使用')
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
  }

  async aboutToAppear() {
    AppStorage.SetOrCreate<DeviceInterface>(DEVICE_INFO, {
      device: deviceInfo.productModel,
      platform: deviceInfo.marketName,
      version: deviceInfo.sdkApiVersion.toString(),
      musicId: null
    })
    const token: string = await preference.getToken() as string;
    setTimeout(() => { // 加载用户信息
      if (token) {
        getUserDataService(token).then((res) => {
          preference.setToken(res.token);
          httpRequest.setToken(res.token);
          AppStorage.SetOrCreate<UserDataInterface>(USER_DATA, res.data)
          router.replaceUrl({
            url: 'pages/ChatPage'
          });
        }).catch(() => {
          router.replaceUrl({
            url: 'pages/LoginPage'
          });
        })
      } else {
        router.replaceUrl({
          url: 'pages/LoginPage'
        });
      }

    }, 1000)

  }
}