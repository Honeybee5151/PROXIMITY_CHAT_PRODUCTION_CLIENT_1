package kabam.rotmg.messaging.impl.outgoing
{
   import flash.utils.IDataOutput;

   public class Crouch extends OutgoingMessage
   {
      public var isCrouching_:Boolean;

      public function Crouch(id:uint, callback:Function)
      {
         super(id, callback);
      }

      override public function writeToOutput(data:IDataOutput) : void
      {
         data.writeBoolean(this.isCrouching_);
      }

      override public function toString() : String
      {
         return formatToString("CROUCH", "isCrouching_");
      }
   }
}
