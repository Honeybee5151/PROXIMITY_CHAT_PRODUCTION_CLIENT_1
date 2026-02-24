package com.company.assembleegameclient.ui.panels {
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.ui.TextBox;
import com.company.assembleegameclient.ui.TextButton;
import com.company.assembleegameclient.ui.dungeons.DungeonBrowser;
import com.company.ui.SimpleText;

import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;

public class DungeonBrowserButton extends Panel {

    private var title_:SimpleText;
    private var browseBtn_:TextButton;

    public function DungeonBrowserButton(gs:GameSprite) {
        super(gs);

        this.title_ = new SimpleText(18, 0xFFFFFF, false, Panel.WIDTH, 0);
        this.title_.setBold(true);
        this.title_.htmlText = "<p align=\"center\">Dungeon Browser</p>";
        this.title_.wordWrap = true;
        this.title_.multiline = true;
        this.title_.autoSize = TextFieldAutoSize.CENTER;
        this.title_.filters = [new DropShadowFilter(0, 0, 0)];
        this.title_.updateMetrics();
        addChild(this.title_);

        this.browseBtn_ = new TextButton(16, "Browse");
        addChild(this.browseBtn_);

        addEventListener(Event.ADDED_TO_STAGE, this.onAddedToStage);
        addEventListener(Event.REMOVED_FROM_STAGE, this.onRemovedFromStage);
    }

    private function onAddedToStage(e:Event):void {
        this.title_.y = 6;
        this.browseBtn_.x = Panel.WIDTH / 2 - this.browseBtn_.width / 2;
        this.browseBtn_.y = Panel.HEIGHT - this.browseBtn_.height - 4;
        this.browseBtn_.addEventListener(MouseEvent.CLICK, this.onBrowseClick);
        stage.addEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
    }

    private function onRemovedFromStage(e:Event):void {
        stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.onKeyDown);
    }

    private function onKeyDown(e:KeyboardEvent):void {
        // Don't open browser if a TextField has focus (user is typing in DungeonBrowser)
        if (stage.focus is TextField)
            return;
        if (e.keyCode == Parameters.data_.interact && !TextBox.isInputtingText) {
            this.onBrowseClick(null);
        }
    }

    private function onBrowseClick(e:MouseEvent):void {
        gs_.forceScaledLayer.addChild(new DungeonBrowser(gs_));
    }
}
}
