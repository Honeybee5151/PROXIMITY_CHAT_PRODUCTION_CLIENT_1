package com.company.assembleegameclient.objects {
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.ui.panels.Panel;
import com.company.assembleegameclient.ui.panels.DungeonBrowserButton;

public class DungeonBrowserNPC extends GameObject implements IInteractiveObject {

    public function DungeonBrowserNPC(xml:XML) {
        super(xml);
        isInteractive_ = true;
        trace("[DungeonBrowserNPC] Created! isInteractive=" + isInteractive_ + " type=" + objectType_);
    }

    public function getPanel(gs:GameSprite):Panel {
        return new DungeonBrowserButton(gs);
    }
}
}
