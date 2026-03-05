package com.company.assembleegameclient.objects
{
   import com.company.assembleegameclient.game.GameSprite; //editor8182381
   import com.company.assembleegameclient.ui.panels.Panel; //editor8182381
   import com.company.assembleegameclient.ui.tooltip.TextToolTip;
   import com.company.assembleegameclient.ui.tooltip.ToolTip;
   import flash.display.BitmapData;
   import kabam.rotmg.vault.VaultPanel; //editor8182381

   public class ClosedVaultChest extends SellableObject
   {


      public function ClosedVaultChest(objectXML:XML)
      {
         super(objectXML);
      }

      override public function soldObjectName() : String
      {
         return "Vault Chest";
      }

      override public function soldObjectInternalName() : String
      {
         return "Vault Chest";
      }

      override public function getTooltip() : ToolTip
      {
         var toolTip:ToolTip = new TextToolTip(3552822,10197915,this.soldObjectName(),"Opens your Vault Storage with organized sections.",200); //editor8182381 — CHANGED: tooltip text
         return toolTip;
      }

      override public function getIcon() : BitmapData
      {
         return ObjectLibrary.getRedrawnTextureFromType(ObjectLibrary.idToType_["Vault Chest"],55,true);
      }

      //editor8182381 — CHANGED: return VaultPanel instead of SellableObjectPanel
      override public function getPanel(gs:GameSprite) : Panel
      {
         return new VaultPanel(gs);
      }
   }
}
