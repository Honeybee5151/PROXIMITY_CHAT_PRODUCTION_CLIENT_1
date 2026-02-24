package com.company.assembleegameclient.ui.dungeons
{
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.ui.Scrollbar;
import com.company.assembleegameclient.ui.TextButton;
import com.company.ui.SimpleText;

import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;

import kabam.rotmg.account.core.Account;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.application.api.ApplicationSetup;

public class DungeonBrowser extends Sprite
{
    private static const WIDTH:int = 700;
    private static const HEIGHT:int = 500;
    private static const LIST_Y:int = 130;
    private static const LIST_HEIGHT:int = 330;
    private static const ITEM_HEIGHT:int = 55;
    private static const ITEMS_VISIBLE:int = 6;

    private var gs_:GameSprite;
    private var background_:Sprite;
    private var title_:SimpleText;
    private var closeBtn_:TextButton;
    private var searchInput_:SimpleText;
    private var searchLabel_:SimpleText;

    private var sortNewest_:TextButton;
    private var sortOldest_:TextButton;
    private var sortLiked_:TextButton;
    private var sortDifficulty_:TextButton;
    private var activeSort_:String = "newest";

    private var listContainer_:Sprite;
    private var listMask_:Shape;
    private var scrollbar_:Scrollbar;

    private var allDungeons_:Array = [];
    private var filteredDungeons_:Array = [];
    private var listItems_:Vector.<DungeonListItem> = new Vector.<DungeonListItem>();
    private var scrollPos_:Number = 0;

    private var loadingText_:SimpleText;
    private var ratePanel_:DungeonRatePanel;

    public function DungeonBrowser(gs:GameSprite)
    {
        super();
        this.gs_ = gs;

        // Center on screen
        this.x = (800 - WIDTH) / 2;
        this.y = (600 - HEIGHT) / 2;

        this.drawBackground();
        this.drawTitle();
        this.drawCloseButton();
        this.drawSearchBar();
        this.drawSortButtons();
        this.drawListArea();
        this.drawLoadingText();

        addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);

        this.fetchDungeonList();
    }

    private function drawBackground():void
    {
        this.background_ = new Sprite();
        var g:Graphics = this.background_.graphics;

        // Full screen dim
        g.beginFill(0x000000, 0.7);
        g.drawRect(-this.x, -this.y, 800, 600);
        g.endFill();

        // Main panel
        g.beginFill(0x1a1a2e, 1);
        g.lineStyle(2, 0x3a3a5c);
        g.drawRoundRect(0, 0, WIDTH, HEIGHT, 12, 12);
        g.endFill();

        addChild(this.background_);
        this.background_.addEventListener(MouseEvent.CLICK, this.onBackgroundClick);
    }

    private function onBackgroundClick(e:MouseEvent):void
    {
        // Only close if clicking the dim area outside the panel
        if (e.localX < 0 || e.localX > WIDTH || e.localY < 0 || e.localY > HEIGHT)
            this.close();
    }

    private function drawTitle():void
    {
        this.title_ = new SimpleText(28, 0xFFFFFF, false, WIDTH, 0);
        this.title_.setBold(true);
        this.title_.htmlText = "<p align=\"center\">DUNGEON BROWSER</p>";
        this.title_.filters = [new DropShadowFilter(0, 0, 0, 1, 4, 4)];
        this.title_.updateMetrics();
        this.title_.y = 12;
        addChild(this.title_);
    }

    private function drawCloseButton():void
    {
        this.closeBtn_ = new TextButton(14, "Close", 60);
        this.closeBtn_.x = WIDTH - 72;
        this.closeBtn_.y = 14;
        this.closeBtn_.addEventListener(MouseEvent.CLICK, this.onCloseClick);
        addChild(this.closeBtn_);
    }

    private function drawSearchBar():void
    {
        this.searchLabel_ = new SimpleText(14, 0xAAAAAA, false, 0, 0);
        this.searchLabel_.text = "Search:";
        this.searchLabel_.updateMetrics();
        this.searchLabel_.x = 20;
        this.searchLabel_.y = 58;
        addChild(this.searchLabel_);

        // Search input background
        var bg:Sprite = new Sprite();
        bg.graphics.beginFill(0x0f0f1e, 1);
        bg.graphics.lineStyle(1, 0x3a3a5c);
        bg.graphics.drawRoundRect(80, 54, 250, 26, 6, 6);
        bg.graphics.endFill();
        addChild(bg);

        this.searchInput_ = new SimpleText(14, 0xFFFFFF, true, 240, 20);
        this.searchInput_.x = 85;
        this.searchInput_.y = 57;
        this.searchInput_.border = false;
        this.searchInput_.background = false;
        this.searchInput_.addEventListener(Event.CHANGE, this.onSearchChange);
        addChild(this.searchInput_);
    }

    private function drawSortButtons():void
    {
        var startX:int = 20;
        var btnY:int = 92;

        var sortLabel:SimpleText = new SimpleText(12, 0x888888, false, 0, 0);
        sortLabel.text = "Sort:";
        sortLabel.updateMetrics();
        sortLabel.x = startX;
        sortLabel.y = btnY + 3;
        addChild(sortLabel);

        this.sortNewest_ = new TextButton(12, "Newest", 70);
        this.sortNewest_.x = startX + 40;
        this.sortNewest_.y = btnY;
        this.sortNewest_.addEventListener(MouseEvent.CLICK, this.onSortNewest);
        addChild(this.sortNewest_);

        this.sortOldest_ = new TextButton(12, "Oldest", 70);
        this.sortOldest_.x = startX + 116;
        this.sortOldest_.y = btnY;
        this.sortOldest_.addEventListener(MouseEvent.CLICK, this.onSortOldest);
        addChild(this.sortOldest_);

        this.sortLiked_ = new TextButton(12, "Most Liked", 90);
        this.sortLiked_.x = startX + 192;
        this.sortLiked_.y = btnY;
        this.sortLiked_.addEventListener(MouseEvent.CLICK, this.onSortLiked);
        addChild(this.sortLiked_);

        this.sortDifficulty_ = new TextButton(12, "Hardest", 70);
        this.sortDifficulty_.x = startX + 288;
        this.sortDifficulty_.y = btnY;
        this.sortDifficulty_.addEventListener(MouseEvent.CLICK, this.onSortDifficulty);
        addChild(this.sortDifficulty_);
    }

    private function drawListArea():void
    {
        // Separator line
        var sep:Shape = new Shape();
        sep.graphics.lineStyle(1, 0x3a3a5c);
        sep.graphics.moveTo(15, LIST_Y - 5);
        sep.graphics.lineTo(WIDTH - 15, LIST_Y - 5);
        addChild(sep);

        this.listContainer_ = new Sprite();
        this.listContainer_.x = 20;
        this.listContainer_.y = LIST_Y;
        addChild(this.listContainer_);

        this.listMask_ = new Shape();
        this.listMask_.graphics.beginFill(0);
        this.listMask_.graphics.drawRect(0, 0, WIDTH - 60, LIST_HEIGHT);
        this.listMask_.graphics.endFill();
        this.listMask_.x = 20;
        this.listMask_.y = LIST_Y;
        addChild(this.listMask_);
        this.listContainer_.mask = this.listMask_;

        this.scrollbar_ = new Scrollbar(16, LIST_HEIGHT);
        this.scrollbar_.x = WIDTH - 32;
        this.scrollbar_.y = LIST_Y;
        this.scrollbar_.addEventListener(Event.CHANGE, this.onScroll);
        addChild(this.scrollbar_);
    }

    private function drawLoadingText():void
    {
        this.loadingText_ = new SimpleText(16, 0x888888, false, WIDTH, 0);
        this.loadingText_.htmlText = "<p align=\"center\">Loading dungeons...</p>";
        this.loadingText_.updateMetrics();
        this.loadingText_.y = LIST_Y + LIST_HEIGHT / 2 - 10;
        addChild(this.loadingText_);
    }

    // --- Data Fetching ---

    private function fetchDungeonList():void
    {
        var setup:ApplicationSetup = StaticInjectorContext.getInjector().getInstance(ApplicationSetup);
        var url:String = setup.getAppEngineUrl() + "/dungeons/list";

        var request:URLRequest = new URLRequest(url);
        request.method = URLRequestMethod.POST;
        request.data = new URLVariables();

        var loader:URLLoader = new URLLoader();
        loader.addEventListener(Event.COMPLETE, this.onListLoaded);
        loader.addEventListener("ioError", this.onListError);
        loader.addEventListener("securityError", this.onListError);
        loader.load(request);
    }

    private function onListLoaded(e:Event):void
    {
        var data:String = URLLoader(e.target).data;
        try
        {
            var parsed:Object = JSON.parse(data);
            this.allDungeons_ = parsed as Array;
            if (this.allDungeons_ == null)
                this.allDungeons_ = [];
        }
        catch (err:Error)
        {
            this.allDungeons_ = [];
        }

        if (this.loadingText_ && this.loadingText_.parent)
            removeChild(this.loadingText_);

        this.applyFilterAndSort();
    }

    private function onListError(e:Event):void
    {
        this.allDungeons_ = [];
        if (this.loadingText_)
        {
            this.loadingText_.htmlText = "<p align=\"center\">Failed to load dungeons</p>";
            this.loadingText_.updateMetrics();
        }
    }

    // --- Filter & Sort ---

    private function applyFilterAndSort():void
    {
        var search:String = this.searchInput_.text.toLowerCase();
        this.filteredDungeons_ = [];

        for (var i:int = 0; i < this.allDungeons_.length; i++)
        {
            var d:Object = this.allDungeons_[i];
            if (search.length == 0 || d.name.toLowerCase().indexOf(search) >= 0)
                this.filteredDungeons_.push(d);
        }

        // Sort
        switch (this.activeSort_)
        {
            case "newest":
                this.filteredDungeons_.reverse();
                break;
            case "oldest":
                // already in order from file
                break;
            case "liked":
                this.filteredDungeons_.sortOn("likes", Array.NUMERIC | Array.DESCENDING);
                break;
            case "difficulty":
                this.filteredDungeons_.sortOn("difficulty", Array.NUMERIC | Array.DESCENDING);
                break;
        }

        this.scrollPos_ = 0;
        this.rebuildList();
    }

    private function rebuildList():void
    {
        // Clear old items
        for (var i:int = 0; i < this.listItems_.length; i++)
        {
            if (this.listItems_[i].parent)
                this.listContainer_.removeChild(this.listItems_[i]);
        }
        this.listItems_.length = 0;

        // Create items
        var itemWidth:int = WIDTH - 65;
        for (i = 0; i < this.filteredDungeons_.length; i++)
        {
            var item:DungeonListItem = new DungeonListItem(
                this.filteredDungeons_[i], itemWidth, ITEM_HEIGHT, this
            );
            item.y = i * ITEM_HEIGHT;
            this.listContainer_.addChild(item);
            this.listItems_.push(item);
        }

        // Update scrollbar
        var totalHeight:Number = this.filteredDungeons_.length * ITEM_HEIGHT;
        if (totalHeight > LIST_HEIGHT)
            this.scrollbar_.setIndicatorSize(LIST_HEIGHT, totalHeight);
        else
            this.scrollbar_.setIndicatorSize(LIST_HEIGHT, LIST_HEIGHT);

        if (this.filteredDungeons_.length == 0 && (!this.loadingText_ || !this.loadingText_.parent))
        {
            var empty:SimpleText = new SimpleText(14, 0x666666, false, WIDTH - 60, 0);
            empty.htmlText = "<p align=\"center\">No dungeons found</p>";
            empty.updateMetrics();
            empty.y = LIST_HEIGHT / 2 - 10;
            empty.name = "emptyText";
            this.listContainer_.addChild(empty);
        }
    }

    // --- Events ---

    private function onSearchChange(e:Event):void
    {
        this.applyFilterAndSort();
    }

    private function onSortNewest(e:MouseEvent):void
    {
        this.activeSort_ = "newest";
        this.applyFilterAndSort();
    }

    private function onSortOldest(e:MouseEvent):void
    {
        this.activeSort_ = "oldest";
        this.applyFilterAndSort();
    }

    private function onSortLiked(e:MouseEvent):void
    {
        this.activeSort_ = "liked";
        this.applyFilterAndSort();
    }

    private function onSortDifficulty(e:MouseEvent):void
    {
        this.activeSort_ = "difficulty";
        this.applyFilterAndSort();
    }

    private function onScroll(e:Event):void
    {
        var totalHeight:Number = this.filteredDungeons_.length * ITEM_HEIGHT;
        var maxScroll:Number = Math.max(0, totalHeight - LIST_HEIGHT);
        this.listContainer_.y = LIST_Y - (this.scrollbar_.pos() * maxScroll);
    }

    private function onCloseClick(e:MouseEvent):void
    {
        this.close();
    }

    private function onAddedToStage(e:Event):void
    {
        stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
        stage.focus = this.searchInput_;
    }

    private function onRemovedFromStage(e:Event):void
    {
        stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
    }

    private function onKeyDown(e:KeyboardEvent):void
    {
        if (e.keyCode == 27) // ESC
        {
            e.stopImmediatePropagation();
            this.close();
        }
    }

    public function enterDungeon(name:String):void
    {
        // Send /dungeon command through game connection
        this.gs_.gsc_.playerText("/dungeon " + name);
        this.close();
    }

    public function showRatePanel(dungeonData:Object):void
    {
        if (this.ratePanel_ && this.ratePanel_.parent)
            removeChild(this.ratePanel_);

        this.ratePanel_ = new DungeonRatePanel(dungeonData, this);
        this.ratePanel_.x = (WIDTH - 300) / 2;
        this.ratePanel_.y = (HEIGHT - 200) / 2;
        addChild(this.ratePanel_);
    }

    public function onRateComplete():void
    {
        if (this.ratePanel_ && this.ratePanel_.parent)
            removeChild(this.ratePanel_);
        this.ratePanel_ = null;

        // Refresh the list
        this.fetchDungeonList();
    }

    private function close():void
    {
        if (this.ratePanel_ && this.ratePanel_.parent)
            removeChild(this.ratePanel_);
        stage.focus = null;
        parent.removeChild(this);
    }
}
}
