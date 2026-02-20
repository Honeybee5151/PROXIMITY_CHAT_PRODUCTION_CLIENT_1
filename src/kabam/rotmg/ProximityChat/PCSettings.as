package kabam.rotmg.ProximityChat {

import flash.net.SharedObject;
import flash.events.EventDispatcher;
import flash.events.Event;

/**
 * PCSettings manages persistent settings for Proximity Chat
 * Currently handles microphone selection persistence
 */
public class PCSettings extends EventDispatcher
{
    private static var _instance:PCSettings;
    private var _sharedObject:SharedObject;
    private static const INCOMING_VOLUME:String = "incomingVolume";
    // Setting keys
    private static const SELECTED_MIC_ID:String = "selectedMicrophoneId";
    private static const SELECTED_MIC_NAME:String = "selectedMicrophoneName";
    private static const CHAT_ENABLED:String = "chatEnabled";
    private static const AUDIO_LEVEL:String = "audioLevel";
    private static const PUSH_TO_TALK_ENABLED:String = "pushToTalkEnabled";

    // Events
    public static const SETTINGS_LOADED:String = "settingsLoaded";
    public static const SETTINGS_SAVED:String = "settingsSaved";
    public static const MIC_SELECTION_CHANGED:String = "micSelectionChanged";

    private static const PRIORITY_SYSTEM_ENABLED:String = "prioritySystemEnabled";
    private static const PRIORITY_ACTIVATION_THRESHOLD:String = "priorityActivationThreshold";
    private static const AUTO_PRIORITY_GUILD:String = "autoPriorityGuild";
    private static const AUTO_PRIORITY_LOCKED:String = "autoPriorityLocked";
    private static const NON_PRIORITY_VOLUME:String = "nonPriorityVolume";
    private static const MAX_PRIORITY_SLOTS:String = "maxPrioritySlots";



    public function PCSettings()
    {
        if (_instance != null)
        {
            throw new Error("PCSettings is a singleton. Use getInstance()");
        }

        initialize();
    }

    public static function getInstance():PCSettings
    {
        if (_instance == null)
        {
            _instance = new PCSettings();
        }
        return _instance;
    }

    private function initialize():void
    {
        try
        {
            _sharedObject = SharedObject.getLocal("proximityChat_settings");
            trace("PCSettings: SharedObject initialized successfully");

            // Dispatch loaded event after a frame to ensure listeners can be set up
            dispatchEvent(new Event(SETTINGS_LOADED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to initialize SharedObject:", error.message);
            // Create a fallback object structure
            _sharedObject = null;
        }
    }
    public function saveIncomingVolume(volume:Number):void
    {
        if (!_sharedObject)
        {
            return;
        }

        try
        {
            _sharedObject.data[INCOMING_VOLUME] = volume;
            _sharedObject.flush();

            trace("PCSettings: Saved incoming volume:", volume);

            dispatchEvent(new Event(SETTINGS_SAVED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to save incoming volume:", error.message);
        }
    }

    /**
     * Get saved incoming volume (defaults to 1.0 = 100%)
     */
    public function getIncomingVolume():Number
    {
        if (!_sharedObject || _sharedObject.data[INCOMING_VOLUME] === undefined)
        {
            return 0.0; // Default to full volume
        }

        return _sharedObject.data[INCOMING_VOLUME] as Number;
    }
    /**
     * Save the selected microphone information
     */
    public function saveSelectedMicrophone(micId:String, micName:String):void
    {
        if (!_sharedObject)
        {
            trace("PCSettings: Cannot save microphone - SharedObject not available");
            return;
        }

        try
        {
            _sharedObject.data[SELECTED_MIC_ID] = micId;
            _sharedObject.data[SELECTED_MIC_NAME] = micName;
            _sharedObject.flush();

            trace("PCSettings: Saved microphone -", micName, "(" + micId + ")");

            dispatchEvent(new Event(SETTINGS_SAVED));
            dispatchEvent(new Event(MIC_SELECTION_CHANGED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to save microphone:", error.message);
        }
    }

    /**
     * Get the saved microphone ID
     */
    public function getSavedMicrophoneId():String
    {
        if (!_sharedObject || !_sharedObject.data[SELECTED_MIC_ID])
        {
            return null;
        }

        return _sharedObject.data[SELECTED_MIC_ID] as String;
    }

    /**
     * Get the saved microphone name
     */
    public function getSavedMicrophoneName():String
    {
        if (!_sharedObject || !_sharedObject.data[SELECTED_MIC_NAME])
        {
            return null;
        }

        return _sharedObject.data[SELECTED_MIC_NAME] as String;
    }

    /**
     * Check if a microphone selection has been saved
     */
    public function hasSavedMicrophone():Boolean
    {
        return getSavedMicrophoneId() != null;
    }

    /**
     * Clear the saved microphone selection
     */
    public function clearSavedMicrophone():void
    {
        if (!_sharedObject)
        {
            return;
        }

        try
        {
            delete _sharedObject.data[SELECTED_MIC_ID];
            delete _sharedObject.data[SELECTED_MIC_NAME];
            _sharedObject.flush();

            trace("PCSettings: Cleared saved microphone selection");

            dispatchEvent(new Event(SETTINGS_SAVED));
            dispatchEvent(new Event(MIC_SELECTION_CHANGED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to clear microphone:", error.message);
        }
    }

    /**
     * Save chat enabled state
     */
    public function saveChatEnabled(enabled:Boolean):void
    {
        if (!_sharedObject)
        {
            return;
        }

        try
        {
            _sharedObject.data[CHAT_ENABLED] = enabled;
            _sharedObject.flush();

            trace("PCSettings: Saved chat enabled state:", enabled);

            dispatchEvent(new Event(SETTINGS_SAVED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to save chat enabled state:", error.message);
        }


    }
    /**
     * Save push-to-talk enabled state
     */
    public function savePushToTalkEnabled(enabled:Boolean):void
    {
        if (!_sharedObject)
        {
            return;
        }

        try
        {
            _sharedObject.data[PUSH_TO_TALK_ENABLED] = enabled;
            _sharedObject.flush();

            trace("PCSettings: Saved push-to-talk enabled state:", enabled);

            dispatchEvent(new Event(SETTINGS_SAVED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to save push-to-talk enabled state:", error.message);
        }
    }

    /**
     * Get saved push-to-talk enabled state (defaults to false)
     */
    public function getPushToTalkEnabled():Boolean
    {
        if (!_sharedObject || _sharedObject.data[PUSH_TO_TALK_ENABLED] === undefined)
        {
            return false;
        }

        return _sharedObject.data[PUSH_TO_TALK_ENABLED] as Boolean;
    }
    /**
     * Get saved chat enabled state (defaults to false)
     */
    public function getChatEnabled():Boolean
    {
        if (!_sharedObject || _sharedObject.data[CHAT_ENABLED] === undefined)
        {
            return false;
        }

        return _sharedObject.data[CHAT_ENABLED] as Boolean;
    }

    /**
     * Save audio level setting
     */
    public function saveAudioLevel(level:Number):void
    {
        if (!_sharedObject)
        {
            return;
        }

        try
        {
            _sharedObject.data[AUDIO_LEVEL] = level;
            _sharedObject.flush();

            trace("PCSettings: Saved audio level:", level);

            dispatchEvent(new Event(SETTINGS_SAVED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to save audio level:", error.message);
        }
    }

    /**
     * Get saved audio level (defaults to 0.5)
     */
    public function getAudioLevel():Number
    {
        if (!_sharedObject || _sharedObject.data[AUDIO_LEVEL] === undefined)
        {
            return 0.5;
        }

        return _sharedObject.data[AUDIO_LEVEL] as Number;
    }

    /**
     * Validate that a saved microphone ID still exists in the available microphones
     */
    public function validateSavedMicrophone(availableMicrophones:Array):Boolean
    {
        var savedId:String = getSavedMicrophoneId();
        if (!savedId)
        {
            return false;
        }

        for (var i:int = 0; i < availableMicrophones.length; i++)
        {
            var mic:Object = availableMicrophones[i];
            if (mic.Id == savedId)
            {
                return true;
            }
        }

        trace("PCSettings: Saved microphone no longer available:", savedId);
        return false;
    }

    /**
     * Auto-select the saved microphone if it's available
     * Returns true if a saved microphone was found and is still available
     */
    public function applySavedMicrophone(availableMicrophones:Array):Object
    {
        if (!hasSavedMicrophone() || !validateSavedMicrophone(availableMicrophones))
        {
            return null;
        }

        var savedId:String = getSavedMicrophoneId();

        for (var i:int = 0; i < availableMicrophones.length; i++)
        {
            var mic:Object = availableMicrophones[i];
            if (mic.Id == savedId)
            {
                trace("PCSettings: Found saved microphone:", mic.Name);

                return mic;
            }
        }

        return null;
    }
    public function savePrioritySystemEnabled(enabled:Boolean):void {
        if (!_sharedObject) return;
        try {
            _sharedObject.data[PRIORITY_SYSTEM_ENABLED] = enabled;
            _sharedObject.flush();
            trace("PCSettings: Saved priority system enabled:", enabled);
            dispatchEvent(new Event(SETTINGS_SAVED));
        } catch (error:Error) {
            trace("PCSettings: Failed to save priority system enabled:", error.message);
        }
    }

    public function getPrioritySystemEnabled():Boolean {
        if (!_sharedObject || _sharedObject.data[PRIORITY_SYSTEM_ENABLED] === undefined) {
            return false;
        }
        return _sharedObject.data[PRIORITY_SYSTEM_ENABLED] as Boolean;
    }

    public function savePriorityActivationThreshold(threshold:int):void {
        if (!_sharedObject) return;
        try {
            _sharedObject.data[PRIORITY_ACTIVATION_THRESHOLD] = threshold;
            _sharedObject.flush();
            dispatchEvent(new Event(SETTINGS_SAVED));
        } catch (error:Error) {
            trace("PCSettings: Failed to save threshold:", error.message);
        }
    }

    public function getPriorityActivationThreshold():int {
        if (!_sharedObject || _sharedObject.data[PRIORITY_ACTIVATION_THRESHOLD] === undefined) {
            return 8;
        }
        return _sharedObject.data[PRIORITY_ACTIVATION_THRESHOLD] as int;
    }

    public function saveNonPriorityVolume(volume:Number):void {
        if (!_sharedObject) return;
        try {
            _sharedObject.data[NON_PRIORITY_VOLUME] = volume;
            _sharedObject.flush();
            dispatchEvent(new Event(SETTINGS_SAVED));
        } catch (error:Error) {
            trace("PCSettings: Failed to save non-priority volume:", error.message);
        }
    }
    public function saveAutoPriorityGuild(enabled:Boolean):void {
        if (!_sharedObject) return;
        try {
            _sharedObject.data[AUTO_PRIORITY_GUILD] = enabled;
            _sharedObject.flush();
            trace("PCSettings: Saved auto priority guild:", enabled);
            dispatchEvent(new Event(SETTINGS_SAVED));
        } catch (error:Error) {
            trace("PCSettings: Failed to save auto priority guild:", error.message);
        }
    }

    public function getAutoPriorityGuild():Boolean {
        if (!_sharedObject || _sharedObject.data[AUTO_PRIORITY_GUILD] === undefined) {
            return true; // Default to enabled
        }
        return _sharedObject.data[AUTO_PRIORITY_GUILD] as Boolean;
    }

    public function saveAutoPriorityLocked(enabled:Boolean):void {
        if (!_sharedObject) return;
        try {
            _sharedObject.data[AUTO_PRIORITY_LOCKED] = enabled;
            _sharedObject.flush();
            trace("PCSettings: Saved auto priority locked:", enabled);
            dispatchEvent(new Event(SETTINGS_SAVED));
        } catch (error:Error) {
            trace("PCSettings: Failed to save auto priority locked:", error.message);
        }
    }

    public function getAutoPriorityLocked():Boolean {
        if (!_sharedObject || _sharedObject.data[AUTO_PRIORITY_LOCKED] === undefined) {
            return true; // Default to enabled
        }
        return _sharedObject.data[AUTO_PRIORITY_LOCKED] as Boolean;
    }

    public function saveMaxPrioritySlots(slots:int):void {
        if (!_sharedObject) return;
        try {
            _sharedObject.data[MAX_PRIORITY_SLOTS] = slots;
            _sharedObject.flush();
            trace("PCSettings: Saved max priority slots:", slots);
            dispatchEvent(new Event(SETTINGS_SAVED));
        } catch (error:Error) {
            trace("PCSettings: Failed to save max priority slots:", error.message);
        }
    }

    public function getMaxPrioritySlots():int {
        if (!_sharedObject || _sharedObject.data[MAX_PRIORITY_SLOTS] === undefined) {
            return 10; // Default to 10 slots
        }
        return _sharedObject.data[MAX_PRIORITY_SLOTS] as int;
    }

    public function getNonPriorityVolume():Number {
        if (!_sharedObject || _sharedObject.data[NON_PRIORITY_VOLUME] === undefined) {
            return 0.2;
        }
        return _sharedObject.data[NON_PRIORITY_VOLUME] as Number;
    }
    /**
     * Get all settings as an object (useful for debugging)
     */
    public function getAllSettings():Object
    {
        if (!_sharedObject)
        {
            return {};
        }

        return {
            selectedMicId: getSavedMicrophoneId(),
            selectedMicName: getSavedMicrophoneName(),
            chatEnabled: getChatEnabled(),
            audioLevel: getAudioLevel(),
            pushToTalkEnabled: getPushToTalkEnabled()
        };
    }

    /**
     * Clear all settings
     */
    public function clearAllSettings():void
    {
        if (!_sharedObject)
        {
            return;
        }

        try
        {
            _sharedObject.clear();
            _sharedObject.flush();

            trace("PCSettings: Cleared all settings");

            dispatchEvent(new Event(SETTINGS_SAVED));
        }
        catch (error:Error)
        {
            trace("PCSettings: Failed to clear all settings:", error.message);
        }
    }

    /**
     * Check if SharedObject is available and working
     */
    public function isAvailable():Boolean
    {
        return _sharedObject != null;
    }

    public function dispose():void
    {
        if (_sharedObject)
        {
            try
            {
                _sharedObject.flush();
            }
            catch (error:Error)
            {
                trace("PCSettings: Error flushing SharedObject during dispose:", error.message);
            }
            _sharedObject = null;
        }

        _instance = null;
    }
}
}