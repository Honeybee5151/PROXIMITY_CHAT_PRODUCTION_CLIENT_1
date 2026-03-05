package kabam.rotmg.messaging.impl.incoming.vault
{

import flash.utils.IDataInput;

import kabam.rotmg.messaging.impl.incoming.IncomingMessage;

public class VaultData extends IncomingMessage
{
    public var sectionIndex_:int;
    public var slots_:Vector.<int>;
    public var itemTypes_:Vector.<int>;
    public var itemDatas_:Vector.<String>;

    public function VaultData(id:uint, callback:Function)
    {
        this.slots_ = new Vector.<int>();
        this.itemTypes_ = new Vector.<int>();
        this.itemDatas_ = new Vector.<String>();
        super(id, callback);
    }

    override public function parseFromInput(data:IDataInput):void
    {
        this.sectionIndex_ = data.readByte();
        var count:int = data.readShort();

        this.slots_.length = 0;
        this.itemTypes_.length = 0;
        this.itemDatas_.length = 0;

        for (var i:int = 0; i < count; i++)
        {
            this.slots_.push(data.readShort());
            this.itemTypes_.push(data.readInt());
            this.itemDatas_.push(data.readUTF());
        }
    }
}
}
