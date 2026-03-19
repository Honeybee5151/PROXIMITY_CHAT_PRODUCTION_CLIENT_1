package kabam.rotmg.ui.view
{
   import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.ui.BoostPanelButton;
import com.company.assembleegameclient.ui.ExperienceBoostTimerPopup;
import com.company.assembleegameclient.ui.IconButton;
   import com.company.ui.SimpleText;
   import com.company.util.AssetLibrary;
   import flash.display.Bitmap;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.utils.getTimer;
   import org.osflash.signals.Signal;
   import org.osflash.signals.natives.NativeSignal;
   
   public class CharacterDetailsView extends Sprite
   {
      
      public static const NEXUS_BUTTON:String = "NEXUS_BUTTON";
      
      public static const OPTIONS_BUTTON:String = "OPTIONS_BUTTON";
       
      
      private var portrait_:Bitmap;
      
      private var button:IconButton;
      
      private var nameText_:SimpleText;
      
      private var nexusClicked:NativeSignal;
      
      private var optionsClicked:NativeSignal;
      
      public var gotoNexus:Signal;
      
      public var gotoOptions:Signal;

      private var boostPanelButton:BoostPanelButton;

      private var expTimer:ExperienceBoostTimerPopup;

      private var dashOverlay_:Shape;
      private static const DASH_COOLDOWN_MS:int = 5000;
      private static const DASH_RADIUS:Number = 16;
      private static const DASH_SEGMENTS:int = 36;
      
      public function CharacterDetailsView()
      {
         this.portrait_ = new Bitmap(null);
         this.nameText_ = new SimpleText(20,11776947,false,0,0);
         this.nexusClicked = new NativeSignal(this.button,MouseEvent.CLICK);
         this.optionsClicked = new NativeSignal(this.button,MouseEvent.CLICK);
         this.gotoNexus = new Signal();
         this.gotoOptions = new Signal();
         super();
      }
      
      public function init(playerName:String, buttonType:String) : void
      {
         this.createPortrait();
         this.createNameText(playerName);
         this.createButton(buttonType);
      }
      
      private function createButton(buttonType:String) : void
      {
         if(buttonType == NEXUS_BUTTON)
         {
            this.button = new IconButton(AssetLibrary.getImageFromSet("lofiInterfaceBig",6),"Nexus","escapeToNexus");
            this.nexusClicked = new NativeSignal(this.button,MouseEvent.CLICK,MouseEvent);
            this.nexusClicked.add(this.onNexusClick);
         }
         else if(buttonType == OPTIONS_BUTTON)
         {
            this.button = new IconButton(AssetLibrary.getImageFromSet("lofiInterfaceBig",5),"Options","options");
            this.optionsClicked = new NativeSignal(this.button,MouseEvent.CLICK,MouseEvent);
            this.optionsClicked.add(this.onOptionsClick);
         }
         this.button.x = 172;
         this.button.y = 4;
         addChild(this.button);
      }
      
      private function createPortrait() : void
      {
         this.portrait_.x = -2;
         this.portrait_.y = -8;
         addChild(this.portrait_);
         this.dashOverlay_ = new Shape();
         addChild(this.dashOverlay_);
      }
      
      private function createNameText(name:String) : void
      {
         this.nameText_.setBold(true);
         this.nameText_.y = 0;
         this.nameText_.filters = [new DropShadowFilter(0,0,0)];
         this.nameText_.text = name;
         this.nameText_.updateMetrics();
         this.nameText_.x = 36 + (136 - this.nameText_.width) / 2;
         addChild(this.nameText_);
      }
      
      public function update(player:Player) : void
      {
         this.portrait_.bitmapData = player.getPortrait();
      }

      public function draw(_arg1:Player):void {
         if (this.expTimer) {
            this.expTimer.update(_arg1.xpTimer);
         }
         drawDashCircle(_arg1);
         if (_arg1.dropBoost) {
            this.boostPanelButton = ((this.boostPanelButton) || (new BoostPanelButton(_arg1)));
            if (this.portrait_) {
               this.portrait_.x = 13;
            }
            if (this.nameText_) {
               this.nameText_.x = 47 + (125 - this.nameText_.width) / 2;
            }
            this.boostPanelButton.x = 6;
            this.boostPanelButton.y = 5;
            addChild(this.boostPanelButton);
         }
         else {
            if (this.boostPanelButton) {
               removeChild(this.boostPanelButton);
               this.boostPanelButton = null;
               this.portrait_.x = -2;
               this.nameText_.x = 36 + (136 - this.nameText_.width) / 2;
            }
         }
      }
      
      private function drawDashCircle(player:Player) : void
      {
         if (this.dashOverlay_ == null) return;
         this.dashOverlay_.graphics.clear();

         // Center the circle on the portrait
         var bd:* = this.portrait_.bitmapData;
         if (bd == null) return;
         var cx:Number = this.portrait_.x + bd.width / 2;
         var cy:Number = this.portrait_.y + bd.height / 2;
         var r:Number = DASH_RADIUS;

         var now:int = getTimer();
         var remaining:int = player.dashCooldownEnd_ - now;
         var progress:Number = remaining <= 0 ? 1.0 : 1.0 - (remaining / Number(DASH_COOLDOWN_MS));
         if (progress > 1.0) progress = 1.0;
         if (progress < 0) progress = 0;

         // Background ring (dark)
         this.dashOverlay_.graphics.lineStyle(3, 0x222222, 0.6);
         this.dashOverlay_.graphics.drawCircle(cx, cy, r);
         this.dashOverlay_.graphics.lineStyle();

         // Progress arc (blue, clockwise from top)
         if (progress > 0)
         {
            var arcEnd:Number = progress * Math.PI * 2;
            var segs:int = Math.max(3, int(progress * DASH_SEGMENTS));
            var ready:Boolean = progress >= 1.0;
            var alpha:Number = ready ? 0.7 + 0.3 * Math.abs(Math.sin(now / 400)) : 0.9;
            var color:uint = ready ? 0x80D0FF : 0x60B0E0;

            this.dashOverlay_.graphics.lineStyle(3, color, alpha);
            var startAngle:Number = -Math.PI / 2;
            this.dashOverlay_.graphics.moveTo(cx + Math.cos(startAngle) * r, cy + Math.sin(startAngle) * r);
            for (var i:int = 1; i <= segs; i++)
            {
               var angle:Number = startAngle + (i / Number(segs)) * arcEnd;
               this.dashOverlay_.graphics.lineTo(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
            }
            this.dashOverlay_.graphics.lineStyle();
         }
      }

      private function onNexusClick(event:MouseEvent) : void
      {
         this.gotoNexus.dispatch();
      }
      
      private function onOptionsClick(event:MouseEvent) : void
      {
         this.gotoOptions.dispatch();
      }
      
      public function setName(name:String) : void
      {
         this.nameText_.text = name;
         this.nameText_.updateMetrics();
         this.nameText_.x = 36 + (136 - this.nameText_.width) / 2;
      }
   }
}
