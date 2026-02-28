package com.company.assembleegameclient.ui.tooltip
{
   import com.company.assembleegameclient.appengine.CharacterStats;
   import com.company.assembleegameclient.ui.LineBreakDesign;
   import com.company.assembleegameclient.util.AnimatedChar;
   import com.company.assembleegameclient.util.AnimatedChars;
   import com.company.assembleegameclient.util.MaskedImage;
   import com.company.assembleegameclient.util.TextureRedrawer;
   import com.company.ui.SimpleText;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.filters.DropShadowFilter;
   import kabam.rotmg.core.model.PlayerModel;

   public class ClassToolTip extends ToolTip
   {


      private var portrait_:Bitmap;

      private var nameText_:SimpleText;

      private var descriptionText_:SimpleText;

      private var lineBreak_:LineBreakDesign;

      private var bestLevel_:SimpleText;

      public function ClassToolTip(playerXML:XML, model:PlayerModel, charStats:CharacterStats)
      {
         super(3552822,1,16777215,1);
         var animatedChar:AnimatedChar = AnimatedChars.getAnimatedChar(String(playerXML.AnimatedTexture.File),int(playerXML.AnimatedTexture.Index));
         var image:MaskedImage = animatedChar.imageFromDir(AnimatedChar.RIGHT,AnimatedChar.STAND,0);
         var size:int = 4 / image.width() * 100;
         var bd:BitmapData = TextureRedrawer.redraw(image.image_,size,true,0);
         this.portrait_ = new Bitmap();
         this.portrait_.bitmapData = bd;
         this.portrait_.x = -4;
         this.portrait_.y = -4;
         addChild(this.portrait_);
         this.nameText_ = new SimpleText(13,11776947,false,0,0);
         this.nameText_.setBold(true);
         this.nameText_.text = playerXML.@id;
         this.nameText_.updateMetrics();
         this.nameText_.filters = [new DropShadowFilter(0,0,0)];
         this.nameText_.x = 32;
         this.nameText_.y = 6;
         addChild(this.nameText_);
         this.descriptionText_ = new SimpleText(13,11776947,false,174,0);
         this.descriptionText_.wordWrap = true;
         this.descriptionText_.multiline = true;
         this.descriptionText_.text = playerXML.Description;
         this.descriptionText_.updateMetrics();
         this.descriptionText_.filters = [new DropShadowFilter(0,0,0)];
         this.descriptionText_.x = 8;
         this.descriptionText_.y = 40;
         addChild(this.descriptionText_);
         this.lineBreak_ = new LineBreakDesign(100,0x151515);
         this.lineBreak_.x = 6;
         this.lineBreak_.y = height;
         addChild(this.lineBreak_);
         this.bestLevel_ = new SimpleText(14,6206769,false,0,0);
         this.bestLevel_.text = "Best Level Achieved: " + (charStats != null?charStats.bestLevel():0) + "\n" + "Best Fame Achieved: " + (charStats != null?charStats.bestFame():0);
         this.bestLevel_.updateMetrics();
         this.bestLevel_.filters = [new DropShadowFilter(0,0,0)];
         this.bestLevel_.x = 8;
         this.bestLevel_.y = height - 2;
         addChild(this.bestLevel_);
      }
      
      override public function draw() : void
      {
         this.lineBreak_.setWidthColor(width - 10,1842204);
         super.draw();
      }
   }
}
