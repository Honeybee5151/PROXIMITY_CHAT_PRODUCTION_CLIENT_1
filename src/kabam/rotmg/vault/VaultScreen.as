package kabam.rotmg.vault
{
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.screens.TitleMenuOption;
import com.company.ui.SimpleText;
import com.gskinner.motion.GTween;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.text.TextFieldAutoSize;

//editor8182381 — Full-screen vault storage UI with 10 named sections
public class VaultScreen extends Sprite
{
    public static var instance:VaultScreen = null;

    private static const SECTION_NAMES:Array = [
        "Weapons", "Armor", "Abilities", "Rings", "Consumables",
        "Materials", "Sets", "Valuables", "Keys", "Misc"
    ];

    private var gs_:GameSprite;
    private var background_:Sprite;
    private var titleText_:SimpleText;
    private var closeButton_:TitleMenuOption;
    private var tabButtons_:Vector.<TitleMenuOption>;
    private var tabUnderlines_:Vector.<Sprite>;
    private var grids_:Vector.<VaultSectionGrid>;
    private var activeSection_:int = 0;
    private var invSlots_:Vector.<Sprite>;
    private var invBitmaps_:Vector.<Bitmap>;
    private var invTypes_:Vector.<int>;
    private var selectedVaultSlot_:int = -1;
    private var selectedVaultSection_:int = -1;
    private var bottomBar_:Sprite;
    private var lines_:Sprite;

    public function VaultScreen(gameSprite:GameSprite)
    {
        super();
        instance = this;
        this.gs_ = gameSprite;
        this.alpha = 0;
        new GTween(this, 0.2, {"alpha": 1});

        // Background
        this.background_ = drawBackground();
        addChild(this.background_);

        // Lines
        this.lines_ = drawLines();
        addChild(this.lines_);

        // Bottom bar
        this.bottomBar_ = drawBottomBar();
        addChild(this.bottomBar_);

        // Title
        this.titleText_ = new SimpleText(22, 0xFFFFFF, false, 800, 0);
        this.titleText_.setBold(true);
        this.titleText_.setText("Vault Storage");
        this.titleText_.autoSize = TextFieldAutoSize.LEFT;
        this.titleText_.filters = [new DropShadowFilter(0, 0, 0)];
        this.titleText_.updateMetrics();
        this.titleText_.x = 20;
        this.titleText_.y = 10;
        addChild(this.titleText_);

        // Close button
        this.closeButton_ = new TitleMenuOption("close", 22, false);
        this.closeButton_.addEventListener(MouseEvent.CLICK, onClose);
        addChild(this.closeButton_);

        // Create tab buttons
        this.tabButtons_ = new Vector.<TitleMenuOption>();
        this.tabUnderlines_ = new Vector.<Sprite>();
        for (var i:int = 0; i < 10; i++)
        {
            var tab:TitleMenuOption = new TitleMenuOption(SECTION_NAMES[i], 14, false);
            tab.addEventListener(MouseEvent.CLICK, onTabClick);
            addChild(tab);
            this.tabButtons_.push(tab);

            var underline:Sprite = new Sprite();
            addChild(underline);
            this.tabUnderlines_.push(underline);
        }

        // Create section grids (lazy — create all, show one at a time)
        this.grids_ = new Vector.<VaultSectionGrid>();
        for (var j:int = 0; j < 10; j++)
        {
            var grid:VaultSectionGrid = new VaultSectionGrid(j);
            grid.visible = (j == 0);
            grid.addEventListener(VaultCellEvent.CELL_CLICK, onVaultCellClick);
            addChild(grid);
            this.grids_.push(grid);
        }

        // Inventory row
        this.invSlots_ = new Vector.<Sprite>();
        this.invBitmaps_ = new Vector.<Bitmap>();
        this.invTypes_ = new Vector.<int>();
        createInventoryRow();

        // Position
        this.positionAssets();
        if (WebMain.STAGE)
            WebMain.STAGE.addEventListener(Event.RESIZE, positionAssets);

        // Request vault data
        this.gs_.gsc_.vaultOpen(0xFF);

        // Set active tab
        updateTabHighlight();
    }

    private function createInventoryRow():void
    {
        var player:Player = this.gs_.map.player_;
        if (player == null) return;

        // Show inventory slots 4-11 (the 8 backpack slots)
        for (var i:int = 4; i < 12; i++)
        {
            var slotIdx:int = i - 4;
            var cell:Sprite = new Sprite();
            var g:Graphics = cell.graphics;
            g.beginFill(0x444444, 1);
            g.drawRoundRect(0, 0, 40, 40, 4, 4);
            g.endFill();
            cell.buttonMode = true;
            cell.useHandCursor = true;
            cell.addEventListener(MouseEvent.CLICK, onInvSlotClick);
            addChild(cell);
            this.invSlots_.push(cell);

            var bmp:Bitmap = new Bitmap();
            cell.addChild(bmp);
            this.invBitmaps_.push(bmp);

            var itemType:int = player.equipment_[i];
            this.invTypes_.push(itemType);
            if (itemType > 0)
            {
                var tex:BitmapData = ObjectLibrary.getRedrawnTextureFromType(itemType, 60, true);
                bmp.bitmapData = tex;
                bmp.x = (40 - (tex ? tex.width : 0)) / 2;
                bmp.y = (40 - (tex ? tex.height : 0)) / 2;
            }
        }
    }

    public function refreshInventoryRow():void
    {
        var player:Player = this.gs_.map.player_;
        if (player == null) return;

        for (var i:int = 0; i < 8; i++)
        {
            var invIdx:int = i + 4;
            var itemType:int = player.equipment_[invIdx];
            this.invTypes_[i] = itemType;
            if (itemType > 0)
            {
                var tex:BitmapData = ObjectLibrary.getRedrawnTextureFromType(itemType, 60, true);
                this.invBitmaps_[i].bitmapData = tex;
                this.invBitmaps_[i].x = (40 - (tex ? tex.width : 0)) / 2;
                this.invBitmaps_[i].y = (40 - (tex ? tex.height : 0)) / 2;
            }
            else
            {
                this.invBitmaps_[i].bitmapData = null;
            }
        }
    }

    public function onVaultData(sectionIndex:int, slots:Vector.<int>, types:Vector.<int>, datas:Vector.<String>):void
    {
        if (sectionIndex >= 0 && sectionIndex < 10)
        {
            this.grids_[sectionIndex].setItems(slots, types, datas);
        }
    }

    private function onTabClick(e:MouseEvent):void
    {
        var tab:TitleMenuOption = e.currentTarget as TitleMenuOption;
        var idx:int = this.tabButtons_.indexOf(tab);
        if (idx < 0 || idx == this.activeSection_) return;

        this.grids_[this.activeSection_].visible = false;
        this.activeSection_ = idx;
        this.grids_[this.activeSection_].visible = true;
        this.selectedVaultSlot_ = -1;
        this.selectedVaultSection_ = -1;
        updateTabHighlight();
    }

    private function updateTabHighlight():void
    {
        for (var i:int = 0; i < 10; i++)
        {
            var ug:Graphics = this.tabUnderlines_[i].graphics;
            ug.clear();
            if (i == this.activeSection_)
            {
                ug.beginFill(0xFFCC00, 1);
                ug.drawRect(0, 0, this.tabButtons_[i].width, 2);
                ug.endFill();
            }
        }
    }

    private function onVaultCellClick(e:VaultCellEvent):void
    {
        var slotIdx:int = e.slotIndex;
        var section:int = e.sectionIndex;

        if (this.selectedVaultSlot_ >= 0 && this.selectedVaultSection_ >= 0)
        {
            // Second click — vault-to-vault swap
            if (this.selectedVaultSlot_ != slotIdx || this.selectedVaultSection_ != section)
            {
                var srcType:int = this.grids_[this.selectedVaultSection_].getItemType(this.selectedVaultSlot_);
                this.gs_.gsc_.vaultSwap(2, this.selectedVaultSection_, this.selectedVaultSlot_, srcType,
                    0, 0, section, slotIdx);

                // Optimistic swap
                var destType:int = this.grids_[section].getItemType(slotIdx);
                var destData:String = this.grids_[section].getItemData(slotIdx);
                var srcData:String = this.grids_[this.selectedVaultSection_].getItemData(this.selectedVaultSlot_);
                this.grids_[section].setSlot(slotIdx, srcType, srcData);
                this.grids_[this.selectedVaultSection_].setSlot(this.selectedVaultSlot_, destType, destData);
            }
            this.selectedVaultSlot_ = -1;
            this.selectedVaultSection_ = -1;
            return;
        }

        // First click — select this vault slot
        var type:int = this.grids_[section].getItemType(slotIdx);
        if (type > 0)
        {
            this.selectedVaultSlot_ = slotIdx;
            this.selectedVaultSection_ = section;
        }
    }

    private function onInvSlotClick(e:MouseEvent):void
    {
        var cell:Sprite = e.currentTarget as Sprite;
        var idx:int = this.invSlots_.indexOf(cell);
        if (idx < 0) return;

        var invSlotIndex:int = idx + 4; // actual player inv slot

        if (this.selectedVaultSlot_ >= 0 && this.selectedVaultSection_ >= 0)
        {
            // Vault → inventory: move selected vault item to this inv slot
            var vaultType:int = this.grids_[this.selectedVaultSection_].getItemType(this.selectedVaultSlot_);
            var invType:int = this.invTypes_[idx];
            this.gs_.gsc_.vaultSwap(1, this.selectedVaultSection_, this.selectedVaultSlot_, vaultType,
                invSlotIndex, invType);

            // Optimistic swap
            var vaultData:String = this.grids_[this.selectedVaultSection_].getItemData(this.selectedVaultSlot_);
            this.grids_[this.selectedVaultSection_].setSlot(this.selectedVaultSlot_, invType, "");
            this.invTypes_[idx] = vaultType;
            updateInvBitmap(idx, vaultType);

            this.selectedVaultSlot_ = -1;
            this.selectedVaultSection_ = -1;
        }
        else
        {
            // Inventory → vault: need to select a vault slot next
            // For now, find first empty slot in active section
            var itemType:int = this.invTypes_[idx];
            if (itemType <= 0) return;

            var emptySlot:int = findEmptySlot(this.activeSection_);
            if (emptySlot < 0)
            {
                trace("[Vault] No empty slots in section " + SECTION_NAMES[this.activeSection_]);
                return;
            }

            var vaultItemType:int = this.grids_[this.activeSection_].getItemType(emptySlot);
            this.gs_.gsc_.vaultSwap(0, this.activeSection_, emptySlot, vaultItemType,
                invSlotIndex, itemType);

            // Optimistic
            this.grids_[this.activeSection_].setSlot(emptySlot, itemType, "");
            this.invTypes_[idx] = -1;
            updateInvBitmap(idx, -1);
        }
    }

    private function updateInvBitmap(idx:int, type:int):void
    {
        if (type > 0)
        {
            var tex:BitmapData = ObjectLibrary.getRedrawnTextureFromType(type, 60, true);
            this.invBitmaps_[idx].bitmapData = tex;
            this.invBitmaps_[idx].x = (40 - (tex ? tex.width : 0)) / 2;
            this.invBitmaps_[idx].y = (40 - (tex ? tex.height : 0)) / 2;
        }
        else
        {
            this.invBitmaps_[idx].bitmapData = null;
        }
    }

    private function findEmptySlot(section:int):int
    {
        for (var i:int = 0; i < VaultSectionGrid.SLOTS; i++)
        {
            if (this.grids_[section].getItemType(i) <= 0)
                return i;
        }
        return -1;
    }

    private function drawBackground():Sprite
    {
        var box:Sprite = new Sprite();
        var b:Graphics = box.graphics;
        b.beginFill(0x2B2B2B, 0.9);
        b.drawRect(0, 0, 800, 600);
        b.endFill();
        return box;
    }

    private function drawLines():Sprite
    {
        var box:Sprite = new Sprite();
        var b:Graphics = box.graphics;
        b.lineStyle(2, 0x5E6E5E);
        b.moveTo(0, 70);
        b.lineTo(800, 70);
        b.lineStyle();
        return box;
    }

    private function drawBottomBar():Sprite
    {
        var box:Sprite = new Sprite();
        var b:Graphics = box.graphics;
        b.beginFill(0, 0.5);
        b.drawRect(0, 525, 800, 75);
        b.endFill();
        return box;
    }

    private function positionAssets(e:Event = null):void
    {
        if (!WebMain.STAGE) return;

        var width:int = WebMain.STAGE.stageWidth;
        var height:int = WebMain.STAGE.stageHeight;
        var sWidth:Number = 800 / width;
        var sHeight:Number = 600 / height;
        var result:Number = sHeight / sWidth;

        this.background_.width = 800 * result;
        this.lines_.width = 800 * result;
        this.bottomBar_.width = 800 * result;

        // Close button
        this.closeButton_.x = (400 * result) - this.closeButton_.width / 2;
        this.closeButton_.y = 540;

        // Tab buttons (across the top, below title)
        var tabX:Number = 20;
        for (var i:int = 0; i < 10; i++)
        {
            this.tabButtons_[i].x = tabX;
            this.tabButtons_[i].y = 40;
            this.tabUnderlines_[i].x = tabX;
            this.tabUnderlines_[i].y = 62;
            tabX += this.tabButtons_[i].width + 8;
        }

        // Grids
        var gridX:Number = 20;
        var gridY:Number = 80;
        for (var j:int = 0; j < 10; j++)
        {
            this.grids_[j].x = gridX;
            this.grids_[j].y = gridY;
        }

        // Inventory row at bottom
        var invStartX:Number = 20;
        var invY:Number = 470;
        for (var k:int = 0; k < this.invSlots_.length; k++)
        {
            this.invSlots_[k].x = invStartX + k * 44;
            this.invSlots_[k].y = invY;
        }

        // Inventory label
        // (label created during position, or could be static)
    }

    private function onClose(e:Event):void
    {
        if (WebMain.STAGE)
            WebMain.STAGE.removeEventListener(Event.RESIZE, positionAssets);

        this.gs_.mui_.setEnableHotKeysInput(true);
        this.gs_.mui_.setEnablePlayerInput(true);

        this.closeButton_.removeEventListener(MouseEvent.CLICK, onClose);

        for (var i:int = 0; i < 10; i++)
        {
            this.tabButtons_[i].removeEventListener(MouseEvent.CLICK, onTabClick);
            this.grids_[i].removeEventListener(VaultCellEvent.CELL_CLICK, onVaultCellClick);
            this.grids_[i].dispose();
        }

        for (var j:int = 0; j < this.invSlots_.length; j++)
        {
            this.invSlots_[j].removeEventListener(MouseEvent.CLICK, onInvSlotClick);
        }

        for (var k:int = numChildren - 1; k >= 0; k--)
        {
            removeChildAt(k);
        }

        instance = null;
        this.gs_ = null;
        stage.focus = null;
        parent.removeChild(this);
    }
}
}
