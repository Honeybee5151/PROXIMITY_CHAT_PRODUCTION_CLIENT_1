package kabam.rotmg.vault
{
import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.ui.TextBox;
import com.company.assembleegameclient.ui.panels.ButtonPanel;

import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

//editor8182381 — Vault panel (interact panel for vault chest)
public class VaultPanel extends ButtonPanel
{
    public function VaultPanel(gs:GameSprite)
    {
        super(gs, "Vault", "Open");
    }

    override protected function onKeyDown(evt:KeyboardEvent):void
    {
        if (!this.gs_.mui_.setHotkeysInput_ || !this.gs_.mui_.enablePlayerInput_)
            return;
        if (evt.keyCode == Parameters.data_.interact && !TextBox.isInputtingText)
            openVault();
    }

    override protected function onButtonClick(evt:MouseEvent):void
    {
        openVault();
    }

    private function openVault():void
    {
        this.gs_.mui_.setEnablePlayerInput(false);
        this.gs_.mui_.setEnableHotKeysInput(false);
        this.gs_.forceScaledLayer.addChild(new VaultScreen(this.gs_));
    }
}
}
