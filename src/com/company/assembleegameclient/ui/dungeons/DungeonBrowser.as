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
import flash.utils.Timer;
import flash.events.TimerEvent;

import kabam.rotmg.account.core.Account;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.application.api.ApplicationSetup;
import kabam.rotmg.assets.CommunityContentLoader; //editor8182381

public class DungeonBrowser extends Sprite
{
    private static const WIDTH:int = 700;
    private static const HEIGHT:int = 500;
    private static const LIST_Y:int = 130;
    private static const LIST_HEIGHT:int = 330;
    private static const ITEM_HEIGHT:int = 55;

    private var gs_:GameSprite;
    private var background_:Sprite;
    private var title_:SimpleText;
    private var closeBtn_:TextButton;
    private var searchInput_:SimpleText;
    private var searchLabel_:SimpleText;

    private var sortNewest_:TextButton;
    private var sortOldest_:TextButton;
    private var sortLiked_:TextButton;
    private var diffFilterInput_:SimpleText;
    private var activeSort_:String = "newest";

    private var listContainer_:Sprite;
    private var listMask_:Shape;
    private var scrollbar_:Scrollbar;

    private var allDungeons_:Array = [];
    private var filteredDungeons_:Array = [];
    private var listItems_:Vector.<DungeonListItem> = new Vector.<DungeonListItem>();

    // Virtual scrolling: only render visible items
    private var visibleCount_:int;
    private var scrollOffset_:int = 0;

    private var loadingText_:SimpleText;
    private var ratePanel_:DungeonRatePanel;

    // Timer-based text polling (avoids Flash ENTER_FRAME timing issues)
    private var pollTimer_:Timer;
    private var lastSearchText_:String = "";
    private var lastDiffText_:String = "";

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

        // Full screen dim - oversized to cover any resolution/scaling
        g.beginFill(0x000000, 0.7);
        g.drawRect(-2000, -2000, 4000, 4000);
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
        this.searchInput_.background = true;
        this.searchInput_.backgroundColor = 0x0f0f1e;
        this.searchInput_.tabEnabled = false;
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

        // Difficulty filter
        var diffLabel:SimpleText = new SimpleText(12, 0x888888, false, 0, 0);
        diffLabel.text = "Diff:";
        diffLabel.updateMetrics();
        diffLabel.x = startX + 295;
        diffLabel.y = btnY + 3;
        addChild(diffLabel);

        var diffBg:Sprite = new Sprite();
        diffBg.graphics.beginFill(0x0f0f1e, 1);
        diffBg.graphics.lineStyle(1, 0x3a3a5c);
        diffBg.graphics.drawRoundRect(startX + 330, btnY - 1, 45, 24, 6, 6);
        diffBg.graphics.endFill();
        addChild(diffBg);

        this.diffFilterInput_ = new SimpleText(12, 0xFFFFFF, true, 37, 18);
        this.diffFilterInput_.x = startX + 334;
        this.diffFilterInput_.y = btnY + 2;
        this.diffFilterInput_.border = false;
        this.diffFilterInput_.background = true;
        this.diffFilterInput_.backgroundColor = 0x0f0f1e;
        this.diffFilterInput_.maxChars = 2;
        this.diffFilterInput_.restrict = "0-9";
        this.diffFilterInput_.tabEnabled = false;
        addChild(this.diffFilterInput_);
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
        var search:String = this.searchInput_.text.replace(/^\s+|\s+$/g, "").toLowerCase();
        var diffText:String = this.diffFilterInput_.text;
        var diffFilter:int = parseInt(diffText);
        var hasDiffFilter:Boolean = diffText.length > 0 && !isNaN(diffFilter);
        this.filteredDungeons_ = [];

        for (var i:int = 0; i < this.allDungeons_.length; i++)
        {
            var d:Object = this.allDungeons_[i];
            var dName:String = String(d.name);
            if (search.length > 0)
            {
                if (dName.toLowerCase().indexOf(search) < 0)
                    continue;
            }
            if (hasDiffFilter)
            {
                var dungeonDiff:Number = Number(d.difficulty);
                if (isNaN(dungeonDiff)) dungeonDiff = 0;
                if (int(dungeonDiff) != diffFilter)
                    continue;
            }
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
                this.filteredDungeons_.sort(function(a:Object, b:Object):int {
                    var aLikes:int = int(a.likes) || 0;
                    var bLikes:int = int(b.likes) || 0;
                    return bLikes - aLikes;
                });
                break;
        }

        this.rebuildList();
    }

    private function rebuildList():void
    {
        this.clearList();
        this.listContainer_.y = LIST_Y;
        this.scrollOffset_ = 0;

        // Calculate how many items fit on screen (+1 for partial visibility during scroll)
        this.visibleCount_ = Math.ceil(LIST_HEIGHT / ITEM_HEIGHT) + 1;

        // Create only the visible item slots
        var itemWidth:int = WIDTH - 65;
        var count:int = Math.min(this.visibleCount_, this.filteredDungeons_.length);
        for (var i:int = 0; i < count; i++)
        {
            var item:DungeonListItem = new DungeonListItem(
                this.filteredDungeons_[i], itemWidth, ITEM_HEIGHT, this
            );
            item.y = 4 + i * ITEM_HEIGHT;
            this.listContainer_.addChild(item);
            this.listItems_.push(item);
        }

        this.listContainer_.mask = null;
        this.listContainer_.mask = this.listMask_;

        // Update scrollbar
        var totalHeight:Number = this.filteredDungeons_.length * ITEM_HEIGHT;
        if (totalHeight > LIST_HEIGHT)
            this.scrollbar_.setIndicatorSize(LIST_HEIGHT, totalHeight);
        else
            this.scrollbar_.setIndicatorSize(LIST_HEIGHT, LIST_HEIGHT);

        // Safety: ensure container.y is correct after scrollbar fires onScroll
        this.listContainer_.y = LIST_Y;

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

    private function onScroll(e:Event):void
    {
        var totalHeight:Number = this.filteredDungeons_.length * ITEM_HEIGHT;
        var maxScroll:Number = Math.max(0, totalHeight - LIST_HEIGHT);
        if (maxScroll <= 0)
        {
            this.listContainer_.y = LIST_Y;
            return;
        }
        var p:Number = this.scrollbar_.pos();
        if (isNaN(p)) p = 0;

        var scrollPixels:Number = p * maxScroll;
        var newOffset:int = Math.floor(scrollPixels / ITEM_HEIGHT);
        // Clamp so we don't go past the end
        var maxOffset:int = Math.max(0, this.filteredDungeons_.length - this.visibleCount_);
        if (newOffset > maxOffset) newOffset = maxOffset;

        // Pixel offset within the top item for smooth scrolling
        var pixelRemainder:Number = scrollPixels - (newOffset * ITEM_HEIGHT);
        this.listContainer_.y = LIST_Y - pixelRemainder;

        // Only rebuild items if the visible window shifted
        if (newOffset != this.scrollOffset_)
        {
            this.scrollOffset_ = newOffset;
            this.updateVisibleItems();
        }
    }

    private function updateVisibleItems():void
    {
        // Remove old items
        for (var r:int = 0; r < this.listItems_.length; r++)
        {
            if (this.listItems_[r].parent)
                this.listContainer_.removeChild(this.listItems_[r]);
        }
        this.listItems_.length = 0;

        var itemWidth:int = WIDTH - 65;
        var count:int = Math.min(this.visibleCount_, this.filteredDungeons_.length - this.scrollOffset_);
        for (var i:int = 0; i < count; i++)
        {
            var dataIndex:int = this.scrollOffset_ + i;
            var item:DungeonListItem = new DungeonListItem(
                this.filteredDungeons_[dataIndex], itemWidth, ITEM_HEIGHT, this
            );
            item.y = 4 + i * ITEM_HEIGHT;
            this.listContainer_.addChild(item);
            this.listItems_.push(item);
        }
    }

    private function onCloseClick(e:MouseEvent):void
    {
        this.close();
    }

    private function onAddedToStage(e:Event):void
    {
        // Listen on THIS sprite to intercept keys before they reach stage (MapUserInput)
        // When text fields inside us have focus, events bubble: TextField → us → stage
        // We stop propagation here so game handlers never see our keystrokes
        addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDownLocal);
        addEventListener(KeyboardEvent.KEY_UP, this.onKeyUpLocal);

        // Stage listener for ESC when focus is null (keys go directly to stage)
        stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);

        // Listen for text changes
        this.searchInput_.addEventListener(Event.CHANGE, this.onTextChanged);
        this.diffFilterInput_.addEventListener(Event.CHANGE, this.onTextChanged);

        // Backup timer poll (200ms)
        this.pollTimer_ = new Timer(200);
        this.pollTimer_.addEventListener(TimerEvent.TIMER, this.onPollTimer);
        this.pollTimer_.start();

        stage.focus = this.searchInput_;
    }

    private function onRemovedFromStage(e:Event):void
    {
        removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDownLocal);
        removeEventListener(KeyboardEvent.KEY_UP, this.onKeyUpLocal);
        stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
        this.searchInput_.removeEventListener(Event.CHANGE, this.onTextChanged);
        this.diffFilterInput_.removeEventListener(Event.CHANGE, this.onTextChanged);

        if (this.pollTimer_)
        {
            this.pollTimer_.stop();
            this.pollTimer_.removeEventListener(TimerEvent.TIMER, this.onPollTimer);
            this.pollTimer_ = null;
        }
    }

    private function onKeyDownLocal(e:KeyboardEvent):void
    {
        // This fires when a text field inside us has focus (bubble phase)
        if (e.keyCode == 27) // ESC
        {
            e.stopPropagation();
            this.close();
            return;
        }
        // Block ALL other keys from reaching game handlers (MapUserInput)
        e.stopPropagation();
    }

    private function onKeyUpLocal(e:KeyboardEvent):void
    {
        // Block ALL key-ups from reaching game handlers
        // MapUserInput.onKeyUp has NO global focus check — it processes interact,
        // PCUI, movement etc. regardless, which steals focus from our text fields
        e.stopPropagation();
    }

    private function onKeyDown(e:KeyboardEvent):void
    {
        // Stage-level: only handles ESC when focus is null (no text field active)
        if (e.keyCode == 27)
        {
            this.close();
        }
    }

    private function onTextChanged(e:Event):void
    {
        var curSearch:String = this.searchInput_.text;
        var curDiff:String = this.diffFilterInput_.text;

        this.lastSearchText_ = curSearch;
        this.lastDiffText_ = curDiff;
        this.applyFilterAndSort();
    }

    private function onPollTimer(e:TimerEvent):void
    {
        var curSearch:String = this.searchInput_.text;
        var curDiff:String = this.diffFilterInput_.text;

        if (curSearch != this.lastSearchText_ || curDiff != this.lastDiffText_)
        {
            this.lastSearchText_ = curSearch;
            this.lastDiffText_ = curDiff;
            this.applyFilterAndSort();
        }
    }

    public function enterDungeon(name:String):void
    {
        //editor8182381 — Block entry until community XMLs are loaded
        if (!CommunityContentLoader.isReady)
        {
            if (this.loadingText_ && this.loadingText_.parent)
                removeChild(this.loadingText_);
            this.loadingText_ = new SimpleText(16, 0xFFAA00, false, WIDTH, 0);
            this.loadingText_.htmlText = "<p align=\"center\">Community content still loading, please wait...</p>";
            this.loadingText_.updateMetrics();
            this.loadingText_.y = LIST_Y + LIST_HEIGHT + 10;
            addChild(this.loadingText_);
            return;
        }
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

        // Show loading state while refreshing
        this.clearList();
        if (!this.loadingText_ || !this.loadingText_.parent)
        {
            this.loadingText_ = new SimpleText(16, 0x888888, false, WIDTH, 0);
            this.loadingText_.htmlText = "<p align=\"center\">Refreshing...</p>";
            this.loadingText_.updateMetrics();
            this.loadingText_.y = LIST_Y + LIST_HEIGHT / 2 - 10;
            addChild(this.loadingText_);
        }

        // Refresh the list
        this.fetchDungeonList();
    }

    private function clearList():void
    {
        for (var i:int = 0; i < this.listItems_.length; i++)
        {
            if (this.listItems_[i].parent)
                this.listContainer_.removeChild(this.listItems_[i]);
        }
        this.listItems_.length = 0;

        var oldEmpty:* = this.listContainer_.getChildByName("emptyText");
        if (oldEmpty)
            this.listContainer_.removeChild(oldEmpty);
    }

    private function close():void
    {
        // Stop timer
        if (this.pollTimer_)
        {
            this.pollTimer_.stop();
            this.pollTimer_.removeEventListener(TimerEvent.TIMER, this.onPollTimer);
            this.pollTimer_ = null;
        }

        // Remove text change listeners
        this.searchInput_.removeEventListener(Event.CHANGE, this.onTextChanged);
        this.diffFilterInput_.removeEventListener(Event.CHANGE, this.onTextChanged);

        // Remove keyboard listener
        if (stage)
        {
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
            stage.focus = null;
        }

        // Clean up rate panel
        if (this.ratePanel_ && this.ratePanel_.parent)
            removeChild(this.ratePanel_);
        this.ratePanel_ = null;

        // Clean up list items
        this.clearList();

        // Remove button listeners
        this.closeBtn_.removeEventListener(MouseEvent.CLICK, this.onCloseClick);
        this.sortNewest_.removeEventListener(MouseEvent.CLICK, this.onSortNewest);
        this.sortOldest_.removeEventListener(MouseEvent.CLICK, this.onSortOldest);
        this.sortLiked_.removeEventListener(MouseEvent.CLICK, this.onSortLiked);
        this.scrollbar_.removeEventListener(Event.CHANGE, this.onScroll);
        this.background_.removeEventListener(MouseEvent.CLICK, this.onBackgroundClick);

        if (parent)
            parent.removeChild(this);
    }
}
}
