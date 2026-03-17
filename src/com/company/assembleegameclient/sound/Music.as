package com.company.assembleegameclient.sound {
import com.company.assembleegameclient.parameters.Parameters;

public class Music {
   private static var musicName:String;
   private static var song:Song;

   public static function load(name:String):void {
      trace("[Music] load() called with name: '" + name + "' playMusic=" + Parameters.data_.playMusic + " musicVolume=" + Parameters.data_.musicVolume);
      if (musicName == name) {
         trace("[Music] Same music, skipping");
         return;
      }

      musicName = name;

      if (Parameters.data_.playMusic) {
         transitionNewMusic();
      } else {
         trace("[Music] playMusic is false, not playing");
      }
   }

   private static function transitionNewMusic():void {
      if (song) {
         song.stop();
      }

      if (musicName == null || musicName == ""
              || Parameters.data_.musicVolume == 0 || !Parameters.data_.playMusic) {
         return;
      }
      song = new Song(musicName);
      song.play(Parameters.data_.musicVolume);
   }

   public static function setPlayMusic(play:Boolean):void {
      Parameters.data_.playMusic = play;
      Parameters.save();

      if (play) {
         transitionNewMusic();
      }

      else if (song) {
         song.stop(true);
         song = null;
      }
   }

   public static function setMusicVolume(newVol:Number):void {
      Parameters.data_.musicVolume = newVol;
      Parameters.save();

      if (newVol == 0) {
         if (song) song.stop(true);
         return;
      }

      if (Parameters.data_.playMusic && song) {
         song.volume = newVol;
      }
   }
}
}
