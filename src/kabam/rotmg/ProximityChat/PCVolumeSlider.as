package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;
import flash.geom.Rectangle;

public class PCVolumeSlider extends Sprite {
    // Events
    public static const VOLUME_CHANGED:String = "volumeChanged";

    // Visual components
    private var background:Shape;
    private var track:Shape;
    private var thumb:Sprite; // Changed to Sprite for buttonMode
    private var label:TextField;
    private var valueLabel:TextField;

    // Properties
    private var _width:Number;
    private var _height:Number;
    private var _value:Number = 1.0; // 0.0 to 1.0
    private var _isDragging:Boolean = false;
    private var _thumbWidth:Number = 8;   // Reduce from 12 to 8
    private var _thumbHeight:Number = 10; // Reduce from 16 to 10
    private var _trackHeight:Number = 2;

    // Colors - updated to match PCMicSelector
    private var _backgroundColor:uint = 0x2a2a2a;
    private var _trackColor:uint = 0x404040;
    private var _thumbColor:uint = 0x444444;
    private var _thumbHoverColor:uint = 0x3a3a3a;
    private var _textColor:uint = 0xcccccc;
    private var _borderColor:uint = 0x444444;
    private var _cornerRadius:Number = 4;

    public function PCVolumeSlider(width:Number = 200, height:Number = 25) {
        _width = width;
        _height = height;

        initialize();
    }

    private function initialize():void {
        // Create background
        background = new Shape();
        addChild(background);

        // Create track
        track = new Shape();
        addChild(track);

        // Create thumb (as Sprite for buttonMode)
        thumb = new Sprite();
        addChild(thumb);

        // Create label
        label = new TextField();
        label.text = "Incoming Volume:";
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
        // Draw background exactly like PCMicSelector
        var g:Graphics = background.graphics;
        g.clear();
        g.beginFill(_backgroundColor);
        g.lineStyle(1, _borderColor);
        g.drawRoundRect(0, 0, _width, _height, _cornerRadius * 2, _cornerRadius * 2);
        g.endFill();

        // Position label on the left (same as PCMicSelector)
        label.x = 8;
        label.y = 2;

        // Calculate track position - start after label text
        var labelWidth:Number = 110; // Fixed width for "Incoming Volume:" text
        var trackY:Number = _height / 2 - _trackHeight / 2;
        var trackX:Number = labelWidth + 10; // Start after label + padding
        var trackWidth:Number = _width - labelWidth - 70; // Leave space for value label

        // Draw track
        g = track.graphics;
        g.clear();
        g.beginFill(_trackColor, 1);
        g.drawRoundRect(trackX, trackY, trackWidth, _trackHeight, _trackHeight, _trackHeight);
        g.endFill();

        // Position thumb based on value
        var thumbX:Number = trackX + (_value * (trackWidth - _thumbWidth));
        var thumbY:Number = _height / 2 - _thumbHeight / 2;

        // Draw thumb exactly like PCMicSelector
        var thumbColor:uint = _isDragging ? _thumbHoverColor : _thumbColor;
        g = thumb.graphics;
        g.clear();
        g.beginFill(thumbColor);
        g.lineStyle(1, _borderColor);
        g.drawRoundRect(0, 0, _thumbWidth, _thumbHeight, _cornerRadius, _cornerRadius);
        g.endFill();

        thumb.x = thumbX;
        thumb.y = thumbY;

        // Position value label on the right
        valueLabel.x = _width - 50;
        valueLabel.y = 2;
    }

    private function updateValueLabel():void {
        var valueFormat:TextFormat = new TextFormat();
        valueFormat.font = "Arial";
        valueFormat.size = 11;

        if (_value == 0) {
            valueLabel.text = "OFF";
            valueFormat.color = 0xff6666; // Red when muted
        } else {
            var percentage:int = Math.round(_value * 100);
            valueLabel.text = percentage + "%";
            valueFormat.color = _textColor;
        }

        valueLabel.setTextFormat(valueFormat);
    }

    private function onThumbMouseDown(e:MouseEvent):void {
        _isDragging = true;

        // Add stage listeners for dragging
        if (stage) {
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
            stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
        }

        draw();
    }

    private function onStageMouseMove(e:MouseEvent):void {
        if (!_isDragging) return;

        updateValueFromMouse();
    }

    private function onStageMouseUp(e:MouseEvent):void {
        if (!_isDragging) return;

        _isDragging = false;

        // Remove stage listeners
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
    }

    private function updateValueFromMouse():void {
        var labelWidth:Number = 110;
        var trackX:Number = labelWidth + 10;
        var trackWidth:Number = _width - labelWidth - 70;

        // Get mouse position relative to this slider
        var localMouseX:Number = mouseX;

        // Calculate new value
        var newValue:Number = (localMouseX - trackX) / trackWidth;
        newValue = Math.max(0, Math.min(1, newValue)); // Clamp to 0-1

        if (newValue != _value) {
            _value = newValue;
            draw();
            updateValueLabel();

            // Dispatch event
            dispatchEvent(new Event(VOLUME_CHANGED));
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

    public function get isMuted():Boolean {
        return _value == 0;
    }

    public function setColors(backgroundColor:uint, trackColor:uint, thumbColor:uint, textColor:uint):void {
        _backgroundColor = backgroundColor;
        _trackColor = trackColor;
        _thumbColor = thumbColor;
        _textColor = textColor;

        label.textColor = textColor;
        if (!isMuted) valueLabel.textColor = textColor;

        draw();
    }
    public function setLabelText(text:String):void {
        label.text = text;
    }

    public function setValueText(text:String):void {
        valueLabel.text = text;

        // Maintain the text formatting
        var valueFormat:TextFormat = new TextFormat();
        valueFormat.font = "Arial";
        valueFormat.size = 11;
        valueFormat.color = _textColor;
        valueLabel.setTextFormat(valueFormat);
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