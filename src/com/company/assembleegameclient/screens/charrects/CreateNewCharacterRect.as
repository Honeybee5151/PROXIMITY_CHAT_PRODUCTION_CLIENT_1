package com.company.assembleegameclient.screens.charrects
{
   import com.company.ui.SimpleText;
   import flash.filters.DropShadowFilter;
   import kabam.rotmg.core.model.PlayerModel;

   //editor8182381 — Classless: removed rank icons and class quest text
   public class CreateNewCharacterRect extends CharacterRect
   {
      private var classNameText_:SimpleText;

      public function CreateNewCharacterRect(model:PlayerModel)
      {
         super(5526612,7829367);
         makeContainer();
         this.classNameText_ = new SimpleText(18,16777215,false,0,0);
         this.classNameText_.setBold(true);
         this.classNameText_.text = "New Character";
         this.classNameText_.updateMetrics();
         this.classNameText_.filters = [new DropShadowFilter(0,0,0,1,8,8)];
         this.classNameText_.x = 12;
         this.classNameText_.y = 14;
         selectContainer.addChild(this.classNameText_);
      }
   }
}
