package com.company.assembleegameclient.sound {
import com.gskinner.motion.GTween;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import flash.net.URLRequest;

import kabam.rotmg.application.api.ApplicationSetup;
import kabam.rotmg.core.StaticInjectorContext;

public class Song {

    private var sound:Sound;
    private var transform:SoundTransform;
    private var channel:SoundChannel;
    private var tween:GTween;
    private var songUrl:String;
    private var loaded:Boolean = false;
    private var pendingVolume:Number = -1;
    private var pendingFadeTime:Number = 2;
    private var pendingLoops:int = int.MAX_VALUE;
    private var retryCount:int = 0;
    private static const MAX_RETRIES:int = 2;


    public function Song(name:String) {
        var url:String;
        if (name.indexOf("http") == 0) {
            url = name; // External URL — use directly
        } else {
            var setup:ApplicationSetup = StaticInjectorContext.getInjector().getInstance(ApplicationSetup);
            url = setup.getAppEngineUrl() + "/music/" + name + ".mp3";
        }
        songUrl = url;
        trace("[Song] Loading music from: " + url);
        transform = new SoundTransform(0);
        tween = new GTween(transform);
        tween.onChange = updateTransform;
        loadSound();
    }

    private function loadSound():void {
        sound = new Sound();
        sound.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
        sound.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
        sound.addEventListener(Event.COMPLETE, onLoadComplete);
        sound.load(new URLRequest(songUrl));
    }

    private function onLoadError(e:IOErrorEvent):void {
        trace("[Song] IO ERROR loading music: " + e.text + " URL: " + songUrl);
        if (retryCount < MAX_RETRIES) {
            retryCount++;
            trace("[Song] Retrying (" + retryCount + "/" + MAX_RETRIES + ")...");
            loadSound();
        }
    }

    private function onSecurityError(e:SecurityErrorEvent):void {
        trace("[Song] SECURITY ERROR loading music: " + e.text + " URL: " + songUrl);
    }

    private function onLoadComplete(e:Event):void {
        trace("[Song] Music loaded successfully: " + songUrl + " (" + sound.length + "ms)");
        loaded = true;
        if (pendingVolume >= 0) {
            playNow(pendingVolume, pendingFadeTime, pendingLoops);
            pendingVolume = -1;
        }
    }

    public function play(volume:Number = 1.0, fadeTime:Number = 2, loops:int = int.MAX_VALUE):void {
        trace("[Song] play() called, volume=" + volume + " loaded=" + loaded);
        if (loaded) {
            playNow(volume, fadeTime, loops);
        } else {
            pendingVolume = volume;
            pendingFadeTime = fadeTime;
            pendingLoops = loops;
            trace("[Song] Deferring play until load completes");
        }
    }

    private function playNow(volume:Number, fadeTime:Number, loops:int):void {
        trace("[Song] Playing music now, volume=" + volume + " fadeTime=" + fadeTime);
        if (channel) {
            channel.stop();
        }
        tween.duration = fadeTime;
        tween.setValue("volume", volume);
        channel = sound.play(0, loops, transform);
        if (!channel) {
            trace("[Song] WARNING: sound.play() returned null channel!");
        }
    }

    public function stop(noFade:Boolean = false):void {
        if (channel) {
            tween.onComplete = stopChannel;
            tween.setValue("volume", 0);
            if (noFade) {
                transform.volume = 0;
            }
        }
    }

    public function get volume():Number {
        return transform.volume;
    }

    public function set volume(volume:Number):void {
        transform.volume = volume;
        tween.setValue("volume", volume);
    }

    private function updateTransform(tween:GTween = null):void {
        if (channel) {
            channel.soundTransform = transform;
        }
    }

    private function stopChannel(tween:GTween):void {
        channel.stop();
        channel = null;
    }


}
}