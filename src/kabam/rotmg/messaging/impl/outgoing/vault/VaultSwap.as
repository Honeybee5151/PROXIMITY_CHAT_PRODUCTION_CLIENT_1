package kabam.rotmg.messaging.impl.outgoing.vault
{

import flash.utils.IDataOutput;

import kabam.rotmg.messaging.impl.outgoing.OutgoingMessage;

public class VaultSwap extends OutgoingMessage
{
    public var action_:int;            // 0=inv→vault, 1=vault→inv, 2=vault→vault
    public var sectionIndex_:int;      // vault section 0-9
    public var vaultSlotIndex_:int;    // vault slot 0-399
    public var vaultItemType_:int;     // current item type at vault slot
    public var invSlotIndex_:int;      // player inv slot
    public var invItemType_:int;       // current item type at inv slot
    public var destSectionIndex_:int;  // destination section (vault→vault only)
    public var destVaultSlotIndex_:int;// destination slot (vault→vault only)

    public function VaultSwap(id:uint, callback:Function)
    {
        super(id, callback);
    }

    override public function writeToOutput(data:IDataOutput):void
    {
        data.writeByte(this.action_);
        data.writeByte(this.sectionIndex_);
        data.writeShort(this.vaultSlotIndex_);
        data.writeInt(this.vaultItemType_);
        data.writeByte(this.invSlotIndex_);
        data.writeInt(this.invItemType_);
        data.writeByte(this.destSectionIndex_);
        data.writeShort(this.destVaultSlotIndex_);
    }
}
}
