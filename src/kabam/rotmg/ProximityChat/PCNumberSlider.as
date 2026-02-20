package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCNumberSlider extends Sprite {
    // Events
    public static const VALUE_CHANGED:String = "valueChanged";

    // Visual components
    private var background:Shape;
    private var track:Shape;
    private var thumb:Sprite;
    private var label:TextField;
    private var valueLabel:TextField;

    // Properties
    private var _width:Number;
    private var _height:Number;
    private var _value:Number = 0.9; // Start at 90% (which = 45.5 slots ≈ 50 slots)
    private var _isDragging:Boolean = false;
    private var _thumbWidth:Number = 8;
    private var _thumbHeight:Number = 10;
    private var _trackHeight:Number = 2;

    // Number range properties
    private var _minValue:int;
    private var _maxValue:int;
    private var _labelText:String;
    private var _suffix:String;

    // Colors
    private var _backgroundColor:uint = 0x2a2a2a;
    private var _trackColor:uint = 0x404040;
    private var _thumbColor:uint = 0x444444;
    private var _thumbHoverColor:uint = 0x3a3a3a;
    private var _textColor:uint = 0xcccccc;
    private var _borderColor:uint = 0x444444;
    private var _cornerRadius:Number = 4;

    public function PCNumberSlider(
            labelText:String = "Value",
            minValue:int = 5,
            maxValue:int = 50,
            defaultValue:int = 10,
            suffix:String = "",
            width:Number = 200,
            height:Number = 25
    ) {
        _labelText = labelText;
        _minValue = minValue;
        _maxValue = maxValue;
        _suffix = suffix;
        _width = width;
        _height = height;

        // Convert defaultValue to 0-1 range
        _value = (defaultValue - minValue) / (maxValue - minValue);

        initialize();
    }

    private function initialize():void {
        // Create background
        background = new Shape();
        addChild(background);

        // Create track
        track = new Shape();
        addChild(track);

        // Create thumb
        thumb = new Sprite();
        addChild(thumb);

        // Create label
        label = new TextField();
        label.text = _labelText + ":";
        label.autoSize = TextFieldAutoSize.LEFT;
        label.selectable = false;
        label.mouseEnabled = false;

        var labelFormat:TextFormat = new TextFormat();
        labelFormat.font = "Arial";
        labelFormat.size = 11;
        labelFormat.color = _textColor;
        label.defaultTextFormat = labelFormat;
        label.setTextFormat(labelFormat);

        addChild(label);

        // Create value label
        valueLabel = new TextField();
        valueLabel.textColor = _textColor;
        valueLabel.autoSize = TextFieldAutoSize.LEFT;
        valueLabel.selectable = false;
        valueLabel.mouseEnabled = false;
        addChild(valueLabel);

        // Set up interaction
        thumb.buttonMode = true;
        thumb.useHandCursor = true;

        // Add event listeners
        thumb.addEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        thumb.addEventListener(MouseEvent.MOUSE_OVER, onThumbMouseOver);
        thumb.addEventListener(MouseEvent.MOUSE_OUT, onThumbMouseOut);
        track.addEventListener(MouseEvent.CLICK, onTrackClick);

        // Draw initial state
        draw();
        updateValueLabel();
    }

    private function draw():void {
        // Draw background
        var g:Graphics = background.graphics;
        g.clear();
        g.beginFill(_backgroundColor);
        g.lineStyle(1, _borderColor);
        g.drawRoundRect(0, 0, _width, _height, _cornerRadius * 2, _cornerRadius * 2);
        g.endFill();

        // Position label
        label.x = 8;
        label.y = 2;

        // Calculate track position
        var labelWidth:Number = 110;
        var trackY:Number = _height / 2 - _trackHeight / 2;
        var trackX:Number = labelWidth + 10;
        var trackWidth:Number = _width - labelWidth - 70;

        // Draw track
        g = track.graphics;
        g.clear();
        g.beginFill(_trackColor, 1);
        g.drawRoundRect(trackX, trackY, trackWidth, _trackHeight, _trackHeight, _trackHeight);
        g.endFill();

        // Position thumb based on value
        var thumbX:Number = trackX + (_value * (trackWidth - _thumbWidth));
        var thumbY:Number = _height / 2 - _thumbHeight / 2;

        // Draw thumb
        var thumbColor:uint = _isDragging ? _thumbHoverColor : _thumbColor;
        g = thumb.graphics;
        g.clear();
        g.beginFill(thumbColor);
        g.lineStyle(1, _borderColor);
        g.drawRoundRect(0, 0, _thumbWidth, _thumbHeight, _cornerRadius, _cornerRadius);
        g.endFill();

        thumb.x = thumbX;
        thumb.y = thumbY;

        // Position value label
        //valueLabel.x = _width - 50;
        valueLabel.y = 2;
    }

    private function updateValueLabel():void {
        var actualValue:int = Math.round(_value * (_maxValue - _minValue)) + _minValue;

        var valueFormat:TextFormat = new TextFormat();
        valueFormat.font = "Arial";
        valueFormat.size = 11;
        valueFormat.color = _textColor;

        valueLabel.text = actualValue.toString() + _suffix;
        valueLabel.setTextFormat(valueFormat);

        // Right-align the text with consistent padding from right edge
        valueLabel.x = _width - valueLabel.textWidth - 8;
    }

    private function onThumbMouseDown(e:MouseEvent):void {
        _isDragging = true;

        if (stage) {
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }

        draw();
    }

    private function onStageMouseMove(e:MouseEvent):void {
        if (!_isDragging) return;
        updateValueFromMouse();
        // ADD THESE TWO LINES:
        updateValueLabel();
        dispatchEvent(new Event(VALUE_CHANGED));
    }

    private function onStageMouseUp(e:MouseEvent):void {
        if (!_isDragging) return;

        _isDragging = false;

        if (stage) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }

        draw();
    }

    private function onThumbMouseOver(e:MouseEvent):void {
        if (!_isDragging) {
            var g:Graphics = thumb.graphics;
            g.clear();
            g.beginFill(_thumbHoverColor, 1);
            g.lineStyle(1, 0x333333, 1);
            g.drawRoundRect(0, 0, _thumbWidth, _thumbHeight, 4, 4);
            g.endFill();
        }
    }

    private function onThumbMouseOut(e:MouseEvent):void {
        if (!_isDragging) {
            draw();
        }
    }

    private function onTrackClick(e:MouseEvent):void {
        if (_isDragging) return;
        updateValueFromMouse();
        // ADD THIS LINE:
        dispatchEvent(new Event(VALUE_CHANGED));
    }

    private function updateValueFromMouse():void {
        var labelWidth:Number = 110;
        var trackX:Number = labelWidth + 10;
        var trackWidth:Number = _width - labelWidth - 70;

        var localMouseX:Number = mouseX;
        var newValue:Number = (localMouseX - trackX) / trackWidth;
        newValue = Math.max(0, Math.min(1, newValue));

        if (newValue != _value) {
            _value = newValue;
            draw();
            updateValueLabel();
            dispatchEvent(new Event(VALUE_CHANGED));
        }
    }

    // Public methods
    public function get value():Number {
        return _value;
    }

    public function set value(val:Number):void {
        _value = Math.max(0, Math.min(1, val));
        draw();
        updateValueLabel();
    }

    public function get actualValue():int {
        return Math.round(_value * (_maxValue - _minValue)) + _minValue;
    }

    public function set actualValue(val:int):void {
        var clampedVal:int = Math.max(_minValue, Math.min(_maxValue, val));
        _value = (clampedVal - _minValue) / (_maxValue - _minValue);
        draw();
        updateValueLabel();
    }

    public function setLabelText(text:String):void {
        _labelText = text;
        label.text = text + ":";
    }

    public function dispose():void {
        // Remove event listeners
        thumb.removeEventListener(MouseEvent.MOUSE_DOWN, onThumbMouseDown);
        thumb.removeEventListener(MouseEvent.MOUSE_OVER, onThumbMouseOver);
        thumb.removeEventListener(MouseEvent.MOUSE_OUT, onThumbMouseOut);
        track.removeEventListener(MouseEvent.CLICK, onTrackClick);

        if (stage) {
            stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }

        // Clear graphics
        if (background && background.parent) removeChild(background);
        if (track && track.parent) removeChild(track);
        if (thumb && thumb.parent) removeChild(thumb);
        if (label && label.parent) removeChild(label);
        if (valueLabel && valueLabel.parent) removeChild(valueLabel);

        background = null;
        track = null;
        thumb = null;
        label = null;
        valueLabel = null;
    }
}
}