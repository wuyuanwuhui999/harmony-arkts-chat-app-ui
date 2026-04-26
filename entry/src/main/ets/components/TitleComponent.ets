import * as colors from '../theme/color';
import * as size from '../theme/size';


@Component
export default struct TitleComponent{
  @Prop title:string;
  @Prop showMarginBottom:boolean;

  build(){
    Row(){
      Divider()
        .height(size.lineHeight)
        .width(size.lineWidth)
        .margin({right:size.smallGap})
      Text(this.title).fontSize(size.middleFont)
    }.alignSelf(ItemAlign.Start)
    .margin({bottom:this.showMarginBottom ? size.middleGap : 0})
  }
}