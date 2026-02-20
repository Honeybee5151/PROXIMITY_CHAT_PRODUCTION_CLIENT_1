package kabam.rotmg.ProximityChat
{
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.geom.Rectangle;

public class PCSlider extends Sprite
{
    // Slider configuration
    private var _width:Number;
    private var _height:Number;
    private var _x:Number;
    private var _y:Number;
    private var _orientation:String; // "vertical" or "horizontal"

    // Visual properties
    private var _trackColor:uint;
    private var _trackAlpha:Number;
    private var _thumbColor:uint;
    private var _thumbAlpha:Number;
    private var _thumbHoverColor:uint;
    private var _cornerRadius:Number;

    // Functional properties
    private var _minValue:Number;
    private var _maxValue:Number;
    private var _currentValue:Number;
    private var _thumbSize:Number;

    // Components
    private var track:Shape;
    private var thumb:Sprite;

    // Interaction
    private var isDragging:Boolean;
    private var dragOffset:Number;
    private var targetBackground:Sprite; // The background we're controlling

    // Events
    public static const VALUE_CHANGED:String = "valueChanged";

    // Constants
    public static const VERTICAL:String = "vertical";
    public static const HORIZONTAL:String = "horizontal";
    private static const DEFAULT_TRACK_COLOR:uint = 0x333333;
    private static const DEFAULT_THUMB_COLOR:uint = 0x666666;
    private static const DEFAULT_THUMB_HOVER_COLOR:uint = 0x888888;
    private static const DEFAULT_THUMB_SIZE:Number = 20;
    private static const DEFAULT_CORNER_RADIUS:Number = 4;

    public function PCSlider(
            width:Number = 20,
            height:Number = 100,
            x:Number = 0,
            y:Number = 0,
            orientation:String = VERTICAL,
            minValue:Number = 0,
            maxValue:Number = 100
    )
    {
        this._width = width;
        this._height = height;
        this._x = x;
        this._y = y;
        this._orientation = orientation;
        this._minValue = minValue;
        this._maxValue = maxValue;
        this._currentValue = minValue;

        // Set default visual properties
        _trackColor = DEFAULT_TRACK_COLOR;
        _trackAlpha = 0.8;
        _thumbColor = DEFAULT_THUMB_COLOR;
        _thumbAlpha = 1.0;
        _thumbHoverColor = DEFAULT_THUMB_HOVER_COLOR;
        _cornerRadius = DEFAULT_CORNER_RADIUS;
        _thumbSize = DEFAULT_THUMB_SIZE;

        initialize();
    }

    private function initialize():void
    {
        // Create components
        track = new Shape();
        thumb = new Sprite();

        // Add to display list
        addChild(track);
        addChild(thumb);

        // Position the slider
        this.x = _x;
        this.y = _y;

        // Enable mouse interaction
        thumb.buttonMode = true;
        thumb.useHandCursor = true;

        // Add event listeners
        thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        thumb.addEventListener(MouseEvent.MOUSE_OVER, onThumbMouseOver);
        thumb.addEventListener(MouseEvent.MOUSE_OUT, onThumbMouseOut);

        // Draw initial graphics
        redraw();
    }

    private function redraw():void
    {
        drawTrack();
        drawThumb();
        updateThumbPosition();
    }

    private function drawTrack():void
    {
        var g:Graphics = track.graphics;
        g.clear();
        g.beginFill(_trackColor, _trackAlpha);

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

    private function drawThumb():void
    {
        var g:Graphics = thumb.graphics;
        g.clear();
        g.beginFill(_thumbColor, _thumbAlpha);

        var thumbWidth:Number, thumbHeight:Number;

        if (_orientation == VERTICAL)
        {
            thumbWidth = _width;
            thumbHeight = _thumbSize;
        }
        else
        {
            thumbWidth = _thumbSize;
            thumbHeight = _height;
        }

        if (_cornerRadius > 0)
        {
            g.drawRoundRect(0, 0, thumbWidth, thumbHeight, _cornerRadius * 2, _cornerRadius * 2);
        }
        else
        {
            g.drawRect(0, 0, thumbWidth, thumbHeight);
        }

        g.endFill();
    }

    private function updateThumbPosition():void
    {
        if (!thumb || !track || !thumb.parent) {
            return; // Don't update if components are disposed
        }
        var normalizedValue:Number = (_currentValue - _minValue) / (_maxValue - _minValue);

        if (_orientation == VERTICAL)
        {
            var maxThumbY:Number = _height - _thumbSize;
            thumb.y = normalizedValue * maxThumbY;
            thumb.x = 0;
        }
        else
        {
            var maxThumbX:Number = _width - _thumbSize;
            thumb.x = normalizedValue * maxThumbX;
            thumb.y = 0;
        }
    }

    // Event handlers
    private function onThumbMouseDown(e:MouseEvent):void
    {
        isDragging = true;

        if (_orientation == VERTICAL)
        {
            dragOffset = e.localY;
        }
        else
        {
            dragOffset = e.localX;
        }

        stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);

        e.stopPropagation();
    }

    private function onStageMouseMove(e:MouseEvent):void
    {
        if (!isDragging) return;

        var newPosition:Number;
        var maxPosition:Number;

        if (_orientation == VERTICAL)
        {
            newPosition = this.mouseY - dragOffset;
            maxPosition = _height - _thumbSize;
        }
        else
        {
            newPosition = this.mouseX - dragOffset;
            maxPosition = _width - _thumbSize;
        }

        // Clamp position
        newPosition = Math.max(0, Math.min(maxPosition, newPosition));

        // Convert position to value
        var normalizedPosition:Number = newPosition / maxPosition;
        var newValue:Number = _minValue + (normalizedPosition * (_maxValue - _minValue));

        setValue(newValue);
    }

    private function onStageMouseUp(e:MouseEvent):void
    {
        isDragging = false;
        stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
        stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
    }

    private function onThumbMouseOver(e:MouseEvent):void
    {
        var g:Graphics = thumb.graphics;
        g.clear();
        g.beginFill(_thumbHoverColor, _thumbAlpha);

        var thumbWidth:Number = _orientation == VERTICAL ? _width : _thumbSize;
        var thumbHeight:Number = _orientation == VERTICAL ? _thumbSize : _height;

        if (_cornerRadius > 0)
        {
            g.drawRoundRect(0, 0, thumbWidth, thumbHeight, _cornerRadius * 2, _cornerRadius * 2);
        }
        else
        {
            g.drawRect(0, 0, thumbWidth, thumbHeight);
        }

        g.endFill();
    }

    private function onThumbMouseOut(e:MouseEvent):void
    {
        drawThumb();
    }

    // Public methods
    public function setValue(value:Number, dispatchEvent:Boolean = true):void
    {
        var oldValue:Number = _currentValue;
        _currentValue = Math.max(_minValue, Math.min(_maxValue, value));

        updateThumbPosition();

        if (dispatchEvent && oldValue != _currentValue)
        {
            this.dispatchEvent(new Event(VALUE_CHANGED));
            updateTargetBackground();
        }
    }

    public function setRange(minValue:Number, maxValue:Number):void
    {
        _minValue = minValue;
        _maxValue = maxValue;
        setValue(_currentValue, false); // Clamp current value to new range
    }

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
        redraw();
    }

    public function setTrackColor(color:uint, alpha:Number = -1):void
    {
        _trackColor = color;
        if (alpha >= 0) _trackAlpha = alpha;
        drawTrack();
    }

    public function setThumbColor(color:uint, hoverColor:uint = 0, alpha:Number = -1):void
    {
        _thumbColor = color;
        if (hoverColor > 0) _thumbHoverColor = hoverColor;
        if (alpha >= 0) _thumbAlpha = alpha;
        drawThumb();
    }

    public function setThumbSize(size:Number):void
    {
        _thumbSize = size;
        redraw();
    }

    public function setCornerRadius(radius:Number):void
    {
        _cornerRadius = radius;
        redraw();
    }

    // Method to link this slider to a background sprite
    public function setTargetBackground(background:Sprite):void
    {
        targetBackground = background;
        updateTargetBackground();
    }

    private function updateTargetBackground():void
    {
        if (!targetBackground) return;

        // Calculate the scroll offset based on current value
        var normalizedValue:Number = (_currentValue - _minValue) / (_maxValue - _minValue);

        if (_orientation == VERTICAL)
        {
            // Move background up/down (negative for scrolling effect)
            targetBackground.y = -normalizedValue * (targetBackground.height - _height);
        }
        else
        {
            // Move background left/right (negative for scrolling effect)
            targetBackground.x = -normalizedValue * (targetBackground.width - _width);
        }
    }

    // Getters
    public function get value():Number { return _currentValue; }
    public function get minValue():Number { return _minValue; }
    public function get maxValue():Number { return _maxValue; }
    public function get orientation():String { return _orientation; }
    public function get sliderWidth():Number { return _width; }
    public function get sliderHeight():Number { return _height; }

    // Cleanup method
    public function dispose():void
    {
        if (thumb)
        {
            thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
            thumb.removeEventListener(MouseEvent.MOUSE_OVER, onThumbMouseOver);
            thumb.removeEventListener(MouseEvent.MOUSE_OUT, onThumbMouseOut);
        }

        if (stage)
        {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }

        if (track && track.parent) removeChild(track);
        if (thumb && thumb.parent) removeChild(thumb);

        track = null;
        thumb = null;
        targetBackground = null;
    }
}
}