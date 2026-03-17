package kabam.rotmg.classes.control
{
import kabam.rotmg.assets.EmbeddedData;
import kabam.rotmg.assets.model.CharacterTemplate;
   import kabam.rotmg.classes.model.CharacterClass;
   import kabam.rotmg.classes.model.CharacterSkin;
   import kabam.rotmg.classes.model.ClassesModel;
   
   public class ParseSkinsXmlCommand
   {
       
      
      [Inject]
      public var data:XML;
      
      [Inject]
      public var model:ClassesModel;
      
      public function ParseSkinsXmlCommand()
      {
         super();
      }
      
      public function execute() : void
      {
         var node:XML = EmbeddedData.skinsXML;
         var list:XMLList = node.children();
         for each(node in list)
         {
            this.parseNode(node);
         }
      }
      
      private function parseNode(xml:XML) : void
      {
         var file:String = xml.AnimatedTexture.File;
         var index:int = xml.AnimatedTexture.Index;
         var skin:CharacterSkin = new CharacterSkin();
         skin.id = xml.@type;
         skin.name = xml.@id;
         skin.unlockLevel = xml.UnlockLevel;
         skin.cost = xml.hasOwnProperty("Cost") ? int(xml.Cost) : 300; //editor8182381 — CHANGED: fix 0||300=300 bug
         skin.requiredRank = xml.hasOwnProperty("RequiredRank") ? int(xml.RequiredRank) : 0; //editor8182381 — CHANGED: fix 0||0 fallback
         skin.template = new CharacterTemplate(file,index);
         var classType:int = int(xml.PlayerClassType); //editor8182381 — explicit int cast to handle 0x hex strings
         var character:CharacterClass = this.model.getCharacterClass(classType);
         if (file.indexOf("16") >= 0)
         {
            skin.is16x16 = true;
         }
         character.skins.addSkin(skin);
      }
   }
}
