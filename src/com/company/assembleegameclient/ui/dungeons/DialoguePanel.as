package com.company.assembleegameclient.ui.dungeons
{
import com.company.assembleegameclient.ui.TextButton;
import com.company.ui.SimpleText;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

import kabam.rotmg.game.view.GameSprite;

public class DialoguePanel extends Sprite
{
    private static const PANEL_W:int = 380;
    private static const BASE_H:int = 160;

    private var gs_:GameSprite;
    private var npcId_:int;
    private var options_:Array;

    public function DialoguePanel(gs:GameSprite, data:Object)
    {
        super();
        this.gs_ = gs;
        this.npcId_ = data.npcId;
        this.options_ = data.options;

        var numOptions:int = this.options_.length;
        var panelH:int = BASE_H + (numOptions - 1) * 40;

        // Background
        var g:Graphics = this.graphics;
        g.beginFill(0x1a1a2e, 0.95);
        g.lineStyle(2, 0x5a5a8c);
        g.drawRoundRect(0, 0, PANEL_W, panelH, 10, 10);
        g.endFill();

        // NPC name title
        var title:SimpleText = new SimpleText(18, 0xFFCC00, false, PANEL_W, 0);
        title.setBold(true);
        title.htmlText = "<p align=\"center\">" + data.npcName + "</p>";
        title.filters = [new DropShadowFilter(0, 0, 0, 1, 2, 2)];
        title.updateMetrics();
        title.y = 12;
        addChild(title);

        // Dialogue text
        var textField:SimpleText = new SimpleText(14, 0xFFFFFF, false, PANEL_W - 40, 0);
        textField.wordWrap = true;
        textField.multiline = true;
        textField.htmlText = data.text;
        textField.updateMetrics();
        textField.x = 20;
        textField.y = 42;
        addChild(textField);

        // Option buttons
        var btnY:int = panelH - 20 - numOptions * 40;
        for (var i:int = 0; i < numOptions; i++)
        {
            var opt:Object = this.options_[i];
            var btn:TextButton = new TextButton(14, opt.label, 120);
            btn.x = PANEL_W / 2 - 60;
            btn.y = btnY + i * 40;
            btn.addEventListener(MouseEvent.CLICK, makeClickHandler(opt.id));
            addChild(btn);
        }

        // Center on screen
        this.x = 400 - PANEL_W / 2;
        this.y = 300 - panelH / 2;
    }

    private function makeClickHandler(optionId:int):Function
    {
        var self:DialoguePanel = this;
        return function(e:MouseEvent):void
        {
            self.gs_.gsc_.playerText("/dialogue " + optionId);
            self.close();
        };
    }

    public function close():void
    {
        if (this.parent)
            this.parent.removeChild(this);
    }
}
}
