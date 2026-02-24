package com.company.assembleegameclient.ui.dungeons
{
import com.company.assembleegameclient.ui.TextButton;
import com.company.ui.SimpleText;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

public class DungeonListItem extends Sprite
{
    private var data_:Object;
    private var browser_:DungeonBrowser;
    private var enterBtn_:TextButton;
    private var rateBtn_:TextButton;

    public function DungeonListItem(data:Object, width:int, height:int, browser:DungeonBrowser)
    {
        super();
        this.data_ = data;
        this.browser_ = browser;

        // Background
        var g:Graphics = this.graphics;
        g.beginFill(0x12122a, 1);
        g.lineStyle(1, 0x2a2a4a);
        g.drawRoundRect(0, 2, width, height - 4, 8, 8);
        g.endFill();

        // Dungeon name
        var nameText:SimpleText = new SimpleText(16, 0xFFFFFF, false, 0, 0);
        nameText.setBold(true);
        nameText.text = data.name;
        nameText.updateMetrics();
        nameText.filters = [new DropShadowFilter(0, 0, 0, 1, 2, 2)];
        nameText.x = 15;
        nameText.y = 8;
        addChild(nameText);

        // Difficulty stars
        var diffText:SimpleText = new SimpleText(12, 0xCCCCCC, false, 0, 0);
        var diff:Number = data.difficulty || 0;
        var stars:String = "";
        for (var i:int = 1; i <= 5; i++)
        {
            if (diff >= i)
                stars += "\u2605"; // filled star
            else if (diff >= i - 0.5)
                stars += "\u2606"; // half/empty star
            else
                stars += "\u2606"; // empty star
        }
        diffText.text = "Difficulty: " + stars + " (" + diff.toFixed(1) + ")";
        diffText.updateMetrics();
        diffText.x = 15;
        diffText.y = 30;
        addChild(diffText);

        // Like count
        var likeText:SimpleText = new SimpleText(14, 0xFF6B8A, false, 0, 0);
        likeText.setBold(true);
        var likes:int = data.likes || 0;
        likeText.text = "\u2665 " + likes;
        likeText.updateMetrics();
        likeText.x = 300;
        likeText.y = 16;
        addChild(likeText);

        // Rating count
        var rateCountText:SimpleText = new SimpleText(11, 0x888888, false, 0, 0);
        var ratingCount:int = data.ratingCount || 0;
        rateCountText.text = ratingCount + " ratings";
        rateCountText.updateMetrics();
        rateCountText.x = 300;
        rateCountText.y = 33;
        addChild(rateCountText);

        // Enter button
        this.enterBtn_ = new TextButton(13, "Enter", 65);
        this.enterBtn_.x = width - 160;
        this.enterBtn_.y = 12;
        this.enterBtn_.addEventListener(MouseEvent.CLICK, this.onEnterClick);
        addChild(this.enterBtn_);

        // Rate button
        this.rateBtn_ = new TextButton(13, "Rate", 55);
        this.rateBtn_.x = width - 80;
        this.rateBtn_.y = 12;
        this.rateBtn_.addEventListener(MouseEvent.CLICK, this.onRateClick);
        addChild(this.rateBtn_);
    }

    private function onEnterClick(e:MouseEvent):void
    {
        this.browser_.enterDungeon(this.data_.name);
    }

    private function onRateClick(e:MouseEvent):void
    {
        this.browser_.showRatePanel(this.data_);
    }
}
}
