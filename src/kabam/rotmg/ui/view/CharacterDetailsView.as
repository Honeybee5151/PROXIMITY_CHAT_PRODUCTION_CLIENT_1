package kabam.rotmg.ui.view
{
   import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.ui.BoostPanelButton;
import com.company.assembleegameclient.ui.ExperienceBoostTimerPopup;
import com.company.assembleegameclient.ui.IconButton;
   import com.company.ui.SimpleText;
   import com.company.util.AssetLibrary;
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


      private var button:IconButton;

      private var nameText_:SimpleText;

      private var nexusClicked:NativeSignal;

      private var optionsClicked:NativeSignal;

      public var gotoNexus:Signal;

      public var gotoOptions:Signal;

      private var boostPanelButton:BoostPanelButton;

      private var expTimer:ExperienceBoostTimerPopup;

      private var dashShape_:Shape;
      private static const DASH_COOLDOWN_MS:int = 5000;
      private static const DASH_X:Number = 2;
      private static const DASH_Y:Number = -2;
      private static const DASH_SIZE:Number = 28;

      public function CharacterDetailsView()
      {
         this.nameText_ = new SimpleText(20,11776947,false,0,0);
         this.nexusClicked = new NativeSignal(this.button,MouseEvent.CLICK);
         this.optionsClicked = new NativeSignal(this.button,MouseEvent.CLICK);
         this.gotoNexus = new Signal();
         this.gotoOptions = new Signal();
         super();
      }

      public function init(playerName:String, buttonType:String) : void
      {
         this.createDashCircle();
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

      private function createDashCircle() : void
      {
         this.dashShape_ = new Shape();
         addChild(this.dashShape_);
      }

      private function createNameText(name:String) : void
      {
         this.nameText_.setBold(true);
         this.nameText_.y = 0;
         this.nameText_.filters = [new DropShadowFilter(0,0,0)];
         addChild(this.nameText_);
         fitName(name);
      }

      private function fitName(name:String) : void
      {
         var maxW:int = 136;
         var fontSize:int = 20;
         this.nameText_.setSize(fontSize);
         this.nameText_.text = name;
         this.nameText_.updateMetrics();
         while (this.nameText_.width > maxW && fontSize > 10)
         {
            fontSize--;
            this.nameText_.setSize(fontSize);
            this.nameText_.text = name;
            this.nameText_.updateMetrics();
         }
         this.nameText_.x = 36 + (maxW - this.nameText_.width) / 2;
      }

      public function update(player:Player) : void
      {
      }

      public function draw(_arg1:Player):void {
         if (this.expTimer) {
            this.expTimer.update(_arg1.xpTimer);
         }
         drawDashCircle(_arg1);
         if (_arg1.dropBoost) {
            this.boostPanelButton = ((this.boostPanelButton) || (new BoostPanelButton(_arg1)));
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
               this.nameText_.x = 36 + (136 - this.nameText_.width) / 2;
            }
         }
      }

      private function drawDashCircle(player:Player) : void
      {
         if (this.dashShape_ == null) return;
         var g:* = this.dashShape_.graphics;
         g.clear();

         var sx:Number = DASH_X;
         var sy:Number = DASH_Y;
         var s:Number = DASH_SIZE;

         var now:int = getTimer();
         var remaining:int = player.dashCooldownEnd_ - now;
         var progress:Number = remaining <= 0 ? 1.0 : 1.0 - (remaining / Number(DASH_COOLDOWN_MS));
         if (progress > 1.0) progress = 1.0;
         if (progress < 0) progress = 0;

         // Background square (dark)
         g.beginFill(0x222222, 0.6);
         g.drawRect(sx, sy, s, s);
         g.endFill();

         // Progress fill (blue, bottom to top)
         if (progress > 0)
         {
            var ready:Boolean = progress >= 1.0;
            var alpha:Number = ready ? 0.7 + 0.3 * Math.abs(Math.sin(now / 400)) : 0.9;
            var color:uint = ready ? 0x80D0FF : 0x60B0E0;
            var fillH:Number = progress * s;

            g.beginFill(color, alpha);
            g.drawRect(sx, sy + s - fillH, s, fillH);
            g.endFill();
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
         fitName(name);
      }
   }
}
