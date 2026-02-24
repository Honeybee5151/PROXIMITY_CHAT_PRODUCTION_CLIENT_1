package kabam.rotmg.assets
{
import com.company.assembleegameclient.map.GroundLibrary;
import com.company.assembleegameclient.objects.ObjectLibrary;
import com.company.util.AssetLibrary;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.TimerEvent;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.utils.Timer;

import com.company.assembleegameclient.parameters.Parameters;

public class CommunityContentLoader
{
    private var _serverUrl:String;
    private var _pendingCount:int = 0;
    private var _callback:Function;
    private var _timers:Array = [];
    private var _loaders:Array = [];

    private static const TIMEOUT_MS:int = 5000;

    private static const SPRITES:Array = [
        ["/sprites/communitySprites8x8.png", "communitySprites8x8", 8, 8],
        ["/sprites/communitySprites16x16.png", "communitySprites16x16", 16, 16]
    ];

    private static const XMLS:Array = [
        ["/community/xml/CustomObjects.xml", "objects"],
        ["/community/xml/CustomItems.xml", "objects"],
        ["/community/xml/CustomProj.xml", "objects"]
        // CustomGrounds.xml loaded per-dungeon via CUSTOM_GROUNDS packet
    ];

    private var _pendingSpriteCount:int = 0;

    public function load(callback:Function = null):void
    {
        _callback = callback;

        if (Parameters.TESTING_SERVER)
            _serverUrl = "http://127.0.0.1:8089";
        else
            _serverUrl = "http://89.167.53.217:8888";

        trace("[CommunityContent] Loading " + (SPRITES.length + XMLS.length) + " assets from " + _serverUrl);

        // Load sprites first, then XMLs (XMLs need sprite sheets to resolve AnimatedTexture)
        _pendingSpriteCount = SPRITES.length;
        _pendingCount = XMLS.length;

        var i:int;
        for (i = 0; i < SPRITES.length; i++)
        {
            loadSprite(SPRITES[i][0] as String, SPRITES[i][1] as String, SPRITES[i][2] as int, SPRITES[i][3] as int);
        }
    }

    private function onAllSpritesLoaded():void
    {
        trace("[CommunityContent] All sprites loaded, now loading XMLs");
        var i:int;
        for (i = 0; i < XMLS.length; i++)
        {
            loadXml(XMLS[i][0] as String, XMLS[i][1] as String);
        }
    }

    private function loadSprite(path:String, assetName:String, tileW:int, tileH:int):void
    {
        var loader:Loader = new Loader();
        _loaders.push(loader);

        var timer:Timer = new Timer(TIMEOUT_MS, 1);
        _timers.push(timer);

        var self:CommunityContentLoader = this;
        var done:Boolean = false;

        timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void
        {
            if (done) return;
            done = true;
            trace("[CommunityContent] Timeout loading sprite: " + assetName);
            try { loader.close(); } catch (err:Error) {}
            self.onSpriteDone();
        });

        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void
        {
            if (done) return;
            done = true;
            timer.stop();

            try
            {
                var newBitmap:BitmapData = (loader.content as Bitmap).bitmapData;
                var oldBitmap:BitmapData = AssetLibrary.getImage(assetName);
                if (oldBitmap != null)
                {
                    oldBitmap.dispose();
                }
                AssetLibrary.addImageSet(assetName, newBitmap, tileW, tileH);
                trace("[CommunityContent] Loaded sprite: " + assetName + " (" + newBitmap.width + "x" + newBitmap.height + ")");
            }
            catch (err:Error)
            {
                trace("[CommunityContent] Error processing sprite " + assetName + ": " + err.message);
            }

            self.onSpriteDone();
        });

        loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
        {
            if (done) return;
            done = true;
            timer.stop();
            trace("[CommunityContent] Failed to load sprite: " + assetName + " - " + e.text);
            self.onSpriteDone();
        });

        timer.start();
        loader.load(new URLRequest(_serverUrl + path));
    }

    private function loadXml(path:String, type:String):void
    {
        var urlLoader:URLLoader = new URLLoader();
        _loaders.push(urlLoader);

        var timer:Timer = new Timer(TIMEOUT_MS, 1);
        _timers.push(timer);

        var self:CommunityContentLoader = this;
        var done:Boolean = false;

        timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void
        {
            if (done) return;
            done = true;
            trace("[CommunityContent] Timeout loading XML: " + path);
            try { urlLoader.close(); } catch (err:Error) {}
            self.onAssetDone();
        });

        urlLoader.addEventListener(Event.COMPLETE, function(e:Event):void
        {
            if (done) return;
            done = true;
            timer.stop();

            try
            {
                var xml:XML = XML(urlLoader.data);
                if (type == "grounds")
                {
                    GroundLibrary.parseFromXML(xml);
                    trace("[CommunityContent] Loaded ground XML: " + path);
                }
                else
                {
                    ObjectLibrary.parseFromXML(xml);
                    trace("[CommunityContent] Loaded object XML: " + path);
                }
            }
            catch (err:Error)
            {
                trace("[CommunityContent] Error parsing XML " + path + ": " + err.message);
            }

            self.onAssetDone();
        });

        urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void
        {
            if (done) return;
            done = true;
            timer.stop();
            trace("[CommunityContent] Failed to load XML: " + path + " - " + e.text);
            self.onAssetDone();
        });

        timer.start();
        urlLoader.load(new URLRequest(_serverUrl + path));
    }

    private function onSpriteDone():void
    {
        _pendingSpriteCount--;
        if (_pendingSpriteCount <= 0)
        {
            onAllSpritesLoaded();
        }
    }

    private function onAssetDone():void
    {
        _pendingCount--;
        if (_pendingCount <= 0)
        {
            trace("[CommunityContent] All downloads complete");
            dispose();
            if (_callback != null) _callback();
        }
    }

    public function dispose():void
    {
        var i:int;
        for (i = 0; i < _timers.length; i++)
        {
            (_timers[i] as Timer).stop();
        }
        _timers = [];
        _loaders = [];
        _callback = null;
    }
}
}
