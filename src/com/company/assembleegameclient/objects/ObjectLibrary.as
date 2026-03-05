// Decompiled by AS3 Sorcerer 6.08
// www.as3sorcerer.com

//com.company.assembleegameclient.objects.ObjectLibrary

package com.company.assembleegameclient.objects
{

import com.company.assembleegameclient.ui.tooltip.TooltipHelper;

import flash.utils.Dictionary;
import flash.utils.ByteArray;
import com.company.assembleegameclient.objects.animation.AnimationsData;
import kabam.rotmg.assets.EmbeddedData;
import flash.utils.getDefinitionByName;
import flash.display.BitmapData;
import com.company.util.AssetLibrary;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.assembleegameclient.util.redrawers.GlowRedrawer;
import kabam.rotmg.constants.ItemConstants;
import kabam.rotmg.constants.GeneralConstants;
import com.company.util.ConversionUtil;
import kabam.rotmg.messaging.impl.data.StatData;


public class ObjectLibrary
{

    public static var textureDataFactory:TextureDataFactory = new TextureDataFactory();
    public static const IMAGE_SET_NAME:String = "lofiObj3";
    public static const IMAGE_ID:int = 0xFF;
    public static var playerChars_:Vector.<XML> = new Vector.<XML>();
    public static var hexTransforms_:Vector.<XML> = new Vector.<XML>();
    public static var playerClassAbbr_:Dictionary = new Dictionary();
    public static const propsLibrary_:Dictionary = new Dictionary();
    public static const xmlLibrary_:Dictionary = new Dictionary();
    public static const xmlPatchLibrary_:Dictionary = new Dictionary();
    public static const setLibrary_:Dictionary = new Dictionary();
    public static const idToType_:Dictionary = new Dictionary();
    public static const typeToDisplayId_:Dictionary = new Dictionary();
    public static const typeToTextureData_:Dictionary = new Dictionary();
    public static const typeToTopTextureData_:Dictionary = new Dictionary();
    public static const typeToAnimationsData_:Dictionary = new Dictionary();
    public static const petXMLDataLibrary_:Dictionary = new Dictionary();
    public static const skinSetXMLDataLibrary_:Dictionary = new Dictionary();
    public static const dungeonToPortalTextureData_:Dictionary = new Dictionary();
    public static const petSkinIdToPetType_:Dictionary = new Dictionary();
    public static const dungeonsXMLLibrary_:Dictionary = new Dictionary(true);
    public static const ENEMY_FILTER_LIST:Vector.<String> = new <String>["None", "Hp", "Defense"];
    public static const TILE_FILTER_LIST:Vector.<String> = new <String>["ALL", "Walkable", "Unwalkable", "Slow", "Speed=1"];
    public static const defaultProps_:ObjectProperties = new ObjectProperties(null);
    public static var usePatchedData:Boolean = false;

    public static const idToTypeItems_:Dictionary = new Dictionary();
    public static const typeToIdItems_:Dictionary = new Dictionary();

    public static const TYPE_MAP:Object = {
        "CaveWall":CaveWall,
        "Character":Character,
        "CharacterChanger":CharacterChanger,
        "ClosedGiftChest":ClosedGiftChest,
        "ClosedVaultChest":ClosedVaultChest,
        "ConnectedWall":ConnectedWall,
        "Container":Container,
        "DoubleWall":DoubleWall,
        "GameObject":GameObject,
        "GuildBoard":GuildBoard,
        "GuildChronicle":GuildChronicle,
        "GuildHallPortal":GuildHallPortal,
        "GuildMerchant":GuildMerchant,
        "GuildRegister":GuildRegister,
        "Merchant":Merchant,
        "MoneyChanger":MoneyChanger,
        "NameChanger":NameChanger,
        "ReskinVendor":ReskinVendor,
        "OneWayContainer":OneWayContainer,
        "Player":Player,
        "Portal":Portal,
        "Projectile":Projectile,
        "Sign":Sign,
        "SpiderWeb":SpiderWeb,
        "Stalagmite":Stalagmite,
        "Wall":Wall,
        "PotionStorage":PotionStorage,
        "MarketNPC":MarketNPC,
        "DungeonBrowserNPC":DungeonBrowserNPC
    }
    private static var currentDungeon:String = "";


    public static function parseDungeonXML(_arg_1:String, _arg_2:XML):void
    {
        var _local_3:int = (_arg_1.indexOf("_") + 1);
        var _local_4:int = _arg_1.indexOf("CXML");
        if (((_arg_1.indexOf("_ObjectsCXML") == -1) && (_arg_1.indexOf("_StaticObjectsCXML") == -1)))
        {
            if (_arg_1.indexOf("Objects") != -1)
            {
                _local_4 = _arg_1.indexOf("ObjectsCXML");
            }
            else
            {
                if (_arg_1.indexOf("Object") != -1)
                {
                    _local_4 = _arg_1.indexOf("ObjectCXML");
                }
            }
        }
        currentDungeon = _arg_1.substr(_local_3, (_local_4 - _local_3));
        dungeonsXMLLibrary_[currentDungeon] = new Dictionary(true);
        parseFromXML(_arg_2, parseDungeonCallbak);
    }

    private static function parseDungeonCallbak(_arg_1:int, _arg_2:XML):void
    {
        if (((!(currentDungeon == "")) && (!(dungeonsXMLLibrary_[currentDungeon] == null))))
        {
            dungeonsXMLLibrary_[currentDungeon][_arg_1] = _arg_2;
            propsLibrary_[_arg_1].belonedDungeon = currentDungeon;
        }
    }

    public static function parsePatchXML(_arg_1:XML, _arg_2:Function=null):void
    {
        var _local_3:XML;
        var _local_4:String;
        var _local_5:String;
        var _local_6:int;
        var _local_7:ObjectProperties;
        for each (_local_3 in _arg_1.Object)
        {
            _local_4 = String(_local_3.@id);
            _local_5 = _local_4;
            if (_local_3.hasOwnProperty("DisplayId"))
            {
                _local_5 = _local_3.DisplayId;
            }
            _local_6 = int(_local_3.@type);
            _local_7 = propsLibrary_[_local_6];
            if (_local_7 != null)
            {
                xmlPatchLibrary_[_local_6] = _local_3;
            }
        }
    }

    public static function parseFromXML(_arg_1:XML, _arg_2:Function=null):void
    {
        var _local_3:XML;
        var _local_4:String;
        var _local_5:String;
        var _local_6:int;
        var _local_7:Boolean;
        var _local_8:int;
        for each (_local_3 in _arg_1.Object)
        {
            try
            {
            _local_4 = String(_local_3.@id);
            _local_5 = _local_4;
            if (_local_3.hasOwnProperty("DisplayId"))
            {
                _local_5 = _local_3.DisplayId;
            }
            if (_local_3.hasOwnProperty("Group"))
            {
                if (_local_3.Group == "Hexable")
                {
                    hexTransforms_.push(_local_3);
                }
            }
            _local_6 = int(_local_3.@type);
            if (((_local_3.hasOwnProperty("PetBehavior")) || (_local_3.hasOwnProperty("PetAbility"))))
            {
                petXMLDataLibrary_[_local_6] = _local_3;
            }
            else
            {
                propsLibrary_[_local_6] = new ObjectProperties(_local_3);
                xmlLibrary_[_local_6] = _local_3;
                idToType_[_local_4] = _local_6;
                typeToDisplayId_[_local_6] = _local_5;

                if (String(_local_3.Class) == "Equipment") {
                    typeToIdItems_[_local_6] = _local_4.toLowerCase(); /* Saves us the power to do this later */
                    idToTypeItems_[_local_4.toLowerCase()] = _local_6;
                }

                if (_arg_2 != null)
                {
                    (_arg_2(_local_6, _local_3));
                }
                if (String(_local_3.Class) == "Player")
                {
                    playerClassAbbr_[_local_6] = String(_local_3.@id).substr(0, 2);
                    _local_7 = false;
                    _local_8 = 0;
                    while (_local_8 < playerChars_.length)
                    {
                        if (int(playerChars_[_local_8].@type) == _local_6)
                        {
                            playerChars_[_local_8] = _local_3;
                            _local_7 = true;
                        }
                        _local_8++;
                    }
                    if (!_local_7)
                    {
                        playerChars_.push(_local_3);
                    }
                }
                typeToTextureData_[_local_6] = textureDataFactory.create(_local_3);
                if (_local_3.hasOwnProperty("Top"))
                {
                    typeToTopTextureData_[_local_6] = textureDataFactory.create(XML(_local_3.Top));
                }
                if (_local_3.hasOwnProperty("Animation"))
                {
                    typeToAnimationsData_[_local_6] = new AnimationsData(_local_3);
                }
                if (((_local_3.hasOwnProperty("IntergamePortal")) && (_local_3.hasOwnProperty("DungeonName"))))
                {
                    dungeonToPortalTextureData_[String(_local_3.DungeonName)] = typeToTextureData_[_local_6];
                }
                if (((String(_local_3.Class) == "Pet") && (_local_3.hasOwnProperty("DefaultSkin"))))
                {
                    petSkinIdToPetType_[String(_local_3.DefaultSkin)] = _local_6;
                }
            }
            }
            catch (parseErr:Error)
            {
                trace("[ObjectLibrary] Failed to parse object '" + String(_local_3.@id) + "' type=0x" + int(_local_3.@type).toString(16) + ": " + parseErr.message);
            }
        }
    }

    public static function getIdFromType(_arg_1:int):String
    {
        var _local_2:XML = xmlLibrary_[_arg_1];
        if (_local_2 == null)
        {
            return (null);
        }
        return (String(_local_2.@id));
    }

    public static function getSetXMLFromType(_arg_1:int):XML
    {
        var _local_2:XML;
        var _local_3:int;
        if (setLibrary_[_arg_1] != undefined)
        {
            return (setLibrary_[_arg_1]);
        }
        for each (_local_2 in EmbeddedData.skinsEquipmentSetsXML.EquipmentSet)
        {
            _local_3 = int(_local_2.@type);
            setLibrary_[_local_3] = _local_2;
        }
        return (setLibrary_[_arg_1]);
    }

    public static function getPropsFromId(_arg_1:String):ObjectProperties
    {
        var _local_2:int = idToType_[_arg_1];
        return (propsLibrary_[_local_2]);
    }

    public static function getXMLfromId(_arg_1:String):XML
    {
        var _local_2:int = idToType_[_arg_1];
        return (xmlLibrary_[_local_2]);
    }

    public static function getObjectFromType(objectType:int):GameObject
    {
        var objectXML:XML;
        var typeReference:String;
        objectXML = xmlLibrary_[objectType];
        if (objectXML == null) {
            return null;
        }
        typeReference = objectXML.Class;
        var typeClass:Class = ((TYPE_MAP[typeReference]) || (makeClass(typeReference)));
        return (new (typeClass)(objectXML));
    }

    private static function makeClass(_arg_1:String):Class
    {
        var _local_2:String = ("com.company.assembleegameclient.objects." + _arg_1);
        return (getDefinitionByName(_local_2) as Class);
    }

    public static function getTextureFromType(_arg_1:int):BitmapData
    {
        var _local_2:TextureData = typeToTextureData_[_arg_1];
        if (_local_2 == null)
        {
            return (null);
        }
        return (_local_2.getTexture());
    }

    public static function getBitmapData(_arg_1:int):BitmapData
    {
        var _local_2:TextureData = typeToTextureData_[_arg_1];
        var _local_3:BitmapData = ((_local_2) ? _local_2.getTexture() : null);
        if (_local_3)
        {
            return (_local_3);
        }
        return (AssetLibrary.getImageFromSet(IMAGE_SET_NAME, IMAGE_ID));
    }

    public static function getRedrawnTextureFromType(_arg_1:int, _arg_2:int, _arg_3:Boolean, _arg_4:Boolean=true, _arg_5:Number=5):BitmapData
    {
        var _local_6:BitmapData = getBitmapData(_arg_1);
        if (((!(Parameters.itemTypes16.indexOf(_arg_1) == -1)) || (_local_6.height == 16)))
        {
            _arg_2 = (_arg_2 * 0.5);
        }
        var _local_7:TextureData = typeToTextureData_[_arg_1];
        var _local_8:BitmapData = ((_local_7) ? _local_7.mask_ : null);
        if (_local_8 == null)
        {
            return (TextureRedrawer.redraw(_local_6, _arg_2, _arg_3, 0, _arg_4, _arg_5));
        }
        var _local_9:XML = xmlLibrary_[_arg_1];
        var _local_10:int = ((_local_9.hasOwnProperty("Tex1")) ? int(_local_9.Tex1) : 0);
        var _local_11:int = ((_local_9.hasOwnProperty("Tex2")) ? int(_local_9.Tex2) : 0);
        _local_6 = TextureRedrawer.resize(_local_6, _local_8, _arg_2, _arg_3, _local_10, _local_11, _arg_5);
        _local_6 = GlowRedrawer.outlineGlow(_local_6, 0);
        return (_local_6);
    }

    public static function isRare(_arg_1:int):Boolean {
        var _local_2:XML = xmlLibrary_[_arg_1];
        return (((!((_local_2 == null))) && (_local_2.hasOwnProperty("Rare"))));
    }

    public static function isLegendary(_arg_1:int):Boolean {
        var _local_2:XML = xmlLibrary_[_arg_1];
        return (((!((_local_2 == null))) && (_local_2.hasOwnProperty("Legendary"))));
    }

    public static function getSizeFromType(_arg_1:int):int
    {
        var _local_2:XML = xmlLibrary_[_arg_1];
        if (!_local_2.hasOwnProperty("Size"))
        {
            return (100);
        }
        return (int(_local_2.Size));
    }

    public static function getSlotTypeFromType(_arg_1:int):int
    {
        var _local_2:XML = xmlLibrary_[_arg_1];
        if (!_local_2.hasOwnProperty("SlotType"))
        {
            return (-1);
        }
        return (int(_local_2.SlotType));
    }

    //editor8182381 — Classless: equippable if item has a valid category slot
    public static function isEquippableByPlayer(_arg_1:int, _arg_2:Player):Boolean
    {
        if (_arg_1 == ItemConstants.NO_ITEM)
        {
            return (false);
        }
        var _local_3:XML = xmlLibrary_[_arg_1];
        var _local_4:int = int(_local_3.SlotType.toString());
        return getCommunityDungeonSlot(_local_4) >= 0;
    }

    //editor8182381 — Classless: always map item type to category slot
    public static function getMatchingSlotIndex(_arg_1:int, _arg_2:Player):int
    {
        var _local_3:XML;
        var _local_4:int;
        if (_arg_1 != ItemConstants.NO_ITEM)
        {
            _local_3 = xmlLibrary_[_arg_1];
            _local_4 = int(_local_3.SlotType);
            return getCommunityDungeonSlot(_local_4);
        }
        return (-1);
    }

    public static function getCommunityDungeonSlot(slotType:int):int
    {
        switch(slotType)
        {
            // Weapons -> slot 0
            case ItemConstants.SWORD_TYPE:
            case ItemConstants.DAGGER_TYPE:
            case ItemConstants.BOW_TYPE:
            case ItemConstants.WAND_TYPE:
            case ItemConstants.STAFF_TYPE:
            case ItemConstants.KATANA_TYPE:
                return 0;
            // Abilities -> slot 1
            case ItemConstants.TOME_TYPE:
            case ItemConstants.SHIELD_TYPE:
            case ItemConstants.SPELL_TYPE:
            case ItemConstants.SEAL_TYPE:
            case ItemConstants.CLOAK_TYPE:
            case ItemConstants.QUIVER_TYPE:
            case ItemConstants.HELM_TYPE:
            case ItemConstants.POISON_TYPE:
            case ItemConstants.SKULL_TYPE:
            case ItemConstants.TRAP_TYPE:
            case ItemConstants.ORB_TYPE:
            case ItemConstants.PRISM_TYPE:
            case ItemConstants.SCEPTER_TYPE:
            case ItemConstants.SHURIKEN_TYPE:
            case ItemConstants.NEW_ABIL_TYPE:
            case ItemConstants.LUTE_TYPE:
                return 1;
            // Armor -> slot 2
            case ItemConstants.LEATHER_TYPE:
            case ItemConstants.PLATE_TYPE:
            case ItemConstants.ROBE_TYPE:
                return 2;
            // Ring -> slot 3
            case ItemConstants.RING_TYPE:
                return 3;
            default:
                return -1;
        }
    }

    //editor8182381 — Classless: all equipment with valid category is usable
    public static function isUsableByPlayer(_arg_1:int, _arg_2:Player):Boolean
    {
        if (((_arg_2 == null) || (_arg_2.slotTypes_ == null)))
        {
            return (true);
        }
        var _local_3:XML = xmlLibrary_[_arg_1];
        if (((_local_3 == null) || (!(_local_3.hasOwnProperty("SlotType")))))
        {
            return (false);
        }
        var _local_4:int = _local_3.SlotType;
        if (((_local_4 == ItemConstants.POTION_TYPE)))
        {
            return (true);
        }
        return getCommunityDungeonSlot(_local_4) >= 0;
    }

    public static function isSoulbound(_arg_1:int):Boolean
    {
        var _local_2:XML = xmlLibrary_[_arg_1];
        return ((!(_local_2 == null)) && (_local_2.hasOwnProperty("Soulbound")));
    }

    public static function isDropTradable(_arg_1:int):Boolean
    {
        var _local_2:XML = xmlLibrary_[_arg_1];
        return ((!(_local_2 == null)) && (_local_2.hasOwnProperty("DropTradable")));
    }

    public static function usableBy(_arg_1:int):Vector.<String>
    {
        var _local_5:XML;
        var _local_6:Vector.<int>;
        var _local_7:int;
        var _local_2:XML = xmlLibrary_[_arg_1];
        if (((_local_2 == null) || (!(_local_2.hasOwnProperty("SlotType")))))
        {
            return (null);
        }
        var _local_3:int = _local_2.SlotType;
        if ((((_local_3 == ItemConstants.POTION_TYPE) || (_local_3 == ItemConstants.RING_TYPE))))
        {
            return (null);
        }
        var _local_4:Vector.<String> = new Vector.<String>();
        for each (_local_5 in playerChars_)
        {
            _local_6 = ConversionUtil.toIntVector(_local_5.SlotTypes);
            _local_7 = 0;
            while (_local_7 < _local_6.length)
            {
                if (_local_6[_local_7] == _local_3)
                {
                    _local_4.push(typeToDisplayId_[int(_local_5.@type)]);
                    break;
                }
                _local_7++;
            }
        }
        return (_local_4);
    }

    public static function playerMeetsRequirements(_arg_1:int, _arg_2:Player):Boolean
    {
        var _local_4:XML;
        if (_arg_2 == null)
        {
            return (true);
        }
        var _local_3:XML = xmlLibrary_[_arg_1];
        for each (_local_4 in _local_3.EquipRequirement)
        {
            if (!playerMeetsRequirement(_local_4, _arg_2))
            {
                return (false);
            }
        }
        return (true);
    }

    public static function playerMeetsRequirement(_arg_1:XML, _arg_2:Player):Boolean
    {
        var _local_3:int;
        if (_arg_1.toString() == "Stat")
        {
            _local_3 = int(_arg_1.@value);
            switch (int(_arg_1.@stat))
            {
                case StatData.MAX_HP_STAT:
                    return (_arg_2.maxHP_ >= _local_3);
                case StatData.MAX_MP_STAT:
                    return (_arg_2.maxMP_ >= _local_3);
                case StatData.LEVEL_STAT:
                    return (_arg_2.level_ >= _local_3);
                case StatData.ATTACK_STAT:
                    return (_arg_2.attack_ >= _local_3);
                case StatData.DEFENSE_STAT:
                    return (_arg_2.defense_ >= _local_3);
                case StatData.SPEED_STAT:
                    return (_arg_2.speed_ >= _local_3);
                case StatData.VITALITY_STAT:
                    return (_arg_2.vitality_ >= _local_3);
                case StatData.WISDOM_STAT:
                    return (_arg_2.wisdom_ >= _local_3);
                case StatData.DEXTERITY_STAT:
                    return (_arg_2.dexterity_ >= _local_3);
            }
        }
        return (false);
    }

    public static function getPetDataXMLByType(_arg_1:int):XML
    {
        return (petXMLDataLibrary_[_arg_1]);
    }

    /**
     * Load custom objects from binary data (sent per-dungeon, like custom grounds).
     * Format: int32 count + (uint16 typeCode + byte[192] RGB pixels + byte classFlag) per entry
     * classFlag: 0=Wall, 1=DestructibleWall, 2=Decoration
     */
    public static function loadBinaryCustomObjects(data:ByteArray):int
    {
        var count:int = data.readInt();

        for (var i:int = 0; i < count; i++)
        {
            var typeCode:int = data.readUnsignedShort();
            var spriteSize:int = data.readUnsignedByte(); // 0=blocker, 8, 16, or 32

            // Read pixel data based on sprite size
            var bmd:BitmapData = null;
            if (spriteSize > 0)
            {
                var totalPixels:int = spriteSize * spriteSize;
                bmd = new BitmapData(spriteSize, spriteSize, true, 0x00000000);
                var pixelVec:Vector.<uint> = new Vector.<uint>(totalPixels);
                for (var pi:int = 0; pi < totalPixels; pi++)
                {
                    var r:uint = data.readUnsignedByte();
                    var g:uint = data.readUnsignedByte();
                    var b:uint = data.readUnsignedByte();
                    // Near-black (0x2a2a2a) = placeholder for transparent pixels
                    if (r <= 0x2a && g <= 0x2a && b <= 0x2a)
                    {
                        pixelVec[pi] = 0x00000000;
                    }
                    else
                    {
                        pixelVec[pi] = 0xFF000000 | (r << 16) | (g << 8) | b;
                    }
                }
                bmd.setVector(bmd.rect, pixelVec);
            }

            // 0=Object(2D solid), 1=Destructible(3D), 2=Decoration(2D), 3=Wall(3D), 4=Blocker(invisible)
            var classFlag:int = data.readUnsignedByte();

            var objId:String = "cobj_" + typeCode.toString(16);
            var objXml:XML = <Object/>;
            objXml.@type = "0x" + typeCode.toString(16);
            objXml.@id = objId;
            objXml.appendChild(<Static/>);

            if (classFlag == 4) // Blocker — invisible, blocks movement (multi-tile padding)
            {
                objXml.appendChild(<Class>GameObject</Class>);
                objXml.appendChild(<OccupySquare/>);
                objXml.appendChild(<EnemyOccupySquare/>);
                // No texture — create a 1x1 transparent BitmapData
                bmd = new BitmapData(1, 1, true, 0x00000000);
            }
            else if (classFlag == 3) // Wall — 3D solid cube
            {
                objXml.appendChild(<Class>Wall</Class>);
                objXml.appendChild(<FullOccupy/>);
                objXml.appendChild(<BlocksSight/>);
                objXml.appendChild(<OccupySquare/>);
                objXml.appendChild(<EnemyOccupySquare/>);
                if (spriteSize > 8)
                {
                    objXml.appendChild(XML("<WallSize>" + int(spriteSize / 8) + "</WallSize>"));
                }
            }
            else if (classFlag == 1) // Destructible — 3D breakable cube
            {
                objXml.appendChild(<Class>Wall</Class>);
                objXml.appendChild(<FullOccupy/>);
                objXml.appendChild(<BlocksSight/>);
                objXml.appendChild(<OccupySquare/>);
                objXml.appendChild(<EnemyOccupySquare/>);
                objXml.appendChild(<Enemy/>);
                objXml.appendChild(<MaxHitPoints>100</MaxHitPoints>);
                if (spriteSize > 8)
                {
                    objXml.appendChild(XML("<WallSize>" + int(spriteSize / 8) + "</WallSize>"));
                }
            }
            else if (classFlag == 2) // Decoration — 2D flat, walk-through
            {
                objXml.appendChild(<Class>GameObject</Class>);
            }
            else // 0 = Object — 2D flat, solid (blocks movement)
            {
                objXml.appendChild(<Class>GameObject</Class>);
                objXml.appendChild(<OccupySquare/>);
                objXml.appendChild(<EnemyOccupySquare/>);
            }

            // Register in ObjectLibrary
            propsLibrary_[typeCode] = new ObjectProperties(objXml);
            xmlLibrary_[typeCode] = objXml;
            idToType_[objId] = typeCode;
            typeToDisplayId_[typeCode] = objId;

            // Create texture
            var dummyXml:XML = <Object type={"0x" + typeCode.toString(16)} id={objId}>
                <Texture><File>lofiObj3</File><Index>0xff</Index></Texture>
            </Object>;
            var td:TextureDataConcrete = new TextureDataConcrete(dummyXml);
            td.texture_ = bmd;
            typeToTextureData_[typeCode] = td;
            typeToTopTextureData_[typeCode] = td;
        }

        return count;
    }

    /**
     * Clean up custom object entries (type codes 0x9000+) to prevent cross-dungeon memory leak.
     * Call on map change before new custom objects arrive.
     */
    public static function cleanupCustomObjects():void
    {
        for (var key:* in typeToTextureData_)
        {
            var tc:int = int(key);
            if (tc >= 0x9000)
            {
                var td:TextureDataConcrete = typeToTextureData_[tc];
                if (td != null && td.texture_ != null)
                    td.texture_.dispose();
                delete typeToTextureData_[tc];
                delete typeToTopTextureData_[tc];
                delete propsLibrary_[tc];
                delete xmlLibrary_[tc];
                delete idToType_["cobj_" + tc.toString(16)];
                delete typeToDisplayId_[tc];
            }
        }
    }


}
}//package com.company.assembleegameclient.objects

