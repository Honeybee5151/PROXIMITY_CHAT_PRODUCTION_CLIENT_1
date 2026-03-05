package kabam.rotmg.vault
{
import com.company.assembleegameclient.objects.ObjectLibrary;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Rectangle;

//editor8182381 — Scrollable grid for one vault section (50 rows × 8 columns = 400 slots)
public class VaultSectionGrid extends Sprite
{
    public static const COLS:int = 8;
    public static const ROWS:int = 50;
    public static const SLOTS:int = COLS * ROWS;
    public static const CELL_SIZE:int = 40;
    public static const CELL_PAD:int = 4;
    public static const CELL_TOTAL:int = CELL_SIZE + CELL_PAD;
    public static const VISIBLE_HEIGHT:int = 352; // 8 rows visible

    private var content_:Sprite;
    private var scrollbar_:Shape;
    private var itemTypes_:Vector.<int>;
    private var itemDatas_:Vector.<String>;
    private var cellSprites_:Vector.<Sprite>;
    private var itemBitmaps_:Vector.<Bitmap>;
    private var scrollY_:Number = 0;
    private var maxScrollY_:Number;
    public var sectionIndex:int;

    public function VaultSectionGrid(sectionIdx:int)
    {
        super();
        this.sectionIndex = sectionIdx;
        this.itemTypes_ = new Vector.<int>(SLOTS);
        this.itemDatas_ = new Vector.<String>(SLOTS);
        this.cellSprites_ = new Vector.<Sprite>(SLOTS);
        this.itemBitmaps_ = new Vector.<Bitmap>(SLOTS);

        // Init empty
        for (var i:int = 0; i < SLOTS; i++)
        {
            this.itemTypes_[i] = -1;
            this.itemDatas_[i] = "";
        }

        this.content_ = new Sprite();
        addChild(this.content_);

        this.createCells();

        this.maxScrollY_ = (ROWS * CELL_TOTAL) - VISIBLE_HEIGHT;
        if (this.maxScrollY_ < 0) this.maxScrollY_ = 0;

        // Scrollbar track
        this.scrollbar_ = new Shape();
        this.drawScrollbar();
        addChild(this.scrollbar_);

        // Clip to visible area
        this.scrollRect = new Rectangle(0, 0, COLS * CELL_TOTAL + 20, VISIBLE_HEIGHT);

        addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
    }

    private function createCells():void
    {
        for (var row:int = 0; row < ROWS; row++)
        {
            for (var col:int = 0; col < COLS; col++)
            {
                var idx:int = row * COLS + col;
                var cell:Sprite = new Sprite();
                var g:Graphics = cell.graphics;
                g.beginFill(0x363636, 1);
                g.drawRoundRect(0, 0, CELL_SIZE, CELL_SIZE, 4, 4);
                g.endFill();
                cell.x = col * CELL_TOTAL;
                cell.y = row * CELL_TOTAL;
                cell.buttonMode = true;
                cell.useHandCursor = true;
                this.content_.addChild(cell);
                this.cellSprites_[idx] = cell;

                var bmp:Bitmap = new Bitmap();
                bmp.x = 4;
                bmp.y = 4;
                cell.addChild(bmp);
                this.itemBitmaps_[idx] = bmp;

                cell.addEventListener(MouseEvent.CLICK, onCellClick);
            }
        }
    }

    public function setItems(slots:Vector.<int>, types:Vector.<int>, datas:Vector.<String>):void
    {
        // Clear all
        for (var i:int = 0; i < SLOTS; i++)
        {
            this.itemTypes_[i] = -1;
            this.itemDatas_[i] = "";
            this.itemBitmaps_[i].bitmapData = null;
        }

        // Set received items
        for (var j:int = 0; j < slots.length; j++)
        {
            var slot:int = slots[j];
            if (slot >= 0 && slot < SLOTS)
            {
                this.itemTypes_[slot] = types[j];
                this.itemDatas_[slot] = datas[j];
                updateCellBitmap(slot);
            }
        }
    }

    private function updateCellBitmap(idx:int):void
    {
        var type:int = this.itemTypes_[idx];
        if (type > 0)
        {
            var tex:BitmapData = ObjectLibrary.getRedrawnTextureFromType(type, 60, true);
            this.itemBitmaps_[idx].bitmapData = tex;
            this.itemBitmaps_[idx].x = (CELL_SIZE - (tex ? tex.width : 0)) / 2;
            this.itemBitmaps_[idx].y = (CELL_SIZE - (tex ? tex.height : 0)) / 2;
        }
        else
        {
            this.itemBitmaps_[idx].bitmapData = null;
        }
    }

    public function getItemType(slot:int):int
    {
        return this.itemTypes_[slot];
    }

    public function getItemData(slot:int):String
    {
        return this.itemDatas_[slot];
    }

    public function setSlot(slot:int, type:int, data:String):void
    {
        this.itemTypes_[slot] = type;
        this.itemDatas_[slot] = data;
        updateCellBitmap(slot);
    }

    public function getSlotAtPoint(localX:Number, localY:Number):int
    {
        var adjustedY:Number = localY + this.scrollY_;
        var col:int = int(localX / CELL_TOTAL);
        var row:int = int(adjustedY / CELL_TOTAL);
        if (col < 0 || col >= COLS || row < 0 || row >= ROWS)
            return -1;
        return row * COLS + col;
    }

    private function onCellClick(e:MouseEvent):void
    {
        var cell:Sprite = e.currentTarget as Sprite;
        if (cell == null) return;

        var idx:int = this.cellSprites_.indexOf(cell);
        if (idx < 0) return;

        // Dispatch to parent VaultScreen
        dispatchEvent(new VaultCellEvent(VaultCellEvent.CELL_CLICK, idx, this.sectionIndex));
    }

    private function onMouseWheel(e:MouseEvent):void
    {
        this.scrollY_ -= e.delta * 20;
        if (this.scrollY_ < 0) this.scrollY_ = 0;
        if (this.scrollY_ > this.maxScrollY_) this.scrollY_ = this.maxScrollY_;

        this.content_.y = -this.scrollY_;
        this.drawScrollbar();
    }

    private function drawScrollbar():void
    {
        var g:Graphics = this.scrollbar_.graphics;
        g.clear();

        var trackX:Number = COLS * CELL_TOTAL + 4;
        var trackH:Number = VISIBLE_HEIGHT;

        // Track
        g.beginFill(0x222222, 0.5);
        g.drawRoundRect(trackX, 0, 10, trackH, 5, 5);
        g.endFill();

        // Thumb
        if (this.maxScrollY_ > 0)
        {
            var thumbH:Number = Math.max(20, trackH * (VISIBLE_HEIGHT / (ROWS * CELL_TOTAL)));
            var thumbY:Number = (this.scrollY_ / this.maxScrollY_) * (trackH - thumbH);
            g.beginFill(0x666666, 0.8);
            g.drawRoundRect(trackX, thumbY, 10, thumbH, 5, 5);
            g.endFill();
        }
    }

    public function dispose():void
    {
        removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
        for (var i:int = 0; i < SLOTS; i++)
        {
            if (this.cellSprites_[i])
                this.cellSprites_[i].removeEventListener(MouseEvent.CLICK, onCellClick);
        }
    }
}
}
