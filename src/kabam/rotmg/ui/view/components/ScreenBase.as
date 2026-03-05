package kabam.rotmg.ui.view.components
{
   import com.company.assembleegameclient.ui.SoundIcon;
   import flash.display.Sprite;
import flash.events.Event;
import flash.media.Sound;

import kabam.rotmg.ui.view.TitleView_TitleScreenBackground;

import mx.core.BitmapAsset;

public class ScreenBase extends Sprite
   {
      private static var graphic:BitmapAsset;
      public function ScreenBase()
      {
         super();
         graphic = new TitleView_TitleScreenBackground();
         fitBackground(); //editor8182381 — CHANGED: cover-fit instead of 800/600 stretch
         addChild(graphic);
         //editor8182381 — DELETED: removed SoundIcon from loading screen
      }

      //editor8182381 — CHANGED: cover-fit scaling to match TitleView
      private static function fitBackground():void
      {
         if (WebMain.STAGE)
         {
            var bgW:Number = graphic.bitmapData.width;
            var bgH:Number = graphic.bitmapData.height;
            var s:Number = Math.max(WebMain.STAGE.stageWidth / bgW, WebMain.STAGE.stageHeight / bgH);
            graphic.scaleX = s;
            graphic.scaleY = s;
            graphic.x = (WebMain.STAGE.stageWidth - bgW * s) / 2;
            graphic.y = WebMain.STAGE.stageHeight - bgH * s; //editor8182381 — anchor to bottom
         }
      }

      public static function reSize(e:Event):void
      {
         fitBackground(); //editor8182381
      }
   }
}
