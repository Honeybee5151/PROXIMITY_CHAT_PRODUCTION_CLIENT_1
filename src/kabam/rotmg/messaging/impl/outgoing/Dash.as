package kabam.rotmg.messaging.impl.outgoing
{
   import flash.utils.IDataOutput;

   public class Dash extends OutgoingMessage
   {
      public var time_:int;

      public function Dash(id:uint, callback:Function)
      {
         super(id, callback);
      }

      override public function writeToOutput(data:IDataOutput) : void
      {
         data.writeInt(this.time_);
      }

      override public function toString() : String
      {
         return formatToString("DASH", "time_");
      }
   }
}
