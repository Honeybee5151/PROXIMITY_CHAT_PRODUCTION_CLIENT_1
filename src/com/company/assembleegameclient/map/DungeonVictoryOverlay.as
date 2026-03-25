package com.company.assembleegameclient.map
{
    import com.company.assembleegameclient.parameters.Parameters;
    import com.company.assembleegameclient.sound.SoundEffectLibrary;

    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;
    import flash.events.TimerEvent;
    import flash.media.Sound;
    import flash.media.SoundTransform;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.Timer;

    public class DungeonVictoryOverlay extends Sprite
    {
        [Embed(source="imagevictory.png")]
        private static var VictoryImage:Class;

        private var fadeTimer:Timer;
        private var fadeStep:int = 0;
        private var totalFadeSteps:int = 20;
        private var holdTimer:Timer;
        private var fadeOutTimer:Timer;
        private var fadeOutStep:int = 0;
        private var screenW:Number;
        private var screenH:Number;

        public function DungeonVictoryOverlay(screenWidth:Number, screenHeight:Number)
        {
            super();
            this.screenW = screenWidth;
            this.screenH = screenHeight;
            this.visible = false;
        }

        public function show():void
        {
            // Clear previous
            while (numChildren > 0) removeChildAt(0);

            // Calculate game viewport width (exclude HUD)
            // HUD is 200px in screen-space, convert to map-space
            var mscale:Number = Parameters.data_.mscale;
            var hudMapW:Number = 200 / mscale;
            var viewW:Number = screenW - hudMapW;

            // Semi-transparent dark backdrop at top (game viewport only)
            var backdrop:Sprite = new Sprite();
            backdrop.graphics.beginFill(0x000000, 0.6);
            backdrop.graphics.drawRect(0, 0, viewW, 160);
            backdrop.graphics.endFill();
            addChild(backdrop);

            // Gold glow line
            var glowLine:Sprite = new Sprite();
            glowLine.graphics.beginFill(0xFFD700, 0.8);
            glowLine.graphics.drawRect(0, 0, viewW, 3);
            glowLine.graphics.endFill();
            glowLine.y = 157;
            addChild(glowLine);

            // Victory image — scale it up (it's pixel art, keep crisp)
            var bmpData:BitmapData = (new VictoryImage() as Bitmap).bitmapData;
            var victoryBmp:Bitmap = new Bitmap(bmpData);
            victoryBmp.smoothing = false;
            victoryBmp.scaleX = 6;
            victoryBmp.scaleY = 6;
            victoryBmp.x = (viewW - victoryBmp.width) / 2;
            victoryBmp.y = 15;
            addChild(victoryBmp);

            // "DUNGEON CLEARED" text below the image
            var tf:TextField = new TextField();
            var fmt:TextFormat = new TextFormat();
            fmt.font = "Myriad Pro";
            fmt.size = 22;
            fmt.color = 0xCCCCCC;
            fmt.align = TextFormatAlign.CENTER;
            fmt.bold = true;
            fmt.letterSpacing = 4;
            tf.defaultTextFormat = fmt;
            tf.embedFonts = true;
            tf.selectable = false;
            tf.width = viewW;
            tf.text = "DUNGEON CLEARED";
            tf.y = victoryBmp.y + victoryBmp.height + 8;
            addChild(tf);

            // Start fade in
            this.alpha = 0;
            this.visible = true;
            fadeStep = 0;

            fadeTimer = new Timer(30, totalFadeSteps);
            fadeTimer.addEventListener(TimerEvent.TIMER, onFadeIn);
            fadeTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onFadeInComplete);
            fadeTimer.start();

            // Play victory sound (independent of SFX toggle, uses own setting)
            playVictorySound();
        }

        private function playVictorySound():void
        {
            if (!Parameters.data_.playVictorySound)
                return;

            try
            {
                var vol:Number = Parameters.data_.victoryVolume;
                var snd:Sound = SoundEffectLibrary.load("victory");
                snd.play(0, 0, new SoundTransform(vol));
            }
            catch (e:Error)
            {
                trace("Victory sound error: " + e.message);
            }
        }

        private function onFadeIn(e:TimerEvent):void
        {
            fadeStep++;
            this.alpha = fadeStep / totalFadeSteps;
        }

        private function onFadeInComplete(e:TimerEvent):void
        {
            fadeTimer.removeEventListener(TimerEvent.TIMER, onFadeIn);
            fadeTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onFadeInComplete);
            this.alpha = 1;

            // Hold for 4 seconds then fade out
            holdTimer = new Timer(4000, 1);
            holdTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onHoldComplete);
            holdTimer.start();
        }

        private function onHoldComplete(e:TimerEvent):void
        {
            holdTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onHoldComplete);

            fadeOutStep = 0;
            fadeOutTimer = new Timer(40, totalFadeSteps);
            fadeOutTimer.addEventListener(TimerEvent.TIMER, onFadeOut);
            fadeOutTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onFadeOutComplete);
            fadeOutTimer.start();
        }

        private function onFadeOut(e:TimerEvent):void
        {
            fadeOutStep++;
            this.alpha = 1 - (fadeOutStep / totalFadeSteps);
        }

        private function onFadeOutComplete(e:TimerEvent):void
        {
            fadeOutTimer.removeEventListener(TimerEvent.TIMER, onFadeOut);
            fadeOutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onFadeOutComplete);
            this.visible = false;
            this.alpha = 0;
        }
    }
}
