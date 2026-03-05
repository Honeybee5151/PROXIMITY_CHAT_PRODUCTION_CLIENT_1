package kabam.rotmg.ui.view
{
import com.company.assembleegameclient.screens.AccountScreen;
import com.company.assembleegameclient.ui.SoundIcon;
import com.company.ui.SimpleText;

import flash.display.Bitmap;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.text.TextFieldAutoSize;

import kabam.rotmg.ui.model.EnvironmentData;
import org.osflash.signals.Signal;

//editor8182381 — CHANGED: removed play/servers/account buttons and bottom bar, click background to play
public class TitleView extends Sprite
{
   private static const COPYRIGHT:String = "© betterSkillys :)";

   public var playClicked:Signal;
   public var accountClicked:Signal;
   public var serversClicked:Signal;
   public var creditsClicked:Signal;

   private var container:Sprite;
   private var parallaxLayers:Vector.<Bitmap>;

   private var versionText:SimpleText;
   private var copyrightText:SimpleText;
   private var clickToPlayText:SimpleText; //editor8182381
   private var data:EnvironmentData;
   public static var proximityChatChecker:Boolean = false;

   public function TitleView()
   {
      super();
      this.initLayers();
      addChild(new AccountScreen());
      this.makeChildren();
      addChild(new SoundIcon());
   }

   public function initLayers():void
   {
      this.parallaxLayers = new Vector.<Bitmap>();
      this.parallaxLayers[0] = new TitleView_BackgroundLayer();
      this.parallaxLayers[0].x = 0;
      this.parallaxLayers[0].y = 0;
      addChild(this.parallaxLayers[0]);
   }

   private function makeChildren():void
   {
      this.container = new Sprite();

      //editor8182381 — signals (playClicked dispatched on background click)
      this.playClicked = new Signal();
      this.accountClicked = new Signal();
      this.serversClicked = new Signal();
      this.creditsClicked = new Signal();

      //editor8182381 — "Click to play" hint
      this.clickToPlayText = new SimpleText(28, 0xFFFFFF, false, 0, 0);
      this.clickToPlayText.setBold(true);
      this.clickToPlayText.setText("Click to Play");
      this.clickToPlayText.autoSize = TextFieldAutoSize.LEFT;
      this.clickToPlayText.filters = [new DropShadowFilter(0, 0, 0, 1, 8, 8)];
      this.clickToPlayText.updateMetrics();
      this.clickToPlayText.alpha = 0.7;
      this.clickToPlayText.mouseEnabled = false;
      this.container.addChild(this.clickToPlayText);

      this.versionText = new SimpleText(12, 0xaaaaaa, false, 0, 0);
      this.versionText.filters = [new DropShadowFilter(0, 0, 0)];
      //editor8182381 — DELETED: removed version text from title screen

      this.copyrightText = new SimpleText(12, 0xaaaaaa, false, 0, 0);
      this.copyrightText.text = COPYRIGHT;
      this.copyrightText.updateMetrics();
      this.copyrightText.filters = [new DropShadowFilter(0, 0, 0)];
      this.container.addChild(this.copyrightText);
   }

   public function addListeners():void
   {
      //editor8182381 — click background to play
      if (stage)
         stage.addEventListener(MouseEvent.CLICK, onBackgroundClick);
   }

   private function onBackgroundClick(e:MouseEvent):void
   {
      //editor8182381 — only dispatch if clicking background/container, not dialogs or UI elements
      if (e.target == stage || e.target == this.parallaxLayers[0] || e.target == this.clickToPlayText || e.target == this.container)
      {
         this.playClicked.dispatch();
      }
   }

   public function removeListener(e:Event):void
   {
      if (stage)
      {
         stage.removeEventListener("resize", positionButtons);
         stage.removeEventListener(MouseEvent.CLICK, onBackgroundClick);
      }
   }

   public function initialize(data:EnvironmentData):void
   {
      this.data = data;
      this.positionButtons();
      this.addChildren();
      this.addListeners();
      if (stage)
         stage.addEventListener("resize", positionButtons);
   }

   private function updateVersionText():void
   {
      this.versionText.htmlText = this.data.buildLabel;
      this.versionText.updateMetrics();
   }

   private function addChildren():void
   {
      addChild(this.container);
   }

   public function positionButtons(e:Event = null):void
   {
      if (stage)
      {
         if (e != null)
            AccountScreen.reSize(e);

         //editor8182381 — scale background to cover
         var bgW:Number = this.parallaxLayers[0].bitmapData.width;
         var bgH:Number = this.parallaxLayers[0].bitmapData.height;
         var fitScale:Number = Math.max(stage.stageWidth / bgW, stage.stageHeight / bgH);
         this.parallaxLayers[0].scaleX = fitScale;
         this.parallaxLayers[0].scaleY = fitScale;
         this.parallaxLayers[0].x = (stage.stageWidth - bgW * fitScale) / 2;
         this.parallaxLayers[0].y = stage.stageHeight - bgH * fitScale; //editor8182381 — CHANGED: anchor to bottom so floor is always visible

         //editor8182381 — center "Click to Play" text
         this.clickToPlayText.x = stage.stageWidth / 2 - this.clickToPlayText.width / 2;
         this.clickToPlayText.y = stage.stageHeight / 2 - this.clickToPlayText.height / 2;

         this.copyrightText.x = stage.stageWidth - this.copyrightText.width;
         this.copyrightText.y = stage.stageHeight - this.copyrightText.height;
      }
   }
}
}
