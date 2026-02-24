package com.company.assembleegameclient.ui.panels {
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.ui.TextButton;
import com.company.assembleegameclient.ui.dungeons.DungeonBrowser;
import com.company.ui.SimpleText;

import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;

public class DungeonBrowserButton extends Panel {

    private var title_:SimpleText;
    private var browseBtn_:TextButton;

    public function DungeonBrowserButton(gs:GameSprite) {
        super(gs);

        this.title_ = new SimpleText(18, 0xFFFFFF, false, Panel.WIDTH, 0);
        this.title_.setBold(true);
        this.title_.htmlText = "<p align=\"center\">Dungeon Browser</p>";
        this.title_.filters = [new DropShadowFilter(0, 0, 0)];
        this.title_.updateMetrics();
        this.title_.x = 0;
        this.title_.y = 0;
        addChild(this.title_);

        this.browseBtn_ = new TextButton(16, "Browse Dungeons", 150);
        this.browseBtn_.x = (Panel.WIDTH - 150) / 2;
        this.browseBtn_.y = 30;
        this.browseBtn_.addEventListener(MouseEvent.CLICK, this.onBrowseClick);
        addChild(this.browseBtn_);
    }

    private function onBrowseClick(e:MouseEvent):void {
        gs_.forceScaledLayer.addChild(new DungeonBrowser(gs_));
    }
}
}
