package kabam.rotmg.ProximityChat
{
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.utils.Timer;

public class PCVisualiser extends Sprite
{
    // Configuration
    private var _width:Number;
    private var _height:Number;
    private var _x:Number;
    private var _y:Number;

    // Visual properties
    private var _backgroundColor:uint;
    private var _backgroundAlpha:Number;
    private var _borderColor:uint;
    private var _borderThickness:Number;
    private var _cornerRadius:Number;

    // Visualizer properties
    private var _barCount:int;
    private var _barSpacing:Number;
    private var _barWidth:Number;
    private var _activeColor:uint;
    private var _inactiveColor:uint;
    private var _peakColor:uint;

    // Audio data
    private var _audioLevel:Number; // 0.0 to 1.0
    private var _peakLevel:Number;
    private var _smoothedLevel:Number;
    private var _isActive:Boolean;

    // Components
    private var background:Shape;
    private var bars:Vector.<Shape>;
    private var peakBar:Shape;

    // Animation
    private var updateTimer:Timer;
    private var _smoothing:Number;
    private var _peakDecay:Number;

    // Constants
    private static const DEFAULT_WIDTH:Number = 60;
    private static const DEFAULT_HEIGHT:Number = 25;
    private static const DEFAULT_BAR_COUNT:int = 8;
    private static const DEFAULT_BG_COLOR:uint = 0x1a1a1a;
    private static const DEFAULT_BG_ALPHA:Number = 0.8;
    private static const DEFAULT_BORDER_COLOR:uint = 0x444444;
    private static const DEFAULT_ACTIVE_COLOR:uint = 0x44aa44;    // Green
    private static const DEFAULT_INACTIVE_COLOR:uint = 0x333333;  // Dark gray
    private static const DEFAULT_PEAK_COLOR:uint = 0xffaa44;      // Orange
    private static const DEFAULT_SMOOTHING:Number = 0.3;
    private static const DEFAULT_PEAK_DECAY:Number = 0.95;


    private var storedMicrophones:Array;

    // Reference to the PCManager for UI updates
    public var currentPCManager:PCManager;

    // Reference to settings
    public var settings:PCSettings;

    // Events
    public static const LEVEL_CHANGED:String = "levelChanged";

    public function PCVisualiser (
            x:Number = 0,
            y:Number = 0,
            width:Number = DEFAULT_WIDTH,
            height:Number = DEFAULT_HEIGHT,
            barCount:int = DEFAULT_BAR_COUNT
    )
    {
        this._x = x;
        this._y = y;
        this._width = width;
        this._height = height;
        this._barCount = barCount;

        // Set default visual properties
        _backgroundColor = DEFAULT_BG_COLOR;
        _backgroundAlpha = DEFAULT_BG_ALPHA;
        _borderColor = DEFAULT_BORDER_COLOR;
        _borderThickness = 1;
        _cornerRadius = 4;
        _activeColor = DEFAULT_ACTIVE_COLOR;
        _inactiveColor = DEFAULT_INACTIVE_COLOR;
        _peakColor = DEFAULT_PEAK_COLOR;

        // Initialize audio properties
        _audioLevel = 0.0;
        _peakLevel = 0.0;
        _smoothedLevel = 0.0;
        _isActive = false;
        _smoothing = DEFAULT_SMOOTHING;
        _peakDecay = DEFAULT_PEAK_DECAY;

        initialize();
    }

    private function initialize():void
    {
        // Position the visualizer
        this.x = _x;
        this.y = _y;
        onMicrophonesReceived(storedMicrophones);
        // Calculate bar dimensions
        calculateBarDimensions();

        // Create components
        createBackground();
        createBars();

        // Set up animation timer
        updateTimer = new Timer(16); // ~60 FPS
        updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer);
        updateTimer.start();

    }

    private function calculateBarDimensions():void
    {
        var availableWidth:Number = _width - (_borderThickness * 2) - 4; // 2px padding on each side
        _barSpacing = 1;
        _barWidth = (availableWidth - ((_barCount - 1) * _barSpacing)) / _barCount;
    }

    private function createBackground():void
    {
        background = new Shape();
        addChild(background);
        drawBackground();
    }

    private function drawBackground():void
    {
        var g:Graphics = background.graphics;
        g.clear();
        g.beginFill(_backgroundColor, _backgroundAlpha);
        g.lineStyle(_borderThickness, _borderColor, 1);

        if (_cornerRadius > 0)
        {
            g.drawRoundRect(0, 0, _width, _height, _cornerRadius * 2, _cornerRadius * 2);
        }
        else
        {
            g.drawRect(0, 0, _width, _height);
        }

        g.endFill();
    }
    private function onMicrophonesReceived(mics:Array):void {
        if (!mics || mics.length == 0) {
            trace("VoiceChatService: No microphones received.");
            return;
        }

        storedMicrophones = mics;
        trace("VoiceChatService: Microphones received:", storedMicrophones.length);

        // Determine initial mic from saved settings
        var initialMicId:String = null;
        if (settings != null) {
            if (settings.hasSavedMicrophone()) {
                var savedMic:Object = settings.applySavedMicrophone(storedMicrophones);
                if (savedMic != null && savedMic.Id != null) {
                    initialMicId = savedMic.Id;
                    trace("VoiceChatService: Initial mic to select:", savedMic.Name ? savedMic.Name : "Unknown");
                } else {
                    trace("VoiceChatService: Saved microphone not available.");
                }
            } else {
                trace("VoiceChatService: No saved microphone found.");
            }
        } else {
            trace("VoiceChatService: Settings not initialized.");
        }

        // Notify manager safely
        if (currentPCManager != null && typeof(currentPCManager.setAvailableMicrophones) == "function") {
            currentPCManager.setAvailableMicrophones(mics);
            if (initialMicId != null && typeof(currentPCManager.updateMicrophoneSelection) == "function") {
                currentPCManager.updateMicrophoneSelection(initialMicId);
            }
        } else {
            trace("VoiceChatService: PCManager not ready yet.");



        }


    }
    private function createBars():void
    {
        bars = new Vector.<Shape>();

        var startX:Number = _borderThickness + 2; // 2px padding
        var startY:Number = _borderThickness + 2;
        var availableHeight:Number = _height - (_borderThickness * 2) - 4; // 2px padding top/bottom

        for (var i:int = 0; i < _barCount; i++)
        {
            var bar:Shape = new Shape();
            bar.x = startX + (i * (_barWidth + _barSpacing));
            bar.y = startY;
            addChild(bar);
            bars.push(bar);
        }

        // Create peak indicator bar (separate from regular bars)
        peakBar = new Shape();
        peakBar.x = startX;
        peakBar.y = startY;
        addChild(peakBar);

        updateBars();
    }

    private function onUpdateTimer(e:TimerEvent):void
    {
        // ADD THIS DEBUG (but maybe only occasionally)
        if (Math.random() < 0.1) { // Only 10% of the time to avoid spam
           // trace("PCVisualiser: Timer update - audioLevel:", _audioLevel, "smoothed:", _smoothedLevel);
        }
        // Smooth the audio level
        _smoothedLevel += (_audioLevel - _smoothedLevel) * _smoothing;

        // Update peak level
        if (_smoothedLevel > _peakLevel)
        {
            _peakLevel = _smoothedLevel;
        }
        else
        {
            _peakLevel *= _peakDecay;
        }

        // Update visual bars
        updateBars();
    }

    private function updateBars():void
    {
        var availableHeight:Number = _height - (_borderThickness * 2) - 4;
        var activeBars:int = Math.floor(_smoothedLevel * _barCount);
        var peakBarIndex:int = Math.floor(_peakLevel * _barCount);

        // Update regular bars
        for (var i:int = 0; i < _barCount; i++)
        {
            var bar:Shape = bars[i];
            var g:Graphics = bar.graphics;
            g.clear();

            var isActive:Boolean = i < activeBars;
            var color:uint = isActive ? _activeColor : _inactiveColor;
            var alpha:Number = isActive ? 1.0 : 0.3;

            g.beginFill(color, alpha);
            g.drawRect(0, 0, _barWidth, availableHeight);
            g.endFill();
        }

        // Update peak bar (thin line at peak level)
        /*var peakG:Graphics = peakBar.graphics;
        peakG.clear();

        if (_peakLevel > 0.05 && peakBarIndex < _barCount && peakBarIndex >= activeBars)
        {
            var peakX:Number = peakBarIndex * (_barWidth + _barSpacing);
            peakG.beginFill(_peakColor, 0.8);
            peakG.drawRect(peakX, 0, _barWidth, 2); // Thin 2px line
            peakG.endFill();
        }
        */

    }

    // Public methods for audio input
    public function setAudioLevel(level:Number):void
    {
        var boostedLevel:Number = level * 2.0;
        // Clamp level between 0 and 1
        _audioLevel = Math.max(0, Math.min(1, boostedLevel));
        _isActive = _audioLevel > 0.01;

        // ADD THIS DEBUG
        trace("PCVisualiser: setAudioLevel called with:", level, "clamped to:", _audioLevel);

        dispatchEvent(new Event(LEVEL_CHANGED));
    }
    public function setAudioLevelFromDB(dbLevel:Number, minDB:Number = -60, maxDB:Number = 0):void
    {
        // Convert dB to 0-1 range
        var normalizedLevel:Number = (dbLevel - minDB) / (maxDB - minDB);
        setAudioLevel(normalizedLevel);
    }

    public function setAudioLevelFromInt(intLevel:int, maxValue:int = 100):void
    {
        // Convert integer value to 0-1 range
        var normalizedLevel:Number = intLevel / maxValue;
        setAudioLevel(normalizedLevel);
    }

    // Methods for C# integration
    public function updateFromCSharp(levelString:String):void
    {
        try
        {
            var level:Number = parseFloat(levelString);
            setAudioLevel(level);
        }
        catch (e:Error)
        {
            trace("Error parsing audio level:", levelString);
        }
    }

    public function updateFromCSharpInt(levelInt:int, maxValue:int = 100):void
    {
        setAudioLevelFromInt(levelInt, maxValue);
    }

    public function updateFromCSharpDB(dbLevel:Number):void
    {
        setAudioLevelFromDB(dbLevel);
    }

    // Configuration methods
    public function setPosition(x:Number, y:Number):void
    {
        this._x = x;
        this._y = y;
        this.x = x;
        this.y = y;
    }

    public function setSize(width:Number, height:Number):void
    {
        this._width = width;
        this._height = height;
        calculateBarDimensions();
        drawBackground();
        repositionBars();
    }

    private function repositionBars():void
    {
        var startX:Number = _borderThickness + 2;
        var startY:Number = _borderThickness + 2;

        for (var i:int = 0; i < bars.length; i++)
        {
            bars[i].x = startX + (i * (_barWidth + _barSpacing));
            bars[i].y = startY;
        }

        peakBar.x = startX;
        peakBar.y = startY;
    }

    public function setColors(activeColor:uint, inactiveColor:uint, peakColor:uint = 0):void
    {
        _activeColor = activeColor;
        _inactiveColor = inactiveColor;
        if (peakColor > 0) _peakColor = peakColor;
    }

    public function setBackgroundStyle(color:uint, alpha:Number = -1, borderColor:uint = 0, borderThickness:Number = -1):void
    {
        _backgroundColor = color;
        if (alpha >= 0) _backgroundAlpha = alpha;
        if (borderColor > 0) _borderColor = borderColor;
        if (borderThickness >= 0) _borderThickness = borderThickness;
        drawBackground();
    }

    public function setCornerRadius(radius:Number):void
    {
        _cornerRadius = radius;
        drawBackground();
    }

    public function setBarCount(count:int):void
    {
        // Remove existing bars
        for (var i:int = 0; i < bars.length; i++)
        {
            removeChild(bars[i]);
        }
        bars = new Vector.<Shape>();

        _barCount = count;
        calculateBarDimensions();
        createBars();
    }

    public function setSmoothing(smoothing:Number):void
    {
        _smoothing = Math.max(0.01, Math.min(1.0, smoothing));
    }

    public function setPeakDecay(decay:Number):void
    {
        _peakDecay = Math.max(0.8, Math.min(0.99, decay));
    }

    // Getters
    public function get audioLevel():Number { return _audioLevel; }
    public function get smoothedLevel():Number { return _smoothedLevel; }
    public function get peakLevel():Number { return _peakLevel; }
    public function get isActive():Boolean { return _isActive; }
    public function get visualizerWidth():Number { return _width; }
    public function get visualizerHeight():Number { return _height; }

    // Control methods
    public function start():void
    {
        if (updateTimer && !updateTimer.running)
        {
            updateTimer.start();
        }
    }

    public function stop():void
    {
        if (updateTimer && updateTimer.running)
        {
            updateTimer.stop();
        }

        // Reset levels
        _audioLevel = 0;
        _smoothedLevel = 0;
        _peakLevel = 0;
        updateBars();
    }

    public function reset():void
    {
        _audioLevel = 0;
        _smoothedLevel = 0;
        _peakLevel = 0;
        updateBars();
    }

    // Cleanup method
    public function dispose():void
    {
        // Stop timer
        if (updateTimer)
        {
            updateTimer.stop();
            updateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimer);
            updateTimer = null;
        }

        // Remove bars
        if (bars)
        {
            for (var i:int = 0; i < bars.length; i++)
            {
                if (bars[i] && bars[i].parent) removeChild(bars[i]);
            }
            bars = null;
        }

        // Remove other components
        if (peakBar && peakBar.parent) removeChild(peakBar);
        if (background && background.parent) removeChild(background);

        peakBar = null;
        background = null;
    }
}
}