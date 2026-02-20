package kabam.rotmg.ProximityChat {
import flash.display.Sprite;
import flash.display.Shape;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;

public class PCMicSelector extends Sprite {
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
    private var dropdown:Sprite;
    private var dropdownItems:Vector.<Sprite>;

    // Data
    private var microphones:Array;
    private var selectedMicId:String;
    private var selectedMicName:String;
    private var isDropdownOpen:Boolean;

    // Events
    public static const MIC_SELECTED:String = "micSelected";

    // Default styling
    private static const DEFAULT_BG_COLOR:uint = 0x2a2a2a;
    private static const DEFAULT_BORDER_COLOR:uint = 0x444444;
    private static const DEFAULT_TEXT_COLOR:uint = 0xcccccc;
    private static const DEFAULT_HOVER_COLOR:uint = 0x3a3a3a;

    public function PCMicSelector(
            width:Number = 200,
            height:Number = 25
    ) {
        _width = width;
        _height = height;
        _backgroundColor = DEFAULT_BG_COLOR;
        _borderColor = DEFAULT_BORDER_COLOR;
        _textColor = DEFAULT_TEXT_COLOR;
        _hoverColor = DEFAULT_HOVER_COLOR;
        _cornerRadius = 4;

        microphones = [];
        dropdownItems = new Vector.<Sprite>();
        isDropdownOpen = false;
        selectedMicName = "Select Microphone";

        initialize();
    }

    private function initialize():void {
        createBackground();
        createLabel();
        createDropdown();

        addEventListener(MouseEvent.CLICK, onSelectorClick);
        addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
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
        label.width = _width - 20; // Leave space for arrow
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
        label.text = selectedMicName;

        addChild(label);
    }

    private function createDropdown():void {
        dropdown = new Sprite();
        dropdown.y = _height;
        dropdown.visible = false;
        addChild(dropdown);
    }

    public function setMicrophones(mics:Array):void {
        microphones = mics.slice(); // Copy array
        updateDropdownItems();
    }

    private function updateDropdownItems():void {
        // Clear existing items
        clearDropdownItems();

        // Create new items
        for (var i:int = 0; i < microphones.length; i++) {
            var mic:Object = microphones[i];
            var item:Sprite = createDropdownItem(mic, i);
            dropdown.addChild(item);
            dropdownItems.push(item);
        }
    }

    private function createDropdownItem(mic:Object, index:int):Sprite {
        var item:Sprite = new Sprite();
        item.y = index * _height;

        // Background
        var itemBg:Shape = new Shape();
        var g = itemBg.graphics;
        g.beginFill(_backgroundColor);
        g.lineStyle(1, _borderColor);
        g.drawRect(0, 0, _width, _height);
        g.endFill();
        item.addChild(itemBg);

        // Text
        var itemText:TextField = new TextField();
        itemText.autoSize = TextFieldAutoSize.NONE;
        itemText.width = _width - 16;
        itemText.height = _height;
        itemText.x = 8;
        itemText.y = 2;
        itemText.selectable = false;
        itemText.mouseEnabled = false;

        var format:TextFormat = new TextFormat();
        format.font = "Arial";
        format.size = 11;
        format.color = _textColor;
        itemText.defaultTextFormat = format;

        // Show mic name, add (Default) if it's the default mic
        var displayName:String = mic.Name;
        if (mic.IsDefault) {
            displayName += " (Default)";
        }
        itemText.text = displayName;

        item.addChild(itemText);

        // Store mic data
        item.name = mic.Id;

        // Event handlers
        item.addEventListener(MouseEvent.CLICK, onItemClick);
        item.addEventListener(MouseEvent.MOUSE_OVER, onItemMouseOver);
        item.addEventListener(MouseEvent.MOUSE_OUT, onItemMouseOut);

        return item;
    }

    private function clearDropdownItems():void {
        for (var i:int = 0; i < dropdownItems.length; i++) {
            var item:Sprite = dropdownItems[i];
            item.removeEventListener(MouseEvent.CLICK, onItemClick);
            item.removeEventListener(MouseEvent.MOUSE_OVER, onItemMouseOver);
            item.removeEventListener(MouseEvent.MOUSE_OUT, onItemMouseOut);
            if (item.parent) dropdown.removeChild(item);
        }
        dropdownItems = new Vector.<Sprite>();
    }

    private function onSelectorClick(e:MouseEvent):void {
        e.stopPropagation();
        toggleDropdown();
    }

    private function toggleDropdown():void {
        isDropdownOpen = !isDropdownOpen;
        dropdown.visible = isDropdownOpen;

        // ADD THIS - Bring dropdown to front when opened
        if (isDropdownOpen) {
            // Move the dropdown to the top of the display list
            if (dropdown.parent) {
                dropdown.parent.setChildIndex(dropdown, dropdown.parent.numChildren - 1);
            }

            // Also move the entire PCMicSelector to front of its parent
            if (this.parent) {
                this.parent.setChildIndex(this, this.parent.numChildren - 1);
            }
        }
    }
    private function closeDropdown():void {
        isDropdownOpen = false;
        dropdown.visible = false;

        // Remove this since we're not using stage listeners anymore
        // if (stage) {
        //     stage.removeEventListener(MouseEvent.CLICK, onStageClick);
        // }
    }



    private function onItemClick(e:MouseEvent):void {
        trace("PCMicSelector: Item clicked!");
        e.stopPropagation();

        var item:Sprite = e.currentTarget as Sprite;
        var micId:String = item.name; // GET the ID from the item's name property

        // Find the full mic object by searching the microphones array
        var mic:Object = null;
        for (var i:int = 0; i < microphones.length; i++) {
            if (microphones[i].Id == micId) {
                mic = microphones[i];
                break;
            }
        }

        if (mic) {
            // JUST update the selection - don't dispatch event yet
            selectedMicId = mic.Id;
            selectedMicName = mic.Name;
            label.text = selectedMicName;

            trace("PCMicSelector: Selected microphone:", selectedMicName, "ID:", selectedMicId);
        }

        closeDropdown();

        // ONLY dispatch event once, after everything is set up
        if (mic) {
            trace("PCMicSelector: Dispatching MIC_SELECTED event");
            dispatchEvent(new Event(MIC_SELECTED));
        }
    }

    private function selectMicrophone(mic:Object):void {
        selectedMicId = mic.Id;
        selectedMicName = mic.Name;
        label.text = selectedMicName;

        // Dispatch selection event
        var event:Event = new Event(MIC_SELECTED);
        dispatchEvent(event);
    }
// Add this method to your PCMicSelector class (place it after the selectMicrophone method):

    /**
     * Select a microphone by its ID (used for restoring saved selections)
     */
    public function selectMicrophoneById(micId:String):Boolean
    {
        if (!microphones || microphones.length == 0)
        {
            trace("PCMicSelector: Cannot select by ID - no microphones available");
            return false;
        }

        for (var i:int = 0; i < microphones.length; i++)
        {
            var mic:Object = microphones[i];
            if (mic.Id == micId)
            {
                trace("PCMicSelector: Found microphone to select:", mic.Name);

                // Update the selection without dispatching event (to avoid loops)
                selectedMicId = mic.Id;
                selectedMicName = mic.Name;
                label.text = selectedMicName;

                trace("PCMicSelector: Successfully selected microphone by ID");
                return true;
            }
        }

        trace("PCMicSelector: Microphone with ID not found:", micId);
        return false;
    }

    /**
     * Select a microphone by array index and dispatch the selection event
     */
    public function selectMicrophoneByIndex(index:int):Boolean
    {
        if (!microphones || index < 0 || index >= microphones.length)
        {
            trace("PCMicSelector: Invalid microphone index:", index);
            return false;
        }

        var mic:Object = microphones[index];
        selectedMicId = mic.Id;
        selectedMicName = mic.Name;
        label.text = selectedMicName;

        // Dispatch selection event
        trace("PCMicSelector: Dispatching MIC_SELECTED event for index selection");
        dispatchEvent(new Event(MIC_SELECTED));

        return true;
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

    private function onItemMouseOver(e:MouseEvent):void {
        var item:Sprite = e.currentTarget as Sprite;
        var bg:Shape = item.getChildAt(0) as Shape;
        var g = bg.graphics;
        g.clear();
        g.beginFill(_hoverColor);
        g.lineStyle(1, _borderColor);
        g.drawRect(0, 0, _width, _height);
        g.endFill();
    }

    private function onItemMouseOut(e:MouseEvent):void {
        var item:Sprite = e.currentTarget as Sprite;
        var bg:Shape = item.getChildAt(0) as Shape;
        var g = bg.graphics;
        g.clear();
        g.beginFill(_backgroundColor);
        g.lineStyle(1, _borderColor);
        g.drawRect(0, 0, _width, _height);
        g.endFill();
    }

    // Getters
    public function get selectedMicrophoneId():String {
        return selectedMicId;
    }

    public function get selectedMicrophoneName():String {
        return selectedMicName;
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


        removeEventListener(MouseEvent.CLICK, onSelectorClick);
        removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        clearDropdownItems();

        if (dropdown && dropdown.parent) removeChild(dropdown);
        if (label && label.parent) removeChild(label);
        if (background && background.parent) removeChild(background);

        dropdown = null;
        label = null;
        background = null;
        microphones = null;
        dropdownItems = null;
    }
}
}