package kabam.rotmg.ProximityChat {

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Graphics;
import flash.display.Shape;
import flash.geom.Rectangle;
import flash.events.Event;

public class PCMask extends Sprite
{
    // Configuration properties
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

    // Components
    private var background:Shape;
    private var maskShape:Shape;
    private var border:Shape;

    // Default values
    private static const DEFAULT_WIDTH:Number = 300;
    private static const DEFAULT_HEIGHT:Number = 200;
    private static const DEFAULT_BG_COLOR:uint = 0x000000;
    private static const DEFAULT_BG_ALPHA:Number = 0.8;
    private static const DEFAULT_BORDER_COLOR:uint = 0x666666;
    private static const DEFAULT_BORDER_THICKNESS:Number = 2;
    private static const DEFAULT_CORNER_RADIUS:Number = 8;

    public function PCMask (
            width:Number = DEFAULT_WIDTH,
            height:Number = DEFAULT_HEIGHT,
            x:Number = 0,
            y:Number = 0
    )
    {
        this._width = width;
        this._height = height;
        this._x = x;
        this._y = y;

        // Set default visual properties
        _backgroundColor = DEFAULT_BG_COLOR;
        _backgroundAlpha = DEFAULT_BG_ALPHA;
        _borderColor = DEFAULT_BORDER_COLOR;
        _borderThickness = DEFAULT_BORDER_THICKNESS;
        _cornerRadius = DEFAULT_CORNER_RADIUS;

        initialize();
    }

    private function initialize():void
    {
        // Create components
        background = new Shape();
        maskShape = new Shape();
        border = new Shape();

        // Add to display list in correct order
        addChild(background);
        addChild(border);

        // Position the container
        this.x = _x;
        this.y = _y;

        // Draw initial graphics
        redraw();

        // Set up masking
        setupMask();
    }

    private function redraw():void
    {
        drawBackground();
        drawBorder();
        drawMask();
    }

    private function drawBackground():void
    {
        var g:Graphics = background.graphics;
        g.clear();
        g.beginFill(_backgroundColor, _backgroundAlpha);

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

    private function drawBorder():void
    {
        if (_borderThickness <= 0) return;

        var g:Graphics = border.graphics;
        g.clear();
        g.lineStyle(_borderThickness, _borderColor, 1);

        if (_cornerRadius > 0)
        {
            g.drawRoundRect(0, 0, _width, _height, _cornerRadius * 2, _cornerRadius * 2);
        }
        else
        {
            g.drawRect(0, 0, _width, _height);
        }
    }

    private function drawMask():void
    {
        var g:Graphics = maskShape.graphics;
        g.clear();
        g.beginFill(0xFFFFFF, 1); // Color doesn't matter for mask

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

    private function setupMask():void
    {
        // Add mask to stage but make it invisible
        addChild(maskShape);
        maskShape.visible = false;

        // Don't apply mask to the container itself
        // The mask will be applied to content added via addChildWithMask()
    }
    // Public methods for customization
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
    public override function addChild(child:DisplayObject):DisplayObject
    {
        // Add the child normally
        var addedChild:DisplayObject = super.addChild(child);

        // If this child should be masked (and it's not our internal components)
        if (child != background && child != border && child != maskShape && child != this.mask)
        {
            child.mask = maskShape;
        }

        return addedChild;
    }
    public function setBackgroundColor(color:uint, alpha:Number = -1):void
    {
        _backgroundColor = color;
        if (alpha >= 0) _backgroundAlpha = alpha;
        drawBackground();
    }

    public function setBorder(color:uint, thickness:Number):void
    {
        _borderColor = color;
        _borderThickness = thickness;
        drawBorder();
    }

    public function setCornerRadius(radius:Number):void
    {
        _cornerRadius = radius;
        redraw();
    }

    public function updateMask():void
    {
        drawMask();
    }

    // Getters
    public function get containerWidth():Number { return _width; }
    public function get containerHeight():Number { return _height; }
    public function get containerX():Number { return _x; }
    public function get containerY():Number { return _y; }
    public function get backgroundColor():uint { return _backgroundColor; }
    public function get backgroundAlpha():Number { return _backgroundAlpha; }
    public function get borderColor():uint { return _borderColor; }
    public function get borderThickness():Number { return _borderThickness; }
    public function get cornerRadius():Number { return _cornerRadius; }

    // Method to get the bounds for child components
    public function getContentBounds():Rectangle
    {
        return new Rectangle(
                _borderThickness,
                _borderThickness,
                _width - (_borderThickness * 2),
                _height - (_borderThickness * 2)
        );
    }

    // Cleanup method
    public function dispose():void
    {
        if (background && background.parent)
        {
            removeChild(background);
        }
        if (border && border.parent)
        {
            removeChild(border);
        }
        if (maskShape && maskShape.parent)
        {
            removeChild(maskShape);
        }

        background = null;
        border = null;
        maskShape = null;
        this.mask = null;
    }
}
}
