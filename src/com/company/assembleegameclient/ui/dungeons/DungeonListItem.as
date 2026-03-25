package com.company.assembleegameclient.ui.dungeons
{
import com.company.assembleegameclient.ui.TextButton;
import com.company.ui.SimpleText;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.text.TextField;
import flash.text.TextFormat;

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
        nameText.text = data.displayName || data.name;
        nameText.updateMetrics();
        nameText.filters = [new DropShadowFilter(0, 0, 0, 1, 2, 2)];
        nameText.x = 15;
        nameText.y = 8;
        addChild(nameText);

        // Difficulty rating
        var diffText:SimpleText = new SimpleText(12, 0xCCCCCC, false, 200, 0);
        var diff:Number = data.difficulty || 0;
        diffText.text = "Difficulty: " + diff.toFixed(1) + " / 10";
        diffText.updateMetrics();
        diffText.x = 15;
        diffText.y = 30;
        addChild(diffText);

        // Like count (device font for heart symbol)
        var likes:int = data.likes || 0;
        var likeField:TextField = new TextField();
        likeField.embedFonts = false;
        likeField.selectable = false;
        likeField.mouseEnabled = false;
        var likeFmt:TextFormat = new TextFormat("Arial", 14, 0xFF6B8A, true);
        likeField.defaultTextFormat = likeFmt;
        likeField.text = "\u2665 " + likes;
        likeField.width = likeField.textWidth + 6;
        likeField.height = likeField.textHeight + 4;
        likeField.x = 300;
        likeField.y = 8;
        addChild(likeField);

        // Rating count
        var rateCountText:SimpleText = new SimpleText(12, 0x888888, false, 0, 0);
        var ratingCount:int = data.ratingCount || 0;
        rateCountText.text = ratingCount + " ratings";
        rateCountText.updateMetrics();
        rateCountText.x = 300;
        rateCountText.y = 28;
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
