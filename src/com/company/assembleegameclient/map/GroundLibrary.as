// Decompiled by AS3 Sorcerer 6.08
// www.as3sorcerer.com

//com.company.assembleegameclient.map.GroundLibrary

package com.company.assembleegameclient.map
{
import flash.utils.Dictionary;
import flash.utils.ByteArray;
import com.company.assembleegameclient.objects.TextureDataConcrete;
import com.hurlant.util.Base64;
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

   // Shared objects for binary custom grounds (created once, reused for all entries)
   private static var _sharedCustomProps:GroundProperties = null;
   private static var _sharedCustomXml:XML = null;
   private static var _sharedNoWalkProps:GroundProperties = null;
   private static var _sharedNoWalkXml:XML = null;


   public static function parseFromXML(_arg_1:XML):void
   {
      var _local_2:XML;
      var _local_3:int;
      var _local_4:TextureDataConcrete;
      var _local_5:String;
      for each (_local_2 in _arg_1.Ground)
      {
         _local_3 = int(_local_2.@type);

         // Dispose old BitmapData for custom grounds to prevent memory leaks
         var oldTd:TextureDataConcrete = typeToTextureData_[_local_3];
         if (oldTd != null && oldTd.texture_ != null)
            oldTd.texture_.dispose();

         propsLibrary_[_local_3] = new GroundProperties(_local_2);
         xmlLibrary_[_local_3] = _local_2;
         _local_4 = new TextureDataConcrete(_local_2);
         _local_5 = String(_local_2.@id);

         // Custom ground tiles: decode per-pixel data or fall back to solid color
         if (_local_5.indexOf("custom_") == 0)
         {
            if (_local_2.hasOwnProperty("GroundPixels"))
            {
               _local_4.texture_ = decodeGroundPixels(String(_local_2.GroundPixels));
            }
            else if (_local_2.hasOwnProperty("Color"))
            {
               _local_4.texture_ = new BitmapData(8, 8, false, uint(_local_2.Color));
            }
         }

         // Clear cached minimap color so it regenerates
         delete tileTypeColorDict_[_local_3];

         typeToTextureData_[_local_3] = _local_4;
         idToType_[_local_5] = _local_3;
      }
      defaultProps_ = propsLibrary_[0xFF];
   }

   /**
    * Load custom grounds from binary data. Much faster than XML for large tile counts.
    * Format: int32 count + (uint16 typeCode + byte[192] RGB pixels + byte flags) per entry
    * Flags: bit 0 = NoWalk
    */
   public static function loadBinaryCustomGrounds(data:ByteArray):int
   {
      // Create shared props/xml once
      if (_sharedCustomXml == null)
      {
         _sharedCustomXml = <Ground type="0x8000" id="custom_shared"><Texture><File>lofiEnvironment2</File><Index>0x0b</Index></Texture></Ground>;
         _sharedCustomProps = new GroundProperties(_sharedCustomXml);
         _sharedNoWalkXml = <Ground type="0x8001" id="custom_nowalk"><Texture><File>lofiEnvironment2</File><Index>0x0b</Index></Texture><NoWalk/></Ground>;
         _sharedNoWalkProps = new GroundProperties(_sharedNoWalkXml);
      }

      var count:int = data.readInt();

      for (var i:int = 0; i < count; i++)
      {
         var typeCode:int = data.readUnsignedShort();

         // Read 192 raw RGB bytes into 8x8 BitmapData using setVector (batch, faster than setPixel)
         var bmd:BitmapData = new BitmapData(8, 8, false, 0);
         var pixelVec:Vector.<uint> = new Vector.<uint>(64);
         for (var pi:int = 0; pi < 64; pi++)
         {
            var r:uint = data.readUnsignedByte();
            var g:uint = data.readUnsignedByte();
            var b:uint = data.readUnsignedByte();
            pixelVec[pi] = 0xFF000000 | (r << 16) | (g << 8) | b;
         }
         bmd.setVector(bmd.rect, pixelVec);

         // Read flags byte: bit 0 = NoWalk
         var flags:uint = data.readUnsignedByte();
         var noWalk:Boolean = (flags & 1) != 0;

         // Dispose old texture if exists
         var oldTd:TextureDataConcrete = typeToTextureData_[typeCode];
         if (oldTd != null && oldTd.texture_ != null)
            oldTd.texture_.dispose();

         // Create TextureDataConcrete with shared XML, override texture with our BitmapData
         var td:TextureDataConcrete = new TextureDataConcrete(_sharedCustomXml);
         td.texture_ = bmd;

         propsLibrary_[typeCode] = noWalk ? _sharedNoWalkProps : _sharedCustomProps;
         xmlLibrary_[typeCode] = null;
         typeToTextureData_[typeCode] = td;
         delete tileTypeColorDict_[typeCode];
      }

      return count;
   }

   /**
    * Clean up custom ground entries (type codes 0x8000+) to prevent cross-dungeon memory leak.
    * Call on map change before new custom grounds arrive.
    */
   public static function cleanupCustomGrounds():void
   {
      for (var key:* in typeToTextureData_)
      {
         var tc:int = int(key);
         if (tc >= 0x8000)
         {
            var td:TextureDataConcrete = typeToTextureData_[tc];
            if (td != null && td.texture_ != null)
               td.texture_.dispose();
            delete typeToTextureData_[tc];
            delete propsLibrary_[tc];
            delete xmlLibrary_[tc];
            delete tileTypeColorDict_[tc];
         }
      }
   }

   private static function decodeGroundPixels(b64:String):BitmapData
   {
      var bytes:ByteArray = Base64.decodeToByteArray(b64);
      var bmd:BitmapData = new BitmapData(8, 8, false, 0x000000);
      bmd.lock();
      var i:int = 0;
      for (var y:int = 0; y < 8; y++)
      {
         for (var x:int = 0; x < 8; x++)
         {
            if (i + 2 < bytes.length)
            {
               var r:uint = bytes[i++];
               var g:uint = bytes[i++];
               var b:uint = bytes[i++];
               bmd.setPixel(x, y, (r << 16) | (g << 8) | b);
            }
         }
      }
      bmd.unlock();
      return bmd;
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
      var td:TextureDataConcrete = typeToTextureData_[_arg_1];
      if (td == null)
      {
         return typeToTextureData_[0xFF] != null ? typeToTextureData_[0xFF].getTexture(_arg_2) : null;
      }
      return (td.getTexture(_arg_2));
   }

   public static function getColor(_arg_1:int):uint
   {
      var _local_2:XML;
      var _local_3:uint;
      var _local_4:BitmapData;
      if (!tileTypeColorDict_.hasOwnProperty(_arg_1))
      {
         _local_2 = xmlLibrary_[_arg_1];

         // Binary custom grounds have no XML - derive color from texture
         if (_local_2 == null)
         {
            _local_4 = getBitmapData(_arg_1);
            _local_3 = _local_4 != null ? BitmapUtil.mostCommonColor(_local_4) : 0x000000;
         }
         else
         {
            var _local_5:String = String(_local_2.@id);
            // Custom grounds with GroundPixels: derive color from decoded texture
            if (_local_5.indexOf("custom_") == 0 && _local_2.hasOwnProperty("GroundPixels"))
            {
               _local_4 = getBitmapData(_arg_1);
               _local_3 = _local_4 != null ? BitmapUtil.mostCommonColor(_local_4) : uint(_local_2.Color);
            }
            else if (_local_2.hasOwnProperty("Color"))
            {
               _local_3 = uint(_local_2.Color);
            }
            else
            {
               _local_4 = getBitmapData(_arg_1);
               _local_3 = BitmapUtil.mostCommonColor(_local_4);
            }
         }
         tileTypeColorDict_[_arg_1] = _local_3;
      }
      return (tileTypeColorDict_[_arg_1]);
   }


}
}//package com.company.assembleegameclient.map
