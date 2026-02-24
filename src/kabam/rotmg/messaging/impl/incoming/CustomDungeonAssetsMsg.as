package kabam.rotmg.messaging.impl.incoming
{
   import flash.utils.IDataInput;

   public class CustomDungeonAssetsMsg extends IncomingMessage
   {
      public var assetsXml_:String;

      public function CustomDungeonAssetsMsg(id:uint, callback:Function)
      {
         super(id, callback);
      }

      override public function parseFromInput(data:IDataInput) : void
      {
         var len:int = data.readInt();
         this.assetsXml_ = data.readUTFBytes(len);
      }
   }
}
