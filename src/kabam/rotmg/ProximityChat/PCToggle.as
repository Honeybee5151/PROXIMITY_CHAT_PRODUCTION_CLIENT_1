package kabam.rotmg.ProximityChat {

import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCToggle extends Sprite
{
    // Configuration
    private var _width:Number;
    private var _height:Number;
    private var _x:Number;
    private var _y:Number;

    // Visual properties
    private var _onColor:uint;
    private var _offColor:uint;
    private var _hoverOnColor:uint;
    private var _hoverOffColor:uint;
    private var _borderColor:uint;
    private var _textColor:uint;
    private var _cornerRadius:Number;

    // State
    private var _isOn:Boolean;
    private var _isHovering:Boolean;

    // Components
    private var background:Shape;
    private var label:TextField;

    // Text labels
    private var _onText:String;
    private var _offText:String;

    // Constants
    private static const DEFAULT_WIDTH:Number = 100;
    private static const DEFAULT_HEIGHT:Number = 30;
    private static const DEFAULT_ON_COLOR:uint = 0x2d5a2d;      // Dark green
    private static const DEFAULT_OFF_COLOR:uint = 0x5a2d2d;     // Dark red
    private static const DEFAULT_HOVER_ON_COLOR:uint = 0x3d7a3d; // Lighter green
    private static const DEFAULT_HOVER_OFF_COLOR:uint = 0x7a3d3d; // Lighter red
    private static const DEFAULT_BORDER_COLOR:uint = 0x666666;
    private static const DEFAULT_TEXT_COLOR:uint = 0xffffff;
    private static const DEFAULT_CORNER_RADIUS:Number = 6;

    // Events
    public static const TOGGLE_CHANGED:String = "toggleChanged";

    public function PCToggle (
            x:Number = 0,
            y:Number = 0,
            width:Number = DEFAULT_WIDTH,
            height:Number = DEFAULT_HEIGHT,
            onText:String = "ON",
            offText:String = "OFF",
            initialState:Boolean = false
    )
    {
        this._x = x;
        this._y = y;
        this._width = width;
        this._height = height;
        this._onText = onText;
        this._offText = offText;
        this._isOn = initialState;
        this._isHovering = false;

        // Set default visual properties
        _onColor = DEFAULT_ON_COLOR;
        _offColor = DEFAULT_OFF_COLOR;
        _hoverOnColor = DEFAULT_HOVER_ON_COLOR;
        _hoverOffColor = DEFAULT_HOVER_OFF_COLOR;
        _borderColor = DEFAULT_BORDER_COLOR;
        _textColor = DEFAULT_TEXT_COLOR;
        _cornerRadius = DEFAULT_CORNER_RADIUS;

        initialize();
    }

    private function initialize():void
    {
        // Position the toggle
        this.x = _x;
        this.y = _y;

        // Create components
        background = new Shape();
        addChild(background);

        // Create label
        label = new TextField();
        label.autoSize = TextFieldAutoSize.CENTER;
        label.selectable = false;
        label.mouseEnabled = false;
        label.textColor = _textColor;
        addChild(label);

        // Set up mouse interaction
        this.buttonMode = true;
        this.useHandCursor = true;

        // Add event listeners
        addEventListener(MouseEvent.CLICK, onToggleClick);
        addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        // Draw initial state
        updateVisuals();
    }

    private function updateVisuals():void
    {
        // Update label text
        label.text = _isOn ? _onText : _offText;
        centerLabel();

        // Update background color
        drawBackground();
        trace("PCToggle: updateVisuals called, _isOn =", _isOn);

        // Clear previous graphics
        graphics.clear();

        // Your existing visual update code...
        // Then add this at the end:

        trace("PCToggle: Visual update complete, button should appear:", _isOn ? "ON" : "OFF");
    }

    private function centerLabel():void
    {
        label.x = (_width - label.width) / 2;
        label.y = (_height - label.height) / 2;
    }

    private function drawBackground():void
    {
        var color:uint;

        if (_isHovering)
        {
            color = _isOn ? _hoverOnColor : _hoverOffColor;
        }
        else
        {
            color = _isOn ? _onColor : _offColor;
        }

        var g:Graphics = background.graphics;
        g.clear();
        g.beginFill(color, 1);
        g.lineStyle(1, _borderColor, 1);

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

    // Event handlers
    private function onToggleClick(e:MouseEvent):void
    {
        toggle();
    }

    private function onMouseOver(e:MouseEvent):void
    {
        _isHovering = true;
        drawBackground();
    }

    private function onMouseOut(e:MouseEvent):void
    {
        _isHovering = false;
        drawBackground();
    }

    // Public methods
    public function toggle():void
    {
        setState(!_isOn);
    }

    public function setState(isOn:Boolean, dispatchEvent:Boolean = true):void
    {
        if (_isOn == isOn) return;

        _isOn = isOn;
        updateVisuals();

        if (dispatchEvent)
        {
            this.dispatchEvent(new Event(TOGGLE_CHANGED));
        }
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
        updateVisuals();
    }

    public function setColors(onColor:uint, offColor:uint, hoverOnColor:uint = 0, hoverOffColor:uint = 0):void
    {
        _onColor = onColor;
        _offColor = offColor;

        if (hoverOnColor > 0) _hoverOnColor = hoverOnColor;
        if (hoverOffColor > 0) _hoverOffColor = hoverOffColor;

        drawBackground();
    }

    public function setBorderColor(color:uint):void
    {
        _borderColor = color;
        drawBackground();
    }

    public function setTextColor(color:uint):void
    {
        _textColor = color;
        label.textColor = color;
    }

    public function setCornerRadius(radius:Number):void
    {
        _cornerRadius = radius;
        drawBackground();
    }

    public function setLabels(onText:String, offText:String):void
    {
        _onText = onText;
        _offText = offText;
        updateVisuals();
    }

    // Getters
    public function get isOn():Boolean { return _isOn; }
    public function get isOff():Boolean { return !_isOn; }
    public function get toggleWidth():Number { return _width; }
    public function get toggleHeight():Number { return _height; }
    public function get onText():String { return _onText; }
    public function get offText():String { return _offText; }

    // Method for C# integration - returns current state as string
    public function getStateString():String
    {
        return _isOn ? "ON" : "OFF";
    }

    // Method for C# integration - set state from string
    public function setStateFromString(state:String):void
    {
        var newState:Boolean = (state.toUpperCase() == "ON" || state == "1" || state.toUpperCase() == "TRUE");
        setState(newState);
    }

    // Method to get state as number (1 for on, 0 for off) - useful for C# integration
    public function getStateAsNumber():int
    {
        return _isOn ? 1 : 0;
    }

    // Method to set state from number - useful for C# integration
    public function setStateFromNumber(state:int):void
    {
        setState(state > 0);
    }

    // Cleanup method
    public function dispose():void
    {
        removeEventListener(MouseEvent.CLICK, onToggleClick);
        removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        if (background && background.parent) removeChild(background);
        if (label && label.parent) removeChild(label);

        background = null;
        label = null;
    }



}
}
