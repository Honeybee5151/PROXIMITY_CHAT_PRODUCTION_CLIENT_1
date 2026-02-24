package kabam.rotmg.messaging.impl.incoming
{
   import flash.utils.IDataInput;

   public class CustomGroundsMsg extends IncomingMessage
   {
      public var groundsXml_:String;

      public function CustomGroundsMsg(id:uint, callback:Function)
      {
         super(id, callback);
      }

      override public function parseFromInput(data:IDataInput) : void
      {
         var len:int = data.readInt();
         this.groundsXml_ = data.readUTFBytes(len);
      }
   }
}
