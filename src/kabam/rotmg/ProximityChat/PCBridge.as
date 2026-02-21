package kabam.rotmg.ProximityChat {
import com.company.assembleegameclient.game.MapUserInput;

import flash.desktop.NativeProcess;
import flash.desktop.NativeProcessStartupInfo;
import flash.events.EventDispatcher;
import flash.events.NativeProcessExitEvent;
import flash.filesystem.File;
import flash.events.ProgressEvent;
import flash.events.Event;
import flash.utils.ByteArray;
import flash.utils.setTimeout;

public class PCBridge extends EventDispatcher  {
    public var audioProcess:NativeProcess;
    public var proximityChatManager:PCManager;
    private var availableMicrophones:Array;
    private var pushToTalkEnabled:Boolean = false;
    private var pushToTalkKeyPressed:Boolean = false;
    public static const PTT_STATE_CHANGED:String = "PTT_STATE_CHANGED";
    private var processAlive:Boolean = false;
    private var isDisposing:Boolean = false;
    private var retryCount:int = 0;
    private static const MAX_RETRIES:int = 3;

    public function PCBridge(manager:PCManager = null) {
        proximityChatManager = manager;
    }

    public function startAudioProgram():void {
        trace("PCBridge: CONSTRUCTOR CALLED - VERSION 789 - NEW CODE LOADED");
        try {
            trace("PCBridge: Application directory:", File.applicationDirectory.nativePath);

            var subDir:File = File.applicationDirectory.resolvePath("proximitychat");
            var file:File = subDir.resolvePath("ConsoleApp1.exe");

            trace("PCBridge: Looking for audio program at:", file.nativePath);
            trace("PCBridge: File exists:", file.exists);

            var files:Array = subDir.getDirectoryListing();
            trace("PCBridge: Files in proximitychat directory:");
            for each (var f:File in files) {
                trace("  - " + f.name);
            }

            if (!file.exists) {
                trace("PCBridge: ERROR - ConsoleApp1.exe not found in proximitychat/!");
                return;
            }

            var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
            startupInfo.executable = file;
            startupInfo.workingDirectory = subDir;

            audioProcess = new NativeProcess();
            audioProcess.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
            audioProcess.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
            audioProcess.addEventListener(NativeProcessExitEvent.EXIT, onProcessExit);

            trace("PCBridge: Starting audio process...");
            audioProcess.start(startupInfo);

            if (audioProcess.running) {
                processAlive = true;
                retryCount = 0;
                trace("PCBridge: Process started successfully");
                trace("PCBridge: Process running =", audioProcess.running);
                setTimeout(connectToPipe, 1000);
            } else {
                trace("PCBridge: Process failed to start");
                processAlive = false;
                retryLaunch();
            }
        } catch (e:Error) {
            trace("PCBridge: Error starting audio program:", e.message);
            processAlive = false;
            retryLaunch();
        }
    }

    public function setIncomingVolume(volume:Number):void {
        var command:String = "SET_INCOMING_VOLUME:" + volume.toFixed(2);
        sendCommand(command);
        trace("PCBridge: Set incoming volume to", volume);
    }

    public function setSpeakerIconMode(mode:String):void {
        sendCommand("SET_SPEAKER_ICON:" + mode);
        trace("PCBridge: Set speaker icon mode to", mode);
    }

    private function connectToPipe():void {
        sendCommand("GET_MICS");
    }

    private function onOutputData(e:ProgressEvent):void {
        var output:String = audioProcess.standardOutput.readUTFBytes(audioProcess.standardOutput.bytesAvailable);
        processAudioMessage(output);
    }

    private function onErrorData(e:ProgressEvent):void
    {
        var error:String = audioProcess.standardError.readUTFBytes(audioProcess.standardError.bytesAvailable);
        trace("PCBridge: *** C# ERROR ***:", error);

        // ADD THIS LINE - Process the error stream too!
        processAudioMessage(error);
    }
    private function onProcessExit(e:NativeProcessExitEvent):void {
        trace("PCBridge: Audio process exited with code:", e.exitCode);
        processAlive = false;

        // Only auto-retry on unexpected crash — NOT during intentional dispose
        if (e.exitCode != 0 && !isDisposing) {
            trace("PCBridge: Unexpected exit - attempting restart");
            retryLaunch();
        }
    }

    private function retryLaunch():void {
        if (retryCount < MAX_RETRIES) {
            retryCount++;
            trace("PCBridge: Retry " + retryCount + "/" + MAX_RETRIES + " in 2 seconds...");
            setTimeout(startAudioProgram, 2000);
        } else {
            trace("PCBridge: Max retries reached - voice chat unavailable");
        }
    }

    public function setUIState(isUIActive:Boolean):void {
        if (MapUserInput.PCUIChecker) {
            sendCommand("UI_ON");
        } else {
            sendCommand("UI_OFF");
        }
    }

    private function processAudioMessage(message:String):void {
        try {
            var lines:Array = message.split('\n');

            for each (var line:String in lines) {
                if (line.length == 0) continue;

                // Strip CMD: prefix if present
                if (line.indexOf("CMD:") == 0) {
                    line = line.substring(4); // Remove "CMD:" prefix
                } else {
                    // Not a command, ignore it (it's a log message)
                    continue;
                }

                var parts:Array = line.split(':');
                if (parts.length < 2) continue;

                var command:String = parts[0] ? parts[0].toString() : "null";
                var value:String = parts[1] ? parts[1].toString() : "null";

                switch (parts[0]) {
                    case "MIC_STATUS":
                        try {
                            trace("PCBridge: Entered MIC_STATUS case");
                            var rawValue:String = parts[1] ? String(parts[1]) : "";
                            rawValue = rawValue.replace(/\s/g, "").toLowerCase();
                            var isEnabled:Boolean = (rawValue == "true");
                            trace("PCBridge: MIC_STATUS -", parts[1], "→", isEnabled);

                            if (proximityChatManager) {
                                proximityChatManager.updateToggleState(isEnabled);
                                if (!isEnabled) {
                                    trace("PCBridge: Microphone turned OFF - resetting visualizer to 0");
                                    proximityChatManager.updateVisualizerLevel(0);
                                }
                            }
                        } catch (e:Error) {
                            trace("PCBridge: ERROR in MIC_STATUS:", e.message);
                        }
                        break;

                    case "MIC_COUNT":
                        trace("PCBridge: Found", parts[1], "microphones");
                        break;

                    case "SELECTED_MIC":
                        trace("PCBridge: Selected microphone:", parts[1]);
                        break;

                    case "AUDIO_LEVEL":
                        var level:Number = parseFloat(parts[1]);
                        trace("PCBridge: *** AUDIO_LEVEL COMMAND RECEIVED ***:", parts[1], "parsed as:", level);
                        if (proximityChatManager) {
                            proximityChatManager.updateVisualizerLevel(level);
                        }
                        break;

                    case "VOICE_CONNECTED":
                        trace("PCBridge: Successfully connected to voice server");
                        VoiceChatService.getInstance().onVoiceConnected();
                        break;

                    case "VOICE_DISCONNECTED":
                        trace("PCBridge: Disconnected from voice server");
                        VoiceChatService.getInstance().onVoiceDisconnected();
                        break;

                    case "MIC_DEVICE":
                        trace("PCBridge: *** MIC_DEVICE case triggered ***");
                        var micData:Array = value.split('|');
                        trace("PCBridge: Parsed mic data:", micData);
                        if (micData.length >= 3) {
                            var micInfo:Object = {
                                Id: micData[0].replace(/\s/g, ""),
                                Name: micData[1],
                                IsDefault: micData[2].replace(/\s/g, "").toLowerCase() == "true"
                            };
                            trace("PCBridge: Created mic info:", micInfo.Name, "Default:", micInfo.IsDefault);

                            if (!availableMicrophones) availableMicrophones = [];
                            availableMicrophones.push(micInfo);
                            trace("PCBridge: Total mics collected:", availableMicrophones.length);
                        }
                        break;

                    case "DEFAULT_MIC":
                        trace("PCBridge: *** DEFAULT_MIC case triggered ***");
                        trace("PCBridge: availableMicrophones exists:", availableMicrophones != null);
                        trace("PCBridge: availableMicrophones length:", availableMicrophones ? availableMicrophones.length : 0);

                        if (availableMicrophones && availableMicrophones.length > 0) {
                            trace("PCBridge: Storing microphones in VoiceChatService");

                            // Print what we're sending
                            for (var i:int = 0; i < availableMicrophones.length; i++) {
                                trace("PCBridge: Mic[" + i + "]:", availableMicrophones[i].Name);
                            }

                            VoiceChatService.getInstance().setStoredMicrophones(availableMicrophones);
                            trace("PCBridge: Microphones stored in VoiceChatService");

                            if (proximityChatManager) {
                                trace("PCBridge: Sending to current PCManager");
                                proximityChatManager.setAvailableMicrophones(availableMicrophones);
                            } else {
                                trace("PCBridge: ⚠️ WARNING - proximityChatManager is NULL!");
                            }

                            availableMicrophones = [];
                        } else {
                            trace("PCBridge: ⚠️ No microphones to store!");
                        }
                        break;

                    case "CLIENT_PORT":
                        trace("PCBridge: Client port:", parts[1]);
                        // Handle client port if needed
                        break;

                    //777592 - Speaker icon events from C# voice mixer
                    case "SPEAKING":
                        VoiceChatService.getInstance().onPlayerSpeaking(parts[1].replace(/\s/g, ""));
                        break;

                    case "SILENT":
                        VoiceChatService.getInstance().onPlayerSilent(parts[1].replace(/\s/g, ""));
                        break;

                    default:
                        trace("PCBridge: Unknown command:", parts[0]);
                        break;
                }
            }
        } catch (error:Error) {
            trace("PCBridge: ERROR in processAudioMessage:", error.message);
            trace("PCBridge: Error stack:", error.getStackTrace());
            trace("PCBridge: Raw message was:", message);
        }
    }
    public function sendCommand(command:String):void {
        if (!processAlive || !audioProcess || !audioProcess.running) {
            return; // Silently skip - voice unavailable
        }
        try {
            var bytes:ByteArray = new ByteArray();
            bytes.writeMultiByte(command + "\n", "utf-8");
            bytes.position = 0;
            audioProcess.standardInput.writeBytes(bytes, 0, bytes.length);
        } catch (e:Error) {
            trace("PCBridge: Error sending command:", e.message);
            processAlive = false;
        }
    }
    public function startMicrophone():void {
        sendCommand("START_MIC");
        trace("PCBridge: Starting microphone");

        if (pushToTalkEnabled) {
            if (pushToTalkKeyPressed) {
                sendCommand("ENABLE_AUDIO_TRANSMISSION");
            } else {
                sendCommand("DISABLE_AUDIO_TRANSMISSION");
            }
        } else {
            sendCommand("ENABLE_AUDIO_TRANSMISSION");
        }
    }

    public function stopMicrophone():void {
        sendCommand("STOP_MIC");
    }

    public function selectMicrophone(micId:String):void {
        sendCommand("SELECT_MIC:" + micId);
    }

    public function setPushToTalkMode(enabled:Boolean):void {
        pushToTalkEnabled = enabled;

        if (enabled) {
            if (!pushToTalkKeyPressed) {
                sendCommand("DISABLE_AUDIO_TRANSMISSION");
            }
            trace("PCBridge: Push-to-talk mode enabled");
        } else {
            sendCommand("ENABLE_AUDIO_TRANSMISSION");
            trace("PCBridge: Push-to-talk mode disabled - normal mode");
        }
    }

    public function setPushToTalkKeyState(pressed:Boolean):void {
        pushToTalkKeyPressed = pressed;

        if (pushToTalkEnabled) {
            if (pressed) {
                sendCommand("ENABLE_AUDIO_TRANSMISSION");
                trace("PCBridge: PTT key pressed - enabling audio transmission");
            } else {
                sendCommand("DISABLE_AUDIO_TRANSMISSION");
                trace("PCBridge: PTT key released - disabling audio transmission");
            }
        }

        dispatchEvent(new PTTStateEvent(PTT_STATE_CHANGED, pressed));
    }

    private function updateMicrophoneList(jsonString:String):void {
        trace("Received microphone list:", jsonString);
    }

    public function dispose():void {
        trace("PCBridge: dispose() called");
        isDisposing = true;

        try {
            if (audioProcess && audioProcess.running) {
                sendCommand("EXIT");

                setTimeout(function ():void {
                    if (audioProcess && audioProcess.running) {
                        trace("PCBridge: Force closing process");
                        audioProcess.exit(true);
                    }
                }, 100);
            }
        } catch (e:Error) {
            trace("PCBridge: Error during disposal:", e.message);
            if (audioProcess) {
                try {
                    audioProcess.exit(true);
                } catch (e2:Error) {
                    trace("PCBridge: Force close also failed:", e2.message);
                }
            }
        }
    }

    public function sendStoredMicrophones():void {
        trace("PCBridge: sendStoredMicrophones() called");
        trace("PCBridge: availableMicrophones exists:", availableMicrophones != null);
        trace("PCBridge: availableMicrophones length:", availableMicrophones ? availableMicrophones.length : 0);
        trace("PCBridge: proximityChatManager exists:", proximityChatManager != null);

        if (availableMicrophones && availableMicrophones.length > 0 && proximityChatManager) {
            trace("PCBridge: Sending stored microphones to PCManager");
            proximityChatManager.setAvailableMicrophones(availableMicrophones);
            availableMicrophones = [];
        }
    }

    public function addProcessExitListener(callback:Function):void {
        if (audioProcess && audioProcess.running) {
            audioProcess.addEventListener(NativeProcessExitEvent.EXIT, callback);
            trace("PCBridge: Added exit listener to audio process");
        } else if (callback != null) {
            trace("PCBridge: Process not running, calling callback immediately");
            callback(null);
        }
    }
}
}