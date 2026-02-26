package kabam.rotmg.messaging.impl.incoming
{
   import flash.utils.IDataInput;
   import flash.utils.ByteArray;

   public class CustomObjectsMsg extends IncomingMessage
   {
      public var binaryData_:ByteArray;

      public function CustomObjectsMsg(id:uint, callback:Function)
      {
         super(id, callback);
      }

      override public function parseFromInput(data:IDataInput) : void
      {
         try
         {
            var len:int = data.readInt();
            trace("[CustomObjects] parseFromInput: compressed length = " + len);
            var compressed:ByteArray = new ByteArray();
            data.readBytes(compressed, 0, len);
            trace("[CustomObjects] parseFromInput: read " + compressed.length + " compressed bytes");
            compressed.uncompress();
            compressed.position = 0;
            trace("[CustomObjects] parseFromInput: decompressed to " + compressed.length + " bytes");
            this.binaryData_ = compressed;
         }
         catch (e:Error)
         {
            trace("[CustomObjects] ERROR in parseFromInput: " + e.message);
            this.binaryData_ = null;
         }
      }
   }
}
