package com.company.assembleegameclient.screens
{
   import com.company.assembleegameclient.appengine.SavedCharactersList;
   import com.company.assembleegameclient.objects.ObjectLibrary;
   import com.company.assembleegameclient.ui.LineBreakDesign;
   import com.company.ui.SimpleText;

   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Graphics;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.DropShadowFilter;
   import flash.geom.ColorTransform;

   import kabam.rotmg.core.model.PlayerModel;
   import kabam.rotmg.game.view.CreditDisplay;
   import kabam.rotmg.ui.view.components.ScreenBase;
   import org.osflash.signals.Signal;

   public class NewCharacterScreen extends Sprite
   {
      private var backButton_:TitleMenuOption;
      private var creditDisplay_:CreditDisplay;
      private var boxes_:Object;
      public var tooltip:Signal;
      public var close:Signal;
      public var selected:Signal;
      private var title:SimpleText;
      private var graphic:Sprite;
      private var lines:Sprite;
      private var container:Sprite;
      private var progressionContainer:Sprite;

      private var isInitialized:Boolean = false;

      // Honor progression fields
      private var currentPortrait:Bitmap;
      private var nextPortrait:Bitmap;
      private var currentTitleText:SimpleText;
      private var nextTitleText:SimpleText;
      private var currentLabel:SimpleText;
      private var nextLabel:SimpleText;
      private var arrowText:SimpleText;
      private var honorText:SimpleText;
      private var progressBarBg:Shape;
      private var progressBarFill:Shape;
      private var selectLabel:SimpleText;
      private var divider1:LineBreakDesign;

      public function NewCharacterScreen()
      {
         this.boxes_ = {};
         super();
         this.tooltip = new Signal(Sprite);
         this.selected = new Signal(int);
         this.close = new Signal();
         addChild(new ScreenBase());
         addChild(new AccountScreen());
      }

      private function makeBar():Sprite
      {
         var box:Sprite = new Sprite();
         var b:Graphics = box.graphics;
         b.clear();
         b.beginFill(0, 0.5);
         b.drawRect(0, 0, 800, 75);
         b.endFill();
         addChild(box);
         return box;
      }

      private function makeTitleText() : void
      {
         this.title = new SimpleText(32,11776947,false,0,0);
         this.title.setBold(true);
         this.title.text = "Titles of Honor";
         this.title.updateMetrics();
         this.title.filters = [new DropShadowFilter(0,0,0,1,8,8)];
         this.title.x = 400 - this.title.width / 2;
         this.title.y = 24;
         addChild(this.title);
      }

      private function positionButtons(e:Event = null) : void
      {
         if (e != null)
         {
            ScreenBase.reSize(e);
            AccountScreen.reSize(e);
         }

         var width:int = WebMain.STAGE.stageWidth;
         var height:int = WebMain.STAGE.stageHeight;
         this.lines.width = width;
         this.graphic.width = width;
         this.graphic.y = height - 75;
         this.container.x = (width / 2) - (this.container.width / 2);
         this.progressionContainer.x = (width / 2) - 340;
         this.creditDisplay_.x = width;
         this.title.x = (width / 2) - (this.title.width / 2);
         this.backButton_.x = (width / 2) - (this.backButton_.width / 2);
         this.backButton_.y = height - 70;
      }

      private function drawLines():Sprite
      {
         var box:Sprite = new Sprite();
         var b:Graphics = box.graphics;
         b.clear();
         b.lineStyle(2,6184542);
         b.moveTo(0,100);
         b.lineTo(800,100);
         b.lineStyle();
         addChild(box);
         return box;
      }

      private function makeTitleIcon(rankIndex:int, size:int = 80) : Bitmap
      {
         var bd:BitmapData = TitleIcons.getIcon(rankIndex, size);
         var portrait:Bitmap = new Bitmap(bd);
         return portrait;
      }

      private function buildProgressionUI() : void
      {
         this.progressionContainer = new Sprite();

         // TODO: Replace with actual honor stat from server
         var honorLevel:int = 0;
         var totalTitles:int = ObjectLibrary.playerChars_.length;
         var currentIndex:int = Math.min(honorLevel, totalTitles - 1);
         var nextIndex:int = Math.min(honorLevel + 1, totalTitles - 1);
         var isMaxRank:Boolean = (honorLevel >= totalTitles - 1);
         var honorForNext:int = honorLevel + 1;

         var currentXML:XML = ObjectLibrary.playerChars_[currentIndex];
         var nextXML:XML = ObjectLibrary.playerChars_[nextIndex];

         var centerX:Number = 340;
         var sectionY:Number = 0;

         // --- Current title section (left side) ---
         var currentBox:Sprite = new Sprite();
         var cbg:Graphics = currentBox.graphics;
         cbg.beginFill(0x1a1a2e, 0.8);
         cbg.lineStyle(1, 0x5e548e);
         cbg.drawRoundRect(0, 0, 140, 160, 8, 8);
         cbg.endFill();

         this.currentLabel = new SimpleText(11, 0x8a8a8a, false, 0, 0);
         this.currentLabel.text = "CURRENT TITLE";
         this.currentLabel.updateMetrics();
         this.currentLabel.filters = [new DropShadowFilter(0,0,0)];
         this.currentLabel.x = 70 - this.currentLabel.width / 2;
         this.currentLabel.y = 8;
         currentBox.addChild(this.currentLabel);

         this.currentPortrait = makeTitleIcon(currentIndex, 72);
         this.currentPortrait.x = 70 - this.currentPortrait.width / 2;
         this.currentPortrait.y = 28;
         currentBox.addChild(this.currentPortrait);

         this.currentTitleText = new SimpleText(16, 0xDAA520, false, 0, 0);
         this.currentTitleText.setBold(true);
         this.currentTitleText.text = String(currentXML.@id);
         this.currentTitleText.updateMetrics();
         this.currentTitleText.filters = [new DropShadowFilter(0,0,0)];
         this.currentTitleText.x = 70 - this.currentTitleText.width / 2;
         this.currentTitleText.y = 108;
         currentBox.addChild(this.currentTitleText);

         var currentRankText:SimpleText = new SimpleText(11, 0x6a6a6a, false, 0, 0);
         currentRankText.text = "Rank " + (currentIndex + 1) + " of " + totalTitles;
         currentRankText.updateMetrics();
         currentRankText.filters = [new DropShadowFilter(0,0,0)];
         currentRankText.x = 70 - currentRankText.width / 2;
         currentRankText.y = 130;
         currentBox.addChild(currentRankText);

         currentBox.x = centerX - 170 - 70;
         currentBox.y = sectionY;
         this.progressionContainer.addChild(currentBox);

         // --- Arrow ---
         this.arrowText = new SimpleText(36, 0x5e548e, false, 0, 0);
         this.arrowText.setBold(true);
         this.arrowText.text = "\u25BA";
         this.arrowText.updateMetrics();
         this.arrowText.filters = [new DropShadowFilter(0,0,0)];
         this.arrowText.x = centerX - this.arrowText.width / 2;
         this.arrowText.y = sectionY + 65;
         this.progressionContainer.addChild(this.arrowText);

         // --- Next title section (right side) ---
         var nextBox:Sprite = new Sprite();
         var nbg:Graphics = nextBox.graphics;
         nbg.beginFill(0x1a1a2e, 0.6);
         nbg.lineStyle(1, 0x3a3a5e);
         nbg.drawRoundRect(0, 0, 140, 160, 8, 8);
         nbg.endFill();

         this.nextLabel = new SimpleText(11, 0x8a8a8a, false, 0, 0);
         if (isMaxRank)
         {
            this.nextLabel.text = "MAX RANK";
         }
         else
         {
            this.nextLabel.text = "NEXT TITLE";
         }
         this.nextLabel.updateMetrics();
         this.nextLabel.filters = [new DropShadowFilter(0,0,0)];
         this.nextLabel.x = 70 - this.nextLabel.width / 2;
         this.nextLabel.y = 8;
         nextBox.addChild(this.nextLabel);

         this.nextPortrait = makeTitleIcon(nextIndex, 72);
         this.nextPortrait.x = 70 - this.nextPortrait.width / 2;
         this.nextPortrait.y = 28;
         if (!isMaxRank)
         {
            this.nextPortrait.transform.colorTransform = new ColorTransform(0.6, 0.6, 0.7);
         }
         nextBox.addChild(this.nextPortrait);

         this.nextTitleText = new SimpleText(16, 0x9090b0, false, 0, 0);
         this.nextTitleText.setBold(true);
         if (isMaxRank)
         {
            this.nextTitleText.text = String(currentXML.@id);
            this.nextTitleText.textColor = 0xDAA520;
         }
         else
         {
            this.nextTitleText.text = String(nextXML.@id);
         }
         this.nextTitleText.updateMetrics();
         this.nextTitleText.filters = [new DropShadowFilter(0,0,0)];
         this.nextTitleText.x = 70 - this.nextTitleText.width / 2;
         this.nextTitleText.y = 108;
         nextBox.addChild(this.nextTitleText);

         if (!isMaxRank)
         {
            var reqText:SimpleText = new SimpleText(11, 0x6a8a6a, false, 0, 0);
            reqText.text = "Honor " + honorForNext + " required";
            reqText.updateMetrics();
            reqText.filters = [new DropShadowFilter(0,0,0)];
            reqText.x = 70 - reqText.width / 2;
            reqText.y = 130;
            nextBox.addChild(reqText);
         }
         else
         {
            var maxText:SimpleText = new SimpleText(11, 0xDAA520, false, 0, 0);
            maxText.text = "Highest Honor";
            maxText.updateMetrics();
            maxText.filters = [new DropShadowFilter(0,0,0)];
            maxText.x = 70 - maxText.width / 2;
            maxText.y = 130;
            nextBox.addChild(maxText);
         }

         nextBox.x = centerX + 170 - 70;
         nextBox.y = sectionY;
         this.progressionContainer.addChild(nextBox);

         // --- Honor progress bar ---
         var barY:Number = sectionY + 175;
         var barWidth:Number = 300;
         var barHeight:Number = 14;
         var barX:Number = centerX - barWidth / 2;

         this.progressBarBg = new Shape();
         var bgG:Graphics = this.progressBarBg.graphics;
         bgG.beginFill(0x2a2a3e, 1);
         bgG.lineStyle(1, 0x3a3a5e);
         bgG.drawRoundRect(barX, barY, barWidth, barHeight, 6, 6);
         bgG.endFill();
         this.progressionContainer.addChild(this.progressBarBg);

         this.progressBarFill = new Shape();
         var fillG:Graphics = this.progressBarFill.graphics;
         var fillWidth:Number = isMaxRank ? barWidth : (barWidth * (honorLevel / honorForNext));
         if (fillWidth > 2)
         {
            fillG.beginFill(0xDAA520, 1);
            fillG.drawRoundRect(barX, barY, fillWidth, barHeight, 6, 6);
            fillG.endFill();
         }
         this.progressionContainer.addChild(this.progressBarFill);

         this.honorText = new SimpleText(13, 0xcccccc, false, 0, 0);
         if (isMaxRank)
         {
            this.honorText.text = "Honor: MAX";
         }
         else
         {
            this.honorText.text = "Honor: " + honorLevel + " / " + honorForNext;
         }
         this.honorText.updateMetrics();
         this.honorText.filters = [new DropShadowFilter(0,0,0)];
         this.honorText.x = centerX - this.honorText.width / 2;
         this.honorText.y = barY + barHeight + 6;
         this.progressionContainer.addChild(this.honorText);

         // --- Divider ---
         this.divider1 = new LineBreakDesign(500, 0x333333);
         this.divider1.x = centerX - 250;
         this.divider1.y = barY + barHeight + 32;
         this.progressionContainer.addChild(this.divider1);

         // --- Select label ---
         this.selectLabel = new SimpleText(14, 0x8a8a8a, false, 0, 0);
         this.selectLabel.text = "Select a title to play";
         this.selectLabel.updateMetrics();
         this.selectLabel.filters = [new DropShadowFilter(0,0,0)];
         this.selectLabel.x = centerX - this.selectLabel.width / 2;
         this.selectLabel.y = barY + barHeight + 42;
         this.progressionContainer.addChild(this.selectLabel);

         this.progressionContainer.y = 110;
         addChild(this.progressionContainer);
      }

      public function initialize(model:PlayerModel) : void
      {
         var playerXML:XML = null;
         var objectType:int = 0;
         var characterType:String = null;
         var overrideIsAvailable:Boolean = false;
         var charBox:CharacterBox = null;
         if(this.isInitialized)
         {
            return;
         }
         this.isInitialized = true;
         this.makeTitleText();
         this.creditDisplay_ = new CreditDisplay();
         this.creditDisplay_.draw(model.getCredits(),model.getFame());
         addChild(this.creditDisplay_);
         this.creditDisplay_.y = 32;

         // Build honor progression UI
         this.buildProgressionUI();

         // Calculate grid offset based on progression UI height
         var gridY:Number = this.progressionContainer.y + this.progressionContainer.height + 10;

         this.container = new Sprite();
         addChild(this.container);
         for(var i:int = 0; i < ObjectLibrary.playerChars_.length; i++)
         {
            playerXML = ObjectLibrary.playerChars_[i];
            objectType = int(playerXML.@type);
            characterType = playerXML.@id;
            if(!model.isClassAvailability(characterType,SavedCharactersList.UNAVAILABLE))
            {
               overrideIsAvailable = model.isClassAvailability(characterType,SavedCharactersList.UNRESTRICTED);
               charBox = new CharacterBox(playerXML,model.getCharStats()[objectType],model,overrideIsAvailable);
               charBox.x = 100 * int(i % 8);
               charBox.y = gridY + 100 * int(i / 8);
               charBox.scaleX = 0.83;
               charBox.scaleY = 0.83;
               this.boxes_[objectType] = charBox;
               charBox.addEventListener(MouseEvent.ROLL_OVER,this.onCharBoxOver);
               charBox.addEventListener(MouseEvent.ROLL_OUT,this.onCharBoxOut);
               charBox.characterSelectClicked_.add(this.onCharBoxClick);
               this.container.addChild(charBox);
            }
         }

         this.lines = drawLines();
         addChild(this.lines);

         // Bottom bar and back button added LAST so they render on top of classes
         this.graphic = this.makeBar();
         addChild(this.graphic);
         this.backButton_ = new TitleMenuOption("back",36,false);
         this.backButton_.addEventListener(MouseEvent.CLICK,this.onBackClick);
         addChild(this.backButton_);

         this.positionButtons();
         if (WebMain.STAGE)
             WebMain.STAGE.addEventListener(Event.RESIZE, positionButtons);
      }

      private function onBackClick(event:Event) : void
      {
         this.close.dispatch();
      }

      private function onCharBoxOver(event:MouseEvent) : void
      {
         var charBox:CharacterBox = event.currentTarget as CharacterBox;
         charBox.setOver(true);
         this.tooltip.dispatch(charBox.getTooltip());
      }

      private function onCharBoxOut(event:MouseEvent) : void
      {
         var charBox:CharacterBox = event.currentTarget as CharacterBox;
         charBox.setOver(false);
         this.tooltip.dispatch(null);
      }

      private function onCharBoxClick(event:MouseEvent) : void
      {
         this.tooltip.dispatch(null);
         var charBox:CharacterBox = event.currentTarget.parent as CharacterBox;
         if(!charBox.available_)
         {
            return;
         }
         var objectType:int = charBox.objectType();
         var displayId:String = ObjectLibrary.typeToDisplayId_[objectType];
         this.selected.dispatch(objectType);
      }

      public function updateCreditsAndFame(credits:int, fame:int) : void
      {
         this.creditDisplay_.draw(credits,fame);
      }

      public function update(model:PlayerModel) : void
      {
         var playerXML:XML = null;
         var objectType:int = 0;
         var characterType:String = null;
         var overrideIsAvailable:Boolean = false;
         var charBox:CharacterBox = null;
         for(var i:int = 0; i < ObjectLibrary.playerChars_.length; i++)
         {
            playerXML = ObjectLibrary.playerChars_[i];
            objectType = int(playerXML.@type);
            characterType = String(playerXML.@id);
            if(!model.isClassAvailability(characterType,SavedCharactersList.UNAVAILABLE))
            {
               overrideIsAvailable = model.isClassAvailability(characterType,SavedCharactersList.UNRESTRICTED);
               charBox = this.boxes_[objectType];
               if(charBox)
               {
                  if(overrideIsAvailable || model.isLevelRequirementsMet(objectType))
                  {
                     charBox.unlock();
                  }
               }
            }
         }
      }
   }
}
