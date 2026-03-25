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
   private static var _sharedHoleProps:GroundProperties = null;
   private static var _sharedHoleXml:XML = null;
   private static var _sharedNoWalkHoleProps:GroundProperties = null;
   private static var _sharedNoWalkHoleXml:XML = null;


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
    * Format: int32 count + (uint16 typeCode + byte[192] RGB pixels + byte flags + sbyte blendPriority + float speed) per entry
    * Flags: bit 0 = NoWalk, bit 1 = Hole
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
         _sharedHoleXml = <Ground type="0x8002" id="custom_hole"><Texture><File>lofiEnvironment2</File><Index>0x0b</Index></Texture><Hole/></Ground>;
         _sharedHoleProps = new GroundProperties(_sharedHoleXml);
         _sharedNoWalkHoleXml = <Ground type="0x8003" id="custom_nowalk_hole"><Texture><File>lofiEnvironment2</File><Index>0x0b</Index></Texture><NoWalk/><Hole/></Ground>;
         _sharedNoWalkHoleProps = new GroundProperties(_sharedNoWalkHoleXml);
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

         // Read flags byte: bit 0 = NoWalk, bit 1 = Hole
         var flags:uint = data.readUnsignedByte();
         var noWalk:Boolean = (flags & 1) != 0;
         var hole:Boolean = (flags & 2) != 0;

         // Read blend priority: sbyte (-1 = default/lowest, higher wins at edges)
         var blendPriority:int = data.readByte();

         // Read speed multiplier: float (1.0 = normal)
         var speed:Number = data.readFloat();

         // Read advanced properties
         var minDamage:int = data.readShort();
         var maxDamage:int = data.readShort();
         var sink:Boolean = data.readBoolean();
         var animType:uint = data.readUnsignedByte(); // 0=none, 1=Wave, 2=Flow
         var animDx:Number = data.readFloat();
         var animDy:Number = data.readFloat();
         var push:Boolean = data.readBoolean();
         var slideAmount:Number = data.readFloat();

         // Dispose old texture if exists
         var oldTd:TextureDataConcrete = typeToTextureData_[typeCode];
         if (oldTd != null && oldTd.texture_ != null)
            oldTd.texture_.dispose();

         // Create TextureDataConcrete with shared XML, override texture with our BitmapData
         var td:TextureDataConcrete = new TextureDataConcrete(_sharedCustomXml);
         td.texture_ = bmd;

         // Check if any non-default properties are set
         var hasAdvanced:Boolean = blendPriority != -1 || speed != 1.0 ||
            minDamage > 0 || maxDamage > 0 || sink || animType != 0 || push || slideAmount != 0;

         if (animType != 0)
            trace("[CustomGrounds] Tile 0x" + typeCode.toString(16) + " animType=" + animType + " dx=" + animDx + " dy=" + animDy);

         // If any special properties set, build per-tile props with all flags combined
         if (hasAdvanced)
         {
            var tileXml:XML = <Ground type={"0x" + typeCode.toString(16)} id={"custom_" + typeCode.toString(16)}>
               <Texture><File>lofiEnvironment2</File><Index>0x0b</Index></Texture>
            </Ground>;
            if (blendPriority != -1) tileXml.appendChild(<BlendPriority>{blendPriority}</BlendPriority>);
            if (speed != 1.0) tileXml.appendChild(<Speed>{speed}</Speed>);
            if (noWalk) tileXml.appendChild(<NoWalk/>);
            if (hole) tileXml.appendChild(<Hole/>);
            if (minDamage > 0) tileXml.appendChild(<MinDamage>{minDamage}</MinDamage>);
            if (maxDamage > 0) tileXml.appendChild(<MaxDamage>{maxDamage}</MaxDamage>);
            if (sink) tileXml.appendChild(<Sink/>);
            if (animType == 1) tileXml.appendChild(<Animate dx={animDx} dy={animDy}>Wave</Animate>);
            else if (animType == 2) tileXml.appendChild(<Animate dx={animDx} dy={animDy}>Flow</Animate>);
            if (push) tileXml.appendChild(<Push/>);
            if (slideAmount != 0) tileXml.appendChild(<SlideAmount>{slideAmount}</SlideAmount>);
            propsLibrary_[typeCode] = new GroundProperties(tileXml);
         }
         else if (noWalk && hole) propsLibrary_[typeCode] = _sharedNoWalkHoleProps;
         else if (hole) propsLibrary_[typeCode] = _sharedHoleProps;
         else if (noWalk) propsLibrary_[typeCode] = _sharedNoWalkProps;
         else propsLibrary_[typeCode] = _sharedCustomProps;
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
