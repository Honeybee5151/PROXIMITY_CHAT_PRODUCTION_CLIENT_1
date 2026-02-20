package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.display.Shape;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCGenericToggle extends Sprite {
    // Visual properties
    private var _width:Number;
    private var _height:Number;
    private var _backgroundColor:uint;
    private var _borderColor:uint;
    private var _textColor:uint;
    private var _hoverColor:uint;
    private var _cornerRadius:Number;

    // Components
    private var background:Shape;
    private var label:TextField;

    // State
    private var _isEnabled:Boolean;
    private var _labelText:String;
    private var _trueText:String;
    private var _falseText:String;

    // Events
    public static const TOGGLE_CHANGED:String = "toggleChanged";

    // Default styling (no green color)
    private static const DEFAULT_BG_COLOR:uint = 0x2a2a2a;
    private static const DEFAULT_BORDER_COLOR:uint = 0x444444;
    private static const DEFAULT_TEXT_COLOR:uint = 0xcccccc;
    private static const DEFAULT_HOVER_COLOR:uint = 0x3a3a3a;

    public function PCGenericToggle(
            labelText:String = "Setting",
            trueText:String = "On",
            falseText:String = "Off",
            width:Number = 200,
            height:Number = 25
    ) {
        _labelText = labelText;
        _trueText = trueText;
        _falseText = falseText;
        _width = width;
        _height = height;
        _backgroundColor = DEFAULT_BG_COLOR;
        _borderColor = DEFAULT_BORDER_COLOR;
        _textColor = DEFAULT_TEXT_COLOR;
        _hoverColor = DEFAULT_HOVER_COLOR;
        _cornerRadius = 4;

        _isEnabled = false; // Default to disabled

        initialize();
    }

    private function initialize():void {
        createBackground();
        createLabel();

        addEventListener(MouseEvent.CLICK, onButtonClick);
        addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        updateDisplay();
    }

    private function createBackground():void {
        background = new Shape();
        addChild(background);
        drawBackground();
    }

    private function drawBackground():void {
        var g = background.graphics;
        g.clear();

        // Always use the same background color (no green when enabled)
        g.beginFill(_backgroundColor);
        g.lineStyle(1, _borderColor);

        if (_cornerRadius > 0) {
            g.drawRoundRect(0, 0, _width, _height, _cornerRadius * 2);
        } else {
            g.drawRect(0, 0, _width, _height);
        }
        g.endFill();
    }

    private function createLabel():void {
        label = new TextField();
        label.autoSize = TextFieldAutoSize.NONE;
        label.width = _width - 16;
        label.height = _height;
        label.x = 8;
        label.y = 2;
        label.selectable = false;
        label.mouseEnabled = false;

        var format:TextFormat = new TextFormat();
        format.font = "Arial";
        format.size = 11;
        format.color = _textColor;
        label.defaultTextFormat = format;

        addChild(label);
    }

    private function updateDisplay():void {
        var statusText:String = _isEnabled ? _trueText : _falseText;
        label.text = _labelText + ": " + statusText;
        drawBackground(); // Redraw background
    }

    private function onButtonClick(e:MouseEvent):void {
        e.stopPropagation();
        toggle();
    }

    private function toggle():void {
        _isEnabled = !_isEnabled;
        updateDisplay();

        trace("PCGenericToggle: " + _labelText + " toggled to:", _isEnabled);

        // Dispatch event so parent can handle the change
        dispatchEvent(new Event(TOGGLE_CHANGED));
    }

    private function onMouseOver(e:MouseEvent):void {
        var g = background.graphics;
        g.clear();

        // Use hover color (no special enabled color)
        g.beginFill(_hoverColor);
        g.lineStyle(1, _borderColor);

        if (_cornerRadius > 0) {
            g.drawRoundRect(0, 0, _width, _height, _cornerRadius * 2);
        } else {
            g.drawRect(0, 0, _width, _height);
        }
        g.endFill();
    }

    private function onMouseOut(e:MouseEvent):void {
        drawBackground();
    }

    // Public API
    public function get isEnabled():Boolean {
        return _isEnabled;
    }

    public function set isEnabled(value:Boolean):void {
        if (_isEnabled != value) {
            _isEnabled = value;
            updateDisplay();
            // Don't dispatch event when set programmatically
        }
    }

    public function get labelText():String {
        return _labelText;
    }

    // Styling methods
    public function setColors(bgColor:uint, borderColor:uint, textColor:uint, hoverColor:uint):void {
        _backgroundColor = bgColor;
        _borderColor = borderColor;
        _textColor = textColor;
        _hoverColor = hoverColor;

        drawBackground();

        var format:TextFormat = new TextFormat();
        format.color = _textColor;
        label.setTextFormat(format);
    }

    public function dispose():void {
        removeEventListener(MouseEvent.CLICK, onButtonClick);
        removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        if (label && label.parent) removeChild(label);
        if (background && background.parent) removeChild(background);

        label = null;
        background = null;
    }
}
}