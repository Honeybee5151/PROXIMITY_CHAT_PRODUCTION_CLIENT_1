// Updated VoiceChatService.as
package kabam.rotmg.ProximityChat {

import kabam.rotmg.ProximityChat.PCSettings;

import flash.events.Event;

public class VoiceChatService {
    private static var _instance:VoiceChatService;
    public var audioBridge:PCBridge;
    private var _isEnabled:Boolean = false;
    public var storedMicrophones:Array;
    private var microphoneListeners:Array = [];

    // NEW: Add settings integration
    public var settings:PCSettings;
    private var isInitialized:Boolean = false;
    private var currentPCManager:*; // Store reference to current PCManager

    private var myVoiceID:String;
    private var myPlayerID:String;
    private var gameServerIP:String;
    private var isVoiceConnected:Boolean = false;

    public static function getInstance():VoiceChatService {
        if (!_instance) {
            _instance = new VoiceChatService();
        }
        return _instance;
    }

    public function handleVoiceAuth(voiceID:String, playerID:String, serverIP:String):void {
        trace("VoiceChatService: Received VoiceAuth - VoiceID:", voiceID, "PlayerID:", playerID, "ServerIP:", serverIP);

        myVoiceID = voiceID;
        myPlayerID = playerID;
        gameServerIP = serverIP;

        // Automatically connect to voice server
        connectToVoiceServer();
    }
    public function onMicrophonesReceived(mics:Array):void {
        storedMicrophones = mics;
        trace("VoiceChatService: Microphones received:", storedMicrophones.length);

        // Determine initial mic from saved settings
        var initialMicId:String = null;
        if (settings && settings.hasSavedMicrophone()) {
            var savedMic:Object = settings.applySavedMicrophone(storedMicrophones);
            if (savedMic) {
                initialMicId = savedMic.Id;
                trace("VoiceChatService: Initial mic to select:", savedMic.Name);
            }
        }

        // Notify manager to update UI and handle selection
        if (currentPCManager) {
            currentPCManager.setAvailableMicrophones(mics);
            if (initialMicId) {
                currentPCManager.updateMicrophoneSelection(initialMicId);
            }
        }
    }
    public function connectToVoiceServer():void {
        if (!audioBridge) {
            trace("VoiceChatService: AudioBridge not available, cannot connect to voice server");
            return;
        }

        if (myVoiceID && myPlayerID && gameServerIP) {
            var connectCommand:String = "CONNECT_VOICE:" + gameServerIP + ":" + myPlayerID + ":" + myVoiceID;
            trace("VoiceChatService: Sending voice connection command:", connectCommand);
            audioBridge.sendCommand(connectCommand);
        } else {
            trace("VoiceChatService: Cannot connect - missing VoiceID, PlayerID, or server IP");
            trace("VoiceChatService: VoiceID:", myVoiceID, "PlayerID:", myPlayerID, "ServerIP:", gameServerIP);
        }
    }
    public function onVoiceConnected():void {
        isVoiceConnected = true;
        trace("VoiceChatService: Connected to voice server successfully");

        // Notify current PCManager if it exists
        if (currentPCManager && currentPCManager.hasOwnProperty("onVoiceServerConnected")) {
            currentPCManager.onVoiceServerConnected();
        }
    }
    public function onVoiceDisconnected():void {
        isVoiceConnected = false;
        trace("VoiceChatService: Disconnected from voice server");

        // Notify current PCManager if it exists
        if (currentPCManager && currentPCManager.hasOwnProperty("onVoiceServerDisconnected")) {
            currentPCManager.onVoiceServerDisconnected();
        }
    }

    // NEW: Getters for voice auth status
    public function hasVoiceAuth():Boolean {
        return myVoiceID != null && myPlayerID != null && gameServerIP != null;
    }

    public function get voiceConnected():Boolean {
        return isVoiceConnected;
    }

    public function getVoiceID():String {
        return myVoiceID;
    }

    public function getPlayerID():String {
        return myPlayerID;
    }
    public function setPushToTalkMode(enabled:Boolean):void {
        if (audioBridge) {
            if (!enabled) {
                // Fix Bug 2: Reset stuck key when disabling PTT
                audioBridge.setPushToTalkKeyState(false);
            }
            // CHANGE THIS LINE:
            // audioBridge.sendCommand("SET_PTT_MODE:" + enabled);

            // TO THIS:
            audioBridge.setPushToTalkMode(enabled);  // ← Call directly instead of sending command

            trace("VoiceChatService: Push-to-talk mode:", enabled);
        }
    }

    public function setPushToTalkKeyState(pressed:Boolean):void {
        if (audioBridge) {
            audioBridge.setPushToTalkKeyState(pressed);
            trace("VoiceChatService: Push-to-talk key state:", pressed);
        }
    }
    public function initialize():void {
        if (isInitialized) {
            return;
        }

        trace("VoiceChatService: Initializing...");

        // Initialize settings first
        try {
            settings = PCSettings.getInstance();
            settings.addEventListener(PCSettings.SETTINGS_LOADED, onSettingsLoaded);
        } catch (error:Error) {
            settings = null;
        }

        // START AUDIO BRIDGE IMMEDIATELY - don't wait for PCManager
        if (!audioBridge) {
            audioBridge = new PCBridge(null); // No PCManager initially
            audioBridge.startAudioProgram();

            // CONNECT TO VOICE SERVER if we already have auth data
            if (hasVoiceAuth()) {
                connectToVoiceServer();
            }

            // RESTORE SAVED SETTINGS even without UI
            if (settings) {
                // Apply saved chat enabled state
                var savedChatEnabled:Boolean = settings.getChatEnabled();
                if (savedChatEnabled) {
                    startMicrophone();
                    trace("VoiceChatService: Started microphone based on saved state (no UI)");

                    // CRITICAL FIX: Check PTT state and set transmission accordingly
                    var pttEnabled:Boolean = settings.getPushToTalkEnabled();
                    if (pttEnabled) {
                        // PTT is enabled - start with transmission DISABLED
                        audioBridge.sendCommand("DISABLE_AUDIO_TRANSMISSION");
                        trace("VoiceChatService: PTT enabled - transmission disabled until key pressed");
                    } else {
                        // Always-on mode - enable transmission
                        audioBridge.sendCommand("ENABLE_AUDIO_TRANSMISSION");
                        trace("VoiceChatService: Always-on mode - transmission enabled");
                    }
                }
            }
        }


        isInitialized = true;
    }
    public function setIncomingVolume(volume:Number):void {
        if (audioBridge) {
            audioBridge.setIncomingVolume(volume);
            trace("VoiceChatService: Set incoming volume to", volume);
        }

        // Save to settings
        if (settings) {
            settings.saveIncomingVolume(volume);
        }
    }


    private function onSettingsLoaded(e:Event):void {
        trace("VoiceChatService: Settings loaded, checking for saved preferences");

        // If we already have microphones stored, try to apply saved selection
        if (storedMicrophones && storedMicrophones.length > 0) {
            applySavedMicrophone();
        }

        // Apply saved chat enabled state to current PCManager
        if (settings && currentPCManager) {
            var savedChatEnabled:Boolean = settings.getChatEnabled();
            if (savedChatEnabled) {
                // Actually start the microphone, not just update UI
                startMicrophone();
                trace("VoiceChatService: Started microphone based on saved state");
            }
            currentPCManager.updateToggleState(savedChatEnabled);
            trace("VoiceChatService: Applied saved chat state:", savedChatEnabled);
        }
    }

    // NEW: Apply saved microphone selection
    private function applySavedMicrophone():void {
        if (!settings || !settings.hasSavedMicrophone()) return;

        var savedMic:Object = settings.applySavedMicrophone(storedMicrophones);
        if (!savedMic) {
            trace("VoiceChatService: Saved microphone no longer available");
            return;
        }

        trace("VoiceChatService: Applying saved microphone:", savedMic.Name);

        // Always select the microphone internally
        selectMicrophoneInternal(savedMic.Id);

        // Update UI only if it exists
        if (currentPCManager) {
            currentPCManager.updateMicrophoneSelection(savedMic.Id);
        }
    }

    // NEW: Internal microphone selection (doesn't save to settings)
    private function selectMicrophoneInternal(microphoneId:String):void {
        if (audioBridge) {
            trace("VoiceChatService: Selecting microphone internally:", microphoneId);
            audioBridge.selectMicrophone(microphoneId);
        } else {
            trace("VoiceChatService: audioBridge is null, cannot select microphone");
        }
    }

    // UPDATED: Modified to save to settings
    public function selectMicrophone(microphoneId:String):void {
        if (audioBridge) {
            audioBridge.setPushToTalkKeyState(false);
            trace("VoiceChatService: Selecting microphone:", microphoneId);
            audioBridge.selectMicrophone(microphoneId);

            // NEW: Save the microphone selection
            if (settings && storedMicrophones) {
                for (var i:int = 0; i < storedMicrophones.length; i++) {
                    var mic:Object = storedMicrophones[i];
                    if (mic.Id == microphoneId) {
                        settings.saveSelectedMicrophone(mic.Id, mic.Name);
                        trace("VoiceChatService: Saved microphone selection:", mic.Name);
                        break;
                    }
                }
            }
        } else {
            trace("VoiceChatService: audioBridge is null, cannot select microphone");
        }
    }

    // NEW: Handle chat enabled state with settings
    public function setChatEnabled(enabled:Boolean):void {
        trace("VoiceChatService: Setting chat enabled:", enabled);

        if (enabled) {
            startMicrophone();
        } else {
            stopMicrophone();
        }

        // Save the chat enabled state
        if (settings) {
            settings.saveChatEnabled(enabled);
            trace("VoiceChatService: Saved chat enabled state:", enabled);
        }
    }

    public function startMicrophone():void {
        if (audioBridge) {
            trace("VoiceChatService: Starting microphone");
            audioBridge.startMicrophone();
            _isEnabled = true;
        }
    }

    public function stopMicrophone():void {
        if (audioBridge) {
            trace("VoiceChatService: Stopping microphone");
            audioBridge.stopMicrophone();
            _isEnabled = false;
        }
    }

    public function get isEnabled():Boolean {
        return _isEnabled;
    }

    public function hasStoredMicrophones():Boolean {
        return storedMicrophones && storedMicrophones.length > 0;
    }

    public function getStoredMicrophones():Array {
        return storedMicrophones ? storedMicrophones.slice() : [];
    }

    // UPDATED: Modified to trigger saved microphone application
    public function setStoredMicrophones(mics:Array):void {
        storedMicrophones = mics ? mics.slice() : [];
        trace("VoiceChatService: Stored", storedMicrophones.length, "microphones, notifying listeners");

        // Notify all listeners (e.g., PCManager UI)
        for each (var listener:Function in microphoneListeners) {
            try {
                listener(storedMicrophones.slice());
            } catch (e:Error) {
                trace("VoiceChatService: Error notifying listener:", e.message);
            }
        }

        // Apply saved microphone automatically
        applySavedMicrophone();
    }


    public function addMicrophoneListener(listener:Function):void {
        if (microphoneListeners.indexOf(listener) == -1) {
            microphoneListeners.push(listener);
        }
    }

    public function removeMicrophoneListener(listener:Function):void {
        var index:int = microphoneListeners.indexOf(listener);
        if (index != -1) {
            microphoneListeners.splice(index, 1);
        }
    }

    // UPDATED: Store reference to current PCManager
    public function setProximityChatManager(manager:*):void {
        currentPCManager = manager;

        if (audioBridge) {
            audioBridge.proximityChatManager = manager;
            trace("VoiceChatService: Connected PCManager to existing bridge");

            // If we're already connected to voice server, update the UI
            if (isVoiceConnected) {
                manager.updateToggleState(true); // or whatever the current state should be
            }
        }
    }
// Add these methods after your existing setIncomingVolume method

    public function setPrioritySystemEnabled(enabled:Boolean):void {
        if (audioBridge) {
            audioBridge.sendCommand("SET_PRIORITY_ENABLED:" + enabled);
            trace("VoiceChatService: Set priority system enabled:", enabled);
        }

        // Save to settings if you want persistence
        if (settings) {
            // You'll need to add this method to PCSettings later
             settings.savePrioritySystemEnabled(enabled);
        }
    }

    public function setPriorityActivationThreshold(threshold:int):void {
        if (audioBridge) {
            audioBridge.sendCommand("SET_PRIORITY_THRESHOLD:" + threshold);
            trace("VoiceChatService: Set priority activation threshold:", threshold);
        }

        // Save to settings if you want persistence
        if (settings) {
            settings.savePriorityActivationThreshold(threshold);
        }
    }

    public function setAutoPriorityGuild(enabled:Boolean):void {
        if (audioBridge) {
            audioBridge.sendCommand("SET_AUTO_PRIORITY_GUILD:" + enabled);
            trace("VoiceChatService: Set auto priority for guild members:", enabled);
        }

        // Save to settings
        if (settings) {
            settings.saveAutoPriorityGuild(enabled);
        }
    }

    public function setAutoPriorityLocked(enabled:Boolean):void {
        if (audioBridge) {
            audioBridge.sendCommand("SET_AUTO_PRIORITY_LOCKED:" + enabled);
            trace("VoiceChatService: Set auto priority for locked players:", enabled);
        }

        // Save to settings
        if (settings) {
            settings.saveAutoPriorityLocked(enabled);
        }
    }

    public function setNonPriorityVolume(volume:Number):void {
        if (audioBridge) {
            audioBridge.sendCommand("SET_NON_PRIORITY_VOLUME:" + volume);
            trace("VoiceChatService: Set non-priority volume:", volume);
        }

        // Save to settings
        if (settings) {
            settings.saveNonPriorityVolume(volume);
        }
    }

    public function setMaxPrioritySlots(slots:int):void {
        if (audioBridge) {
            audioBridge.sendCommand("SET_MAX_PRIORITY_SLOTS:" + slots);
            trace("VoiceChatService: Set max priority slots:", slots);
        }

        // Save to settings
        if (settings) {
             settings.saveMaxPrioritySlots(slots);
        }
    }

    public function addManualPriority(accountId:int):void {
        if (audioBridge) {
            audioBridge.sendCommand("ADD_MANUAL_PRIORITY:" + accountId);
            trace("VoiceChatService: Added manual priority for account:", accountId);
        }
    }

    public function removeManualPriority(accountId:int):void {
        if (audioBridge) {
            audioBridge.sendCommand("REMOVE_MANUAL_PRIORITY:" + accountId);
            trace("VoiceChatService: Removed manual priority for account:", accountId);
        }
    }
    // UPDATED: Enhanced dispose with settings cleanup
    public function dispose(onComplete:Function = null):void {
        if (settings) {
            settings.removeEventListener(PCSettings.SETTINGS_LOADED, onSettingsLoaded);
            settings = null;
        }

        if (audioBridge) {
            if (onComplete != null) {
                // Add the exit listener before disposing
                audioBridge.addProcessExitListener(onComplete);
            }
            audioBridge.dispose(); // Sends EXIT command
            audioBridge = null;
        } else if (onComplete != null) {
            // No audioBridge, call callback immediately
            onComplete(null);
        }

        currentPCManager = null;
        _isEnabled = false;
        isInitialized = false;
    }
}
}