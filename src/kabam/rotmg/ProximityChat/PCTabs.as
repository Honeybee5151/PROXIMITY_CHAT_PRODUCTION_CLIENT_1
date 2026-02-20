package kabam.rotmg.ProximityChat {
import com.company.assembleegameclient.game.MapUserInput;

import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.events.MouseEvent;
import flash.events.Event;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;
import flash.utils.Dictionary;


public class PCTabs extends Sprite {
    // Tab configuration
    private var _tabWidth:Number;
    private var _tabHeight:Number;
    private var _tabSpacing:Number;
    private var _x:Number;
    private var _y:Number;

    // Visual properties
    private var _activeTabColor:uint;
    private var _inactiveTabColor:uint;
    private var _hoverTabColor:uint;
    private var _borderColor:uint;
    private var _textColor:uint;
    private var _activeTextColor:uint;
    private var _cornerRadius:Number;

    // Tab data
    private var tabs:Vector.<TabButton>;
    private var tabBackgrounds:Vector.<Sprite>;
    private var activeTabIndex:int;
    private var targetContainer:Sprite; // Container where backgrounds will be shown

    // Tab button class
    private var blockedTab:TabButton;
    private var algorithmTab:TabButton;
    private var blockedBackground:Sprite;
    private var algorithmBackground:Sprite;

    // Constants
    private static const DEFAULT_TAB_WIDTH:Number = 80;
    private static const DEFAULT_TAB_HEIGHT:Number = 30;
    private static const DEFAULT_TAB_SPACING:Number = 2;
    private static const DEFAULT_ACTIVE_COLOR:uint = 0x444444;
    private static const DEFAULT_INACTIVE_COLOR:uint = 0x2a2a2a;
    private static const DEFAULT_HOVER_COLOR:uint = 0x333333;
    private static const DEFAULT_BORDER_COLOR:uint = 0x666666;
    private static const DEFAULT_TEXT_COLOR:uint = 0xcccccc;
    private static const DEFAULT_ACTIVE_TEXT_COLOR:uint = 0xffffff;

    // Events
    public static const TAB_CHANGED:String = "tabChanged";

    public var micSelector:PCMicSelector;
    private var backgroundMicSelectors:Dictionary = new Dictionary()


    public function PCTabs(
            x:Number = 0,
            y:Number = 0,
            tabWidth:Number = DEFAULT_TAB_WIDTH,
            tabHeight:Number = DEFAULT_TAB_HEIGHT
    ) {
        this._x = x;
        this._y = y;
        this._tabWidth = tabWidth;
        this._tabHeight = tabHeight;
        this._tabSpacing = DEFAULT_TAB_SPACING;

        // Set default visual properties
        _activeTabColor = DEFAULT_ACTIVE_COLOR;
        _inactiveTabColor = DEFAULT_INACTIVE_COLOR;
        _hoverTabColor = DEFAULT_HOVER_COLOR;
        _borderColor = DEFAULT_BORDER_COLOR;
        _textColor = DEFAULT_TEXT_COLOR;
        _activeTextColor = DEFAULT_ACTIVE_TEXT_COLOR;
        _cornerRadius = 4;

        activeTabIndex = 0;

        initialize();

    }

    private function initialize():void {
        // Position the tabs container
        this.x = _x;
        this.y = _y;

        // Initialize collections
        tabs = new Vector.<TabButton>();
        tabBackgrounds = new Vector.<Sprite>();

        // Create tab buttons
        createTabs();

        // Create backgrounds for each tab
        createBackgrounds();


        // Set initial active tab
        setActiveTab(0, false);

        loadSavedPushToTalkState();
        loadSavedPrioritySettings();
    }

    private function createTabs():void {
        // Create "Adjust" tab FIRST (most used)
        algorithmTab = new TabButton("Adjust", _tabWidth, _tabHeight);
        algorithmTab.x = 0; // Move to first position
        algorithmTab.y = 0;
        algorithmTab.addEventListener(MouseEvent.CLICK, onAlgorithmTabClick);
        addChild(algorithmTab);
        tabs.push(algorithmTab);

        // Create "Blocked" tab SECOND
        blockedTab = new TabButton("Priority", _tabWidth, _tabHeight);
        blockedTab.x = _tabWidth + _tabSpacing; // Move to second position
        blockedTab.y = 0;
        blockedTab.addEventListener(MouseEvent.CLICK, onBlockedTabClick);
        addChild(blockedTab);
        tabs.push(blockedTab);

        // Apply styling to all tabs
        updateTabStyling();
    }

    private function createBackgrounds():void {
        // Create background for "Adjust" tab FIRST (index 0)
        algorithmBackground = new Sprite();
        createBackgroundContent(algorithmBackground, 0x2a1a1a, "Adjust stuff");
        tabBackgrounds.push(algorithmBackground);

        // Create background for "Blocked" tab SECOND (index 1)
        blockedBackground = new Sprite();
        createBackgroundContent(blockedBackground, 0x1a1a2a, "Choose how, when and who has priority in groups");
        tabBackgrounds.push(blockedBackground);
    }

    public function getMicSelectorForBackground(background:Sprite):PCMicSelector {
        return backgroundMicSelectors[background];
    }

    private function createBackgroundContent(background:Sprite, color:uint, labelText:String):void {
        var label:TextField = new TextField();
        label.text = labelText;
        label.textColor = 0xcccccc;
        label.autoSize = TextFieldAutoSize.LEFT;
        label.x = 10;
        label.y = 10;
        background.addChild(label);

        // Add microphone selector to the "Adjust" tab content
        if (labelText == "Adjust stuff") {
            var micSelector:PCMicSelector = new PCMicSelector(280, 25);
            micSelector.x = 10;
            micSelector.y = 40;
            background.addChild(micSelector);

            // Store reference in dictionary
            backgroundMicSelectors[background] = micSelector;

            // ADD EVENT LISTENER HERE:
            micSelector.addEventListener(PCMicSelector.MIC_SELECTED, onMicrophoneSelected);

            var volumeSlider:PCVolumeSlider = new PCVolumeSlider(280, 25);
            volumeSlider.x = 10;
            volumeSlider.y = 75; // Position below mic selector

            // Load saved volume setting
            var savedVolume:Number = PCSettings.getInstance().getIncomingVolume();
            volumeSlider.value = savedVolume;
            VoiceChatService.getInstance().setIncomingVolume(savedVolume);

            background.addChild(volumeSlider);

            // Store volume slider reference
            backgroundMicSelectors[background + "_volume"] = volumeSlider;

            // Add event listener for volume changes
            volumeSlider.addEventListener(PCVolumeSlider.VOLUME_CHANGED, onVolumeChanged);

            // ADD PUSH-TO-TALK BUTTON HERE:
            var pushToTalkButton:PCPushToTalkButton = new PCPushToTalkButton(280, 25);
            pushToTalkButton.x = 10;
            pushToTalkButton.y = 110; // Position below volume slider
            background.addChild(pushToTalkButton);

            // Store push-to-talk button reference
            backgroundMicSelectors[background + "_pushToTalk"] = pushToTalkButton;

            // Add event listener for push-to-talk changes
            pushToTalkButton.addEventListener(PCPushToTalkButton.PUSH_TO_TALK_TOGGLED, onPushToTalkToggled);
        } else if (labelText == "Choose how, when and who has priority in groups") {
            // Priority System Enable/Disable Toggle
            var priorityToggle:PCGenericToggle = new PCGenericToggle("Priority System", "Enabled", "Disabled", 280, 25);
            priorityToggle.x = 10;
            priorityToggle.y = 40;
            background.addChild(priorityToggle);
            backgroundMicSelectors[background + "_priorityToggle"] = priorityToggle;
            priorityToggle.addEventListener(PCGenericToggle.TOGGLE_CHANGED, onPriorityToggleChanged);

            // Auto Priority Cycle Button (Guild/Locked/Both)
            var autoPriorityButton:PCCycleButton = new PCCycleButton("Auto Priority", 280, 25);
            autoPriorityButton.x = 10;
            autoPriorityButton.y = 75;
            background.addChild(autoPriorityButton);
            backgroundMicSelectors[background + "_autoPriority"] = autoPriorityButton;
            autoPriorityButton.addEventListener(PCCycleButton.STATE_CHANGED, onAutoPriorityChanged);

            // Non-Priority Volume Slider
            var nonPrioritySlider:PCVolumeSlider = new PCVolumeSlider(280, 25);
            nonPrioritySlider.x = 10;
            nonPrioritySlider.y = 110;
            nonPrioritySlider.setLabelText("Non-Priority Volume:");
            background.addChild(nonPrioritySlider);
            backgroundMicSelectors[background + "_nonPriorityVolume"] = nonPrioritySlider;
            nonPrioritySlider.addEventListener(PCVolumeSlider.VOLUME_CHANGED, onNonPriorityVolumeChanged);

            // Max Priority Slots Slider (5-50 range)
            var maxSlotsSlider:PCVolumeSlider = new PCVolumeSlider(280, 25);
            maxSlotsSlider.x = 10;
            maxSlotsSlider.y = 145;
            maxSlotsSlider.setLabelText("Max Priority Slots:");
            background.addChild(maxSlotsSlider);
            backgroundMicSelectors[background + "_maxSlots"] = maxSlotsSlider;
            maxSlotsSlider.addEventListener(PCVolumeSlider.VOLUME_CHANGED, onMaxSlotsChanged);

// With this:
            var activationThresholdSlider:PCNumberSlider = new PCNumberSlider(
                    "Activate When", // label
                    3,               // min value (activate when 3+ people nearby)
                    30,              // max value (activate when 30+ people nearby)
                    8,               // default value (activate when 8+ people nearby)
                    " people",       // suffix
                    280,             // width
                    25               // height
            );
            activationThresholdSlider.x = 10;
            activationThresholdSlider.y = 145;
            background.addChild(activationThresholdSlider);
            backgroundMicSelectors[background + "_activationThreshold"] = activationThresholdSlider;
            activationThresholdSlider.addEventListener(PCNumberSlider.VALUE_CHANGED, onActivationThresholdChanged);

        }
    }



    // Add this method to PCTabs.as
    private function loadSavedPrioritySettings():void {
        var settings:PCSettings = PCSettings.getInstance();

        // Load and apply saved priority toggle
        var priorityToggle:PCGenericToggle = backgroundMicSelectors[blockedBackground + "_priorityToggle"];
        if (priorityToggle) {
            priorityToggle.isEnabled = settings.getPrioritySystemEnabled();
        }

        // Load and apply saved activation threshold
        var thresholdSlider:PCNumberSlider = backgroundMicSelectors[blockedBackground + "_activationThreshold"];
        if (thresholdSlider) {
            thresholdSlider.actualValue = settings.getPriorityActivationThreshold();
        }

        // Load and apply saved non-priority volume
        var nonPrioritySlider:PCVolumeSlider = backgroundMicSelectors[blockedBackground + "_nonPriorityVolume"];
        if (nonPrioritySlider) {
            nonPrioritySlider.value = settings.getNonPriorityVolume();
        }

        trace("PCTabs: Loaded saved priority settings");
    }
    private function onPriorityToggleChanged(e:Event):void {
        var toggle:PCGenericToggle = e.target as PCGenericToggle;
        var enabled:Boolean = toggle.isEnabled;

        trace("PCTabs: Priority system toggled to:", enabled);

        // Use VoiceChatService instead of ExternalInterface
        VoiceChatService.getInstance().setPrioritySystemEnabled(enabled);
    }

    private function onActivationThresholdChanged(e:Event):void {
        var slider:PCNumberSlider = e.target as PCNumberSlider;
        var threshold:int = slider.actualValue;

        trace("PCTabs: Priority system will activate when", threshold, "people are nearby");

        // Use VoiceChatService
        VoiceChatService.getInstance().setPriorityActivationThreshold(threshold);
    }

    private function onAutoPriorityChanged(e:Event):void {
        var button:PCCycleButton = e.target as PCCycleButton;

        trace("PCTabs: Auto priority changed to:", button.currentStateText);

        // Use VoiceChatService
        VoiceChatService.getInstance().setAutoPriorityGuild(button.isGuildMode);
        VoiceChatService.getInstance().setAutoPriorityLocked(button.isLockedMode);
    }

    private function onNonPriorityVolumeChanged(e:Event):void {
        var slider:PCVolumeSlider = e.target as PCVolumeSlider;
        var volume:Number = slider.value;

        trace("PCTabs: Non-priority volume changed to:", volume);

        // Use VoiceChatService
        VoiceChatService.getInstance().setNonPriorityVolume(volume);
    }

    private function onMaxSlotsChanged(e:Event):void {
        var slider:PCVolumeSlider = e.target as PCVolumeSlider;
        var slots:int = Math.round(slider.value * 45) + 5;

        slider.setValueText(slots.toString() + " slots");
        trace("PCTabs: Max priority slots changed to:", slots);

        // Use VoiceChatService
        VoiceChatService.getInstance().setMaxPrioritySlots(slots);
    }

     // VoiceChatService.getInstance().setAutoPriorityMode(button.currentState);






    private function loadPrioritySettings(background:Sprite):void {
        // TODO: Load and apply saved priority settings when we add PCSettings methods
        trace("PCTabs: Loading priority settings...");
    }

    private function onPushToTalkToggled(e:Event):void {
        var button:PCPushToTalkButton = e.target as PCPushToTalkButton;
        var enabled:Boolean = button.pushToTalkEnabled;

        trace("PCTabs: Push-to-talk toggled to:", enabled);

        // Sync with the global variable
        MapUserInput.PCUITChecker = enabled;

        // Save the state
        PCSettings.getInstance().savePushToTalkEnabled(enabled);

        VoiceChatService.getInstance().setPushToTalkMode(enabled);
        dispatchEvent(new Event("pushToTalkToggled"));
    }

    // In your PCTabs or PCManager initialization
    private function loadSavedPushToTalkState():void {
        var savedState:Boolean = PCSettings.getInstance().getPushToTalkEnabled();
        if (savedState) {
            // Get the push-to-talk button from the algorithm background
            var pushToTalkButton:PCPushToTalkButton = backgroundMicSelectors[algorithmBackground + "_pushToTalk"];
            if (pushToTalkButton) {
                // Update the button
                pushToTalkButton.pushToTalkEnabled = savedState;
            }

            // Sync the variable
            MapUserInput.PCUITChecker = savedState;
            // Set the mode
            VoiceChatService.getInstance().setPushToTalkMode(savedState);

            trace("PCTabs: Loaded saved push-to-talk state:", savedState);
        }
    }

    private function onVolumeChanged(e:Event):void {
        var slider:PCVolumeSlider = e.target as PCVolumeSlider;
        var volume:Number = slider.value;

        trace("PCTabs: Volume changed to:", volume);

        // ADD THIS LINE: Send to voice system
        VoiceChatService.getInstance().setIncomingVolume(volume);

        // Save to PCSettings for persistence
        PCSettings.getInstance().saveIncomingVolume(volume);

        // Forward event to PCManager
        dispatchEvent(new Event("volumeChanged"));
    }

    private function onMicrophoneSelected(e:Event):void {
        // Forward the event to PCManager
        dispatchEvent(new Event("microphoneSelected"));
    }

    // Event handlers
    private function onBlockedTabClick(e:MouseEvent):void {
        setActiveTab(1);
    }

    private function onAlgorithmTabClick(e:MouseEvent):void {
        setActiveTab(0);
    }

    // Public methods
    public function setActiveTab(index:int, dispatchEvent:Boolean = true):void {
        if (index < 0 || index >= tabs.length) return;
        if (index == activeTabIndex) return;

        activeTabIndex = index;
        updateTabStyling();
        updateBackgroundVisibility();

        if (dispatchEvent) {
            this.dispatchEvent(new Event(TAB_CHANGED));
        }
    }

    public function setTargetContainer(container:Sprite):void {
        targetContainer = container;

        // Add all backgrounds to the container
        for (var i:int = 0; i < tabBackgrounds.length; i++) {
            container.addChild(tabBackgrounds[i]);
        }

        updateBackgroundVisibility();
    }

    private function updateTabStyling():void {
        for (var i:int = 0; i < tabs.length; i++) {
            var tab:TabButton = tabs[i];
            var isActive:Boolean = (i == activeTabIndex);

            tab.setColors(
                    isActive ? _activeTabColor : _inactiveTabColor,
                    _hoverTabColor,
                    _borderColor,
                    isActive ? _activeTextColor : _textColor
            );

            tab.setActive(isActive);
        }
    }

    private function updateBackgroundVisibility():void {
        if (!targetContainer) return;

        // Hide all backgrounds
        for (var i:int = 0; i < tabBackgrounds.length; i++) {
            tabBackgrounds[i].visible = false;
        }

        // Show active background
        if (activeTabIndex >= 0 && activeTabIndex < tabBackgrounds.length) {
            tabBackgrounds[activeTabIndex].visible = true;
        }
    }

    // Styling methods
    public function setPosition(x:Number, y:Number):void {
        this._x = x;
        this._y = y;
        this.x = x;
        this.y = y;
    }

    public function setTabColors(activeColor:uint, inactiveColor:uint, hoverColor:uint):void {
        _activeTabColor = activeColor;
        _inactiveTabColor = inactiveColor;
        _hoverTabColor = hoverColor;
        updateTabStyling();
    }

    public function setTextColors(textColor:uint, activeTextColor:uint):void {
        _textColor = textColor;
        _activeTextColor = activeTextColor;
        updateTabStyling();
    }

    public function setBorderColor(color:uint):void {
        _borderColor = color;
        updateTabStyling();
    }

    public function setCornerRadius(radius:Number):void {
        _cornerRadius = radius;
        for (var i:int = 0; i < tabs.length; i++) {
            tabs[i].setCornerRadius(radius);
        }
    }

    public function setTabSize(width:Number, height:Number):void {
        _tabWidth = width;
        _tabHeight = height;

        // Update tab sizes and positions
        for (var i:int = 0; i < tabs.length; i++) {
            tabs[i].setSize(width, height);
            tabs[i].x = i * (width + _tabSpacing);
        }
    }

    // Getters
    public function get activeTab():int {
        return activeTabIndex;
    }

    public function get blockedTabBackground():Sprite {
        return blockedBackground;
    }

    public function get algorithmTabBackground():Sprite {
        return algorithmBackground;
    }

    public function get tabCount():int {
        return tabs.length;
    }

    // Cleanup
    public function dispose():void {
        // Remove event listeners
        if (blockedTab) {
            blockedTab.removeEventListener(MouseEvent.CLICK, onBlockedTabClick);
            blockedTab.dispose();
        }

        if (algorithmTab) {
            algorithmTab.removeEventListener(MouseEvent.CLICK, onAlgorithmTabClick);
            algorithmTab.dispose();
        }

        for each (var background:Sprite in tabBackgrounds) {
            var micSelector:PCMicSelector = getMicSelectorForBackground(background);
            if (micSelector) {
                micSelector.dispose();
            }
        }

        // Existing cleanup
        var volumeSlider:PCVolumeSlider = backgroundMicSelectors[background + "_volume"];
        if (volumeSlider) {
            volumeSlider.removeEventListener(PCVolumeSlider.VOLUME_CHANGED, onVolumeChanged);
            volumeSlider.dispose();
        }

        var pushToTalkButton:PCPushToTalkButton = backgroundMicSelectors[background + "_pushToTalk"];
        if (pushToTalkButton) {
            pushToTalkButton.removeEventListener(PCPushToTalkButton.PUSH_TO_TALK_TOGGLED, onPushToTalkToggled);
            pushToTalkButton.dispose();
        }

        // ADD NEW PRIORITY CONTROLS CLEANUP:
        var priorityToggle:PCGenericToggle = backgroundMicSelectors[background + "_priorityToggle"];
        if (priorityToggle) {
            priorityToggle.removeEventListener(PCGenericToggle.TOGGLE_CHANGED, onPriorityToggleChanged);
            priorityToggle.dispose();
        }

        var autoPriorityButton:PCCycleButton = backgroundMicSelectors[background + "_autoPriority"];
        if (autoPriorityButton) {
            autoPriorityButton.removeEventListener(PCCycleButton.STATE_CHANGED, onAutoPriorityChanged);
            autoPriorityButton.dispose();
        }

        var nonPrioritySlider:PCVolumeSlider = backgroundMicSelectors[background + "_nonPriorityVolume"];
        if (nonPrioritySlider) {
            nonPrioritySlider.removeEventListener(PCVolumeSlider.VOLUME_CHANGED, onNonPriorityVolumeChanged);
            nonPrioritySlider.dispose();
        }

        var activationThresholdSlider:PCNumberSlider = backgroundMicSelectors[background + "_activationThreshold"];
        if (activationThresholdSlider) {
            activationThresholdSlider.removeEventListener(PCNumberSlider.VALUE_CHANGED, onActivationThresholdChanged);
            activationThresholdSlider.dispose();
        }

        // Clear collections
        tabs = null;
        tabBackgrounds = null;
        targetContainer = null;
        blockedBackground = null;
        algorithmBackground = null;
        backgroundMicSelectors = null; // ADD THIS LINE TOO
    }
}
}

// Internal TabButton class
import flash.display.Sprite;
import flash.display.Shape;
import flash.display.Graphics;
import flash.text.TextField;
import flash.text.TextFormat;
import flash.text.TextFieldAutoSize;
import flash.events.MouseEvent;

class TabButton extends Sprite
{
    private var background:Shape;
    private var label:TextField;
    private var _width:Number;
    private var _height:Number;
    private var _text:String;
    private var _cornerRadius:Number;

    // Colors
    private var _normalColor:uint;
    private var _hoverColor:uint;
    private var _borderColor:uint;
    private var _textColor:uint;
    private var _isActive:Boolean;

    public function TabButton(text:String, width:Number, height:Number)
    {
        _text = text;
        _width = width;
        _height = height;
        _cornerRadius = 4;
        _isActive = false;

        initialize();
    }

    private function initialize():void
    {
        // Create background
        background = new Shape();
        addChild(background);

        // Create label
        label = new TextField();
        label.text = _text;
        label.autoSize = TextFieldAutoSize.CENTER;
        label.selectable = false;
        label.mouseEnabled = false;
        addChild(label);

        // Set up mouse interaction
        this.buttonMode = true;
        this.useHandCursor = true;

        // Add hover events
        addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);

        centerLabel();
    }

    private function centerLabel():void
    {
        // First, let it auto-size to measure the text
        label.autoSize = TextFieldAutoSize.LEFT;
        var textHeight:Number = label.textHeight;

        // Now set it to fixed size
        label.autoSize = TextFieldAutoSize.NONE;
        label.width = _width;
        label.height = _height;

        // Create a TextFormat to center the text
        var format:TextFormat = new TextFormat();
        format.align = "center";
        label.setTextFormat(format);
        label.defaultTextFormat = format;

        // Position the TextField to fill the tab with proper vertical centering
        label.x = 0;
        label.y = (_height - textHeight) / 2 - 2; // -2 for slight adjustment
    }

    private function drawBackground(color:uint):void
    {
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

    private function onMouseOver(e:MouseEvent):void
    {
        if (!_isActive)
        {
            drawBackground(_hoverColor);
        }
    }

    private function onMouseOut(e:MouseEvent):void
    {
        if (!_isActive)
        {
            drawBackground(_normalColor);
        }
    }

    public function setColors(normalColor:uint, hoverColor:uint, borderColor:uint, textColor:uint):void
    {
        _normalColor = normalColor;
        _hoverColor = hoverColor;
        _borderColor = borderColor;
        _textColor = textColor;

        label.textColor = textColor;
        drawBackground(_isActive ? _normalColor : _normalColor);
    }

    public function setActive(active:Boolean):void
    {
        _isActive = active;
        drawBackground(_normalColor);
    }

    public function setSize(width:Number, height:Number):void
    {
        _width = width;
        _height = height;
        drawBackground(_normalColor);
        centerLabel();
    }

    public function setCornerRadius(radius:Number):void
    {
        _cornerRadius = radius;
        drawBackground(_normalColor);
    }

    public function dispose():void
    {
        removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
        removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);



        if (background && background.parent) removeChild(background);
        if (label && label.parent) removeChild(label);

        background = null;
        label = null;
    }
}