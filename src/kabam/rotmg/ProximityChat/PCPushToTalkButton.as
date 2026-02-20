package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.display.Shape;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCPushToTalkButton extends Sprite {
    // Visual properties
    private var _width:Number;
    private var _height:Number;
    private var _backgroundColor:uint;
    private var _borderColor:uint;
    private var _textColor:uint;
    private var _hoverColor:uint;
    private var _enabledColor:uint;
    private var _cornerRadius:Number;

    // Components
    private var background:Shape;
    private var label:TextField;

    // State
    private var _pushToTalkEnabled:Boolean;

    // Events
    public static const PUSH_TO_TALK_TOGGLED:String = "pushToTalkToggled";

    // Default styling
    private static const DEFAULT_BG_COLOR:uint = 0x2a2a2a;
    private static const DEFAULT_BORDER_COLOR:uint = 0x444444;
    private static const DEFAULT_TEXT_COLOR:uint = 0xcccccc;
    private static const DEFAULT_HOVER_COLOR:uint = 0x3a3a3a;
    private static const DEFAULT_ENABLED_COLOR:uint = 0x4a6741; // Green tint when enabled

    public function PCPushToTalkButton(
            width:Number = 200,
            height:Number = 25
    ) {
        _width = width;
        _height = height;
        _backgroundColor = DEFAULT_BG_COLOR;
        _borderColor = DEFAULT_BORDER_COLOR;
        _textColor = DEFAULT_TEXT_COLOR;
        _hoverColor = DEFAULT_HOVER_COLOR;
        _enabledColor = DEFAULT_ENABLED_COLOR;
        _cornerRadius = 4;

        _pushToTalkEnabled = false; // Default to disabled

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

        // Use enabled color if push-to-talk is on, otherwise normal background
        var bgColor:uint = _pushToTalkEnabled ? _enabledColor : _backgroundColor;

        g.beginFill(bgColor);
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
        var statusText:String = _pushToTalkEnabled ? "True" : "False";
        label.text = "Push to Talk: " + statusText;
        drawBackground(); // Redraw background to show enabled state
    }

    private function onButtonClick(e:MouseEvent):void {
        e.stopPropagation();
        togglePushToTalk();
    }

    private function togglePushToTalk():void {
        _pushToTalkEnabled = !_pushToTalkEnabled;
        updateDisplay();

        trace("PCPushToTalkButton: Push-to-talk toggled to:", _pushToTalkEnabled);

        // Dispatch event so parent can handle the change
        dispatchEvent(new Event(PUSH_TO_TALK_TOGGLED));
    }

    private function onMouseOver(e:MouseEvent):void {
        var g = background.graphics;
        g.clear();

        // Use brighter version of current color when hovering
        var hoverColor:uint = _pushToTalkEnabled ? lightenColor(_enabledColor) : _hoverColor;

        g.beginFill(hoverColor);
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

    // Helper function to lighten colors for hover effect
    private function lightenColor(color:uint):uint {
        var r:uint = (color >> 16) & 0xFF;
        var g:uint = (color >> 8) & 0xFF;
        var b:uint = color & 0xFF;

        r = Math.min(255, r + 30);
        g = Math.min(255, g + 30);
        b = Math.min(255, b + 30);

        return (r << 16) | (g << 8) | b;
    }

    // Public API
    public function get pushToTalkEnabled():Boolean {
        return _pushToTalkEnabled;
    }

    public function set pushToTalkEnabled(value:Boolean):void {
        if (_pushToTalkEnabled != value) {
            _pushToTalkEnabled = value;
            updateDisplay();
            // Don't dispatch event when set programmatically
        }
    }

    // Styling methods
    public function setColors(bgColor:uint, borderColor:uint, textColor:uint, hoverColor:uint, enabledColor:uint = 0x4a6741):void {
        _backgroundColor = bgColor;
        _borderColor = borderColor;
        _textColor = textColor;
        _hoverColor = hoverColor;
        _enabledColor = enabledColor;

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