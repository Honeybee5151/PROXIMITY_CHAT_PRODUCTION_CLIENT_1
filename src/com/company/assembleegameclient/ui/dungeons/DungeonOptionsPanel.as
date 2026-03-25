package com.company.assembleegameclient.ui.dungeons
{
import com.company.assembleegameclient.ui.TextButton;
import com.company.ui.SimpleText;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

public class DungeonOptionsPanel extends Sprite
{
    private static const PANEL_W:int = 320;
    private static const PANEL_H:int = 280;

    private var browser_:DungeonBrowser;
    private var selected_:int;
    private var buttons_:Vector.<Sprite> = new Vector.<Sprite>();

    private static const NAMES:Array = ["Peaceful", "Easy", "Medium", "Hard"];
    private static const DESCS:Array = [
        "Infinite lives, normal damage",
        "1 life, normal damage",
        "1 life, 1.33x damage",
        "1 life, 1.77x damage"
    ];
    private static const COLORS:Array = [0x44CC44, 0xFFFFFF, 0xFFCC00, 0xFF4444];

    public function DungeonOptionsPanel(browser:DungeonBrowser, currentDifficulty:int)
    {
        super();
        this.browser_ = browser;
        this.selected_ = currentDifficulty;

        // Background
        var g:Graphics = this.graphics;
        g.beginFill(0x1a1a2e, 1);
        g.lineStyle(2, 0x5a5a8c);
        g.drawRoundRect(0, 0, PANEL_W, PANEL_H, 10, 10);
        g.endFill();

        // Title
        var title:SimpleText = new SimpleText(18, 0xFFFFFF, false, PANEL_W, 0);
        title.setBold(true);
        title.htmlText = "<p align=\"center\">Select Difficulty</p>";
        title.filters = [new DropShadowFilter(0, 0, 0, 1, 2, 2)];
        title.updateMetrics();
        title.y = 12;
        addChild(title);

        // Difficulty buttons
        for (var i:int = 0; i < 4; i++)
        {
            var btn:Sprite = createDiffButton(i, NAMES[i], DESCS[i], COLORS[i]);
            btn.x = 15;
            btn.y = 45 + i * 48;
            btn.addEventListener(MouseEvent.CLICK, makeClickHandler(i));
            addChild(btn);
            this.buttons_.push(btn);
        }

        updateHighlight();

        // Confirm button
        var confirmBtn:TextButton = new TextButton(14, "Confirm", 80);
        confirmBtn.x = PANEL_W / 2 - 90;
        confirmBtn.y = PANEL_H - 40;
        confirmBtn.addEventListener(MouseEvent.CLICK, this.onConfirm);
        addChild(confirmBtn);

        // Cancel button
        var cancelBtn:TextButton = new TextButton(14, "Cancel", 80);
        cancelBtn.x = PANEL_W / 2 + 10;
        cancelBtn.y = PANEL_H - 40;
        cancelBtn.addEventListener(MouseEvent.CLICK, this.onCancel);
        addChild(cancelBtn);
    }

    private function createDiffButton(index:int, name:String, desc:String, color:uint):Sprite
    {
        var s:Sprite = new Sprite();
        s.buttonMode = true;
        s.useHandCursor = true;

        // Background (will be updated by highlight)
        var bg:Sprite = new Sprite();
        bg.name = "bg";
        var g:Graphics = bg.graphics;
        g.beginFill(0x0f0f1e, 1);
        g.lineStyle(1, 0x3a3a5c);
        g.drawRoundRect(0, 0, PANEL_W - 30, 42, 8, 8);
        g.endFill();
        s.addChild(bg);

        // Name
        var nameText:SimpleText = new SimpleText(15, color, false, 0, 0);
        nameText.setBold(true);
        nameText.text = name;
        nameText.updateMetrics();
        nameText.x = 12;
        nameText.y = 4;
        nameText.mouseEnabled = false;
        s.addChild(nameText);

        // Description
        var descText:SimpleText = new SimpleText(11, 0xAAAAAA, false, 0, 0);
        descText.text = desc;
        descText.updateMetrics();
        descText.x = 12;
        descText.y = 23;
        descText.mouseEnabled = false;
        s.addChild(descText);

        return s;
    }

    private function makeClickHandler(index:int):Function
    {
        var self:DungeonOptionsPanel = this;
        return function(e:MouseEvent):void
        {
            self.selected_ = index;
            self.updateHighlight();
        };
    }

    private function updateHighlight():void
    {
        for (var i:int = 0; i < this.buttons_.length; i++)
        {
            var btn:Sprite = this.buttons_[i];
            var bg:Sprite = btn.getChildByName("bg") as Sprite;
            if (bg)
            {
                bg.graphics.clear();
                if (i == this.selected_)
                {
                    bg.graphics.beginFill(0x2a2a4a, 1);
                    bg.graphics.lineStyle(2, COLORS[i] as uint);
                }
                else
                {
                    bg.graphics.beginFill(0x0f0f1e, 1);
                    bg.graphics.lineStyle(1, 0x3a3a5c);
                }
                bg.graphics.drawRoundRect(0, 0, PANEL_W - 30, 42, 8, 8);
                bg.graphics.endFill();
            }
        }
    }

    private function onConfirm(e:MouseEvent):void
    {
        this.browser_.setSelectedDifficulty(this.selected_);
        this.browser_.closeOptionsPanel();
    }

    private function onCancel(e:MouseEvent):void
    {
        this.browser_.closeOptionsPanel();
    }
}
}
