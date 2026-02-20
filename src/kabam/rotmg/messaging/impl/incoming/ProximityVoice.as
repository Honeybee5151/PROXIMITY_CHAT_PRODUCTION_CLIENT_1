package kabam.rotmg.messaging.impl.incoming
{
import flash.utils.IDataInput;
import kabam.lib.net.impl.Message;

public class ProximityVoice extends Message
{
    public var jsonData_:String;

    public function ProximityVoice(id:uint, callback:Function)
    {
        super(id, callback);
    }

    public override function parseFromInput(data:IDataInput) : void
    {
        try {
            // Check if there's data available to read
            if (data.bytesAvailable > 0) {
                this.jsonData_ = data.readUTF();
            } else {
                this.jsonData_ = null;
                trace("ProximityVoice: No data available to read");
            }
        } catch (error:Error) {
            this.jsonData_ = null;
            trace("ProximityVoice: Error reading data:", error.message);
        }
    }

    public override function toString() : String
    {
        return formatToString("PROXIMITY_VOICE","jsonData_");
    }
}
}