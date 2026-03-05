package kabam.rotmg.vault
{
import flash.events.Event;

//editor8182381 — Custom event for vault cell clicks
public class VaultCellEvent extends Event
{
    public static const CELL_CLICK:String = "vaultCellClick";

    public var slotIndex:int;
    public var sectionIndex:int;

    public function VaultCellEvent(type:String, slotIndex:int, sectionIndex:int)
    {
        super(type, true, false);
        this.slotIndex = slotIndex;
        this.sectionIndex = sectionIndex;
    }

    override public function clone():Event
    {
        return new VaultCellEvent(type, slotIndex, sectionIndex);
    }
}
}
