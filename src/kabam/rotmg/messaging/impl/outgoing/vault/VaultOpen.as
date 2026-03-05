package kabam.rotmg.messaging.impl.outgoing.vault
{

import flash.utils.IDataOutput;

import kabam.rotmg.messaging.impl.outgoing.OutgoingMessage;

public class VaultOpen extends OutgoingMessage
{
    public var sectionIndex_:int; // 0-9 or 0xFF for all

    public function VaultOpen(id:uint, callback:Function)
    {
        super(id, callback);
    }

    override public function writeToOutput(data:IDataOutput):void
    {
        data.writeByte(this.sectionIndex_);
    }
}
}
