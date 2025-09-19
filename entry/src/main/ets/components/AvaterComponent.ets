import { HOST, USER_DATA } from '../common/constant';

@Component
export default struct AvaterComponent {
  @Prop avater: string|undefined;
  @Prop dimensions: number;

  build() {
    Image(this.avater !== undefined ? HOST + this.avater : $r('app.media.default_avater'))
      .height(this.dimensions)
      .width(this.dimensions)
      .borderRadius(this.dimensions)
  }
}