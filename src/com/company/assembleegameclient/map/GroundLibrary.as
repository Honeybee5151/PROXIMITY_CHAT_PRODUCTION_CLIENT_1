// Decompiled by AS3 Sorcerer 6.08
// www.as3sorcerer.com

//com.company.assembleegameclient.map.GroundLibrary

package com.company.assembleegameclient.map
{
import flash.utils.Dictionary;
import com.company.assembleegameclient.objects.TextureDataConcrete;
import flash.display.BitmapData;
import com.company.util.BitmapUtil;

public class GroundLibrary
{

   public static const propsLibrary_:Dictionary = new Dictionary();
   public static const xmlLibrary_:Dictionary = new Dictionary();
   private static var tileTypeColorDict_:Dictionary = new Dictionary();
   public static const typeToTextureData_:Dictionary = new Dictionary();
   public static var idToType_:Dictionary = new Dictionary();
   public static var defaultProps_:GroundProperties;
   public static var GROUND_CATEGORY:String = "Ground";


   public static function parseFromXML(_arg_1:XML):void
   {
      var _local_2:XML;
      var _local_3:int;
      var _local_4:TextureDataConcrete;
      var _local_5:String;
      for each (_local_2 in _arg_1.Ground)
      {
         _local_3 = int(_local_2.@type);
         propsLibrary_[_local_3] = new GroundProperties(_local_2);
         xmlLibrary_[_local_3] = _local_2;
         _local_4 = new TextureDataConcrete(_local_2);
         _local_5 = String(_local_2.@id);

         // Custom ground tiles: use Color tag to generate solid-color 8x8 texture
         if (_local_5.indexOf("custom_") == 0 && _local_2.hasOwnProperty("Color"))
         {
            _local_4.texture_ = new BitmapData(8, 8, false, uint(_local_2.Color));
         }

         typeToTextureData_[_local_3] = _local_4;
         idToType_[_local_5] = _local_3;
      }
      defaultProps_ = propsLibrary_[0xFF];
   }

   public static function getIdFromType(_arg_1:int):String
   {
      var _local_2:GroundProperties = propsLibrary_[_arg_1];
      if (_local_2 == null)
      {
         return (null);
      }
      return (_local_2.id_);
   }

   public static function getPropsFromId(_arg_1:String):GroundProperties
   {
      return (propsLibrary_[idToType_[_arg_1]]);
   }

   public static function getBitmapData(_arg_1:int, _arg_2:int=0):BitmapData
   {
      return (typeToTextureData_[_arg_1].getTexture(_arg_2));
   }

   public static function getColor(_arg_1:int):uint
   {
      var _local_2:XML;
      var _local_3:uint;
      var _local_4:BitmapData;
      if (!tileTypeColorDict_.hasOwnProperty(_arg_1))
      {
         _local_2 = xmlLibrary_[_arg_1];
         if (_local_2.hasOwnProperty("Color"))
         {
            _local_3 = uint(_local_2.Color);
         }
         else
         {
            _local_4 = getBitmapData(_arg_1);
            _local_3 = BitmapUtil.mostCommonColor(_local_4);
         }
         tileTypeColorDict_[_arg_1] = _local_3;
      }
      return (tileTypeColorDict_[_arg_1]);
   }


}
}//package com.company.assembleegameclient.map

