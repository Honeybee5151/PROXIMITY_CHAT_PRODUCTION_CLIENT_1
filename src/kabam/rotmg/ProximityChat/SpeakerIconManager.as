package kabam.rotmg.ProximityChat {

import com.company.assembleegameclient.game.GameSprite;
import com.company.assembleegameclient.map.mapoverlay.SpeakerIcon;
import com.company.assembleegameclient.objects.GameObject;
import com.company.assembleegameclient.objects.Player;

import flash.utils.Dictionary;

//777592 - Manages speaker icons above player heads for proximity voice chat
public class SpeakerIconManager {

    private var gs:GameSprite;
    private var activeIcons:Dictionary; // accountId (int) -> SpeakerIcon
    private var _enabled:Boolean = true;

    public function SpeakerIconManager(gameSprite:GameSprite) {
        this.gs = gameSprite;
        this.activeIcons = new Dictionary();

        // Load saved setting
        var settings:PCSettings = PCSettings.getInstance();
        if (settings) {
            _enabled = settings.getSpeakerIconsEnabled();
        }

        trace("SpeakerIconManager: Initialized, enabled=" + _enabled);
    }

    public function showSpeaker(accountId:int):void {
        if (!_enabled) return;
        if (activeIcons[accountId]) return; // Already showing
        if (!gs || !gs.map || !gs.map.goDict_) return;

        var player:Player = findPlayerByAccountId(accountId);
        if (!player) return;

        var icon:SpeakerIcon = new SpeakerIcon(player);
        activeIcons[accountId] = icon;
        gs.map.mapOverlay_.addChild(icon);
        trace("SpeakerIconManager: Showing icon for account " + accountId);
    }

    public function hideSpeaker(accountId:int):void {
        var icon:SpeakerIcon = activeIcons[accountId] as SpeakerIcon;
        if (icon) {
            icon.remove();
            icon.dispose();
            delete activeIcons[accountId];
        }
    }

    public function setEnabled(value:Boolean):void {
        _enabled = value;
        if (!value) {
            removeAllIcons();
        }
        trace("SpeakerIconManager: enabled=" + value);
    }

    public function get enabled():Boolean {
        return _enabled;
    }

    private function findPlayerByAccountId(accountId:int):Player {
        for each (var go:GameObject in gs.map.goDict_) {
            var p:Player = go as Player;
            if (p && p.accountId_ == accountId) {
                return p;
            }
        }
        return null;
    }

    private function removeAllIcons():void {
        for (var id:* in activeIcons) {
            var icon:SpeakerIcon = activeIcons[id] as SpeakerIcon;
            if (icon) {
                icon.remove();
                icon.dispose();
            }
            delete activeIcons[id];
        }
    }

    public function dispose():void {
        removeAllIcons();
        gs = null;
    }
}
}
