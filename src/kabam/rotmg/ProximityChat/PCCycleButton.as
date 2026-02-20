package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.display.Shape;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCCycleButton extends Sprite {
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
    private var _currentState:int = 0; // 0=Guild, 1=Locked, 2=Both
    private var _states:Vector.<String>;
    private var _labelText:String;

    // Events
    public static const STATE_CHANGED:String = "stateChanged";

    // Constants for states
    public static const GUILD:int = 0;
    public static const LOCKED:int = 1;
    public static const BOTH:int = 2;

    // Default styling
    private static const DEFAULT_BG_COLOR:uint = 0x2a2a2a;
    private static const DEFAULT_BORDER_COLOR:uint = 0x444444;
    private static const DEFAULT_TEXT_COLOR:uint = 0xcccccc;
    private static const DEFAULT_HOVER_COLOR:uint = 0x3a3a3a;

    public function PCCycleButton(
            labelText:String = "Auto Priority",
            width:Number = 200,
            height:Number = 25
    ) {
        _labelText = labelText;
        _width = width;
        _height = height;
        _backgroundColor = DEFAULT_BG_COLOR;
        _borderColor = DEFAULT_BORDER_COLOR;
        _textColor = DEFAULT_TEXT_COLOR;
        _hoverColor = DEFAULT_HOVER_COLOR;
        _cornerRadius = 4;

        // Define the cycle states
        _states = new Vector.<String>();
        _states.push("Guild");
        _states.push("Locked");
        _states.push("Both");

        _currentState = 0; // Start with Guild

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
        var stateText:String = _states[_currentState];
        label.text = _labelText + ": " + stateText;
        drawBackground();
    }

    private function onButtonClick(e:MouseEvent):void {
        e.stopPropagation();
        cycleToNextState();
    }

    private function cycleToNextState():void {
        // Cycle to next state
        _currentState = (_currentState + 1) % _states.length;
        updateDisplay();

        trace("PCCycleButton: " + _labelText + " cycled to:", _states[_currentState]);

        // Dispatch event so parent can handle the change
        dispatchEvent(new Event(STATE_CHANGED));
    }

    private function onMouseOver(e:MouseEvent):void {
        var g = background.graphics;
        g.clear();

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
    public function get currentState():int {
        return _currentState;
    }

    public function set currentState(value:int):void {
        if (value >= 0 && value < _states.length && _currentState != value) {
            _currentState = value;
            updateDisplay();
            // Don't dispatch event when set programmatically
        }
    }

    public function get currentStateText():String {
        return _states[_currentState];
    }

    public function get isGuildMode():Boolean {
        return _currentState == GUILD;
    }

    public function get isLockedMode():Boolean {
        return _currentState == LOCKED;
    }

    public function get isBothMode():Boolean {
        return _currentState == BOTH;
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
        _states = null;
    }
}
}