package com.company.assembleegameclient.objects {
import com.company.assembleegameclient.map.Camera;
import com.company.assembleegameclient.map.Square;
import com.company.assembleegameclient.screens.TitleIcons;
import com.company.assembleegameclient.map.mapoverlay.CharacterStatusText;
import com.company.assembleegameclient.objects.particles.HealingEffect;
import com.company.assembleegameclient.objects.particles.LevelUpEffect;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.sound.SoundEffectLibrary;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;
import com.company.assembleegameclient.tutorial.Tutorial;
import com.company.assembleegameclient.tutorial.doneAction;
import com.company.assembleegameclient.util.AnimatedChar;
import com.company.assembleegameclient.util.ConditionEffect;
import com.company.assembleegameclient.util.FameUtil;
import com.company.assembleegameclient.util.FreeList;
import com.company.assembleegameclient.util.MaskedImage;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.assembleegameclient.util.redrawers.GlowRedrawer;
import com.company.ui.SimpleText;
import com.company.util.CachingColorTransformer;
import com.company.util.ConversionUtil;
import com.company.util.GraphicsUtil;
import com.company.util.IntPoint;
import com.company.util.MoreColorUtil;
import com.company.util.PointUtil;
import com.company.util.Trig;

import flash.display.BitmapData;
import flash.display.GraphicsPath;
import flash.display.GraphicsPathCommand;
import flash.display.GraphicsSolidFill;
import flash.display.IGraphicsData;
import flash.display.Sprite;
import flash.filters.GlowFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.Dictionary;
import flash.utils.getTimer;

import kabam.rotmg.assets.services.CharacterFactory;
import kabam.rotmg.constants.ActivationType;
import kabam.rotmg.constants.GeneralConstants;
import kabam.rotmg.constants.UseType;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.game.model.AddTextLineVO;
import kabam.rotmg.game.model.PotionInventoryModel;
import kabam.rotmg.game.signals.AddTextLineSignal;
import kabam.rotmg.stage3D.GraphicsFillExtra;
import kabam.rotmg.storage.PotionStorageModal;
import kabam.rotmg.storage.PotionsView;
import kabam.rotmg.ui.model.TabStripModel;

import org.swiftsuspenders.Injector;

public class Player extends Character {

    public static const MS_BETWEEN_TELEPORT:int = 10000;
    private static const MOVE_THRESHOLD:Number = 0.4;
    private static const NEARBY:Vector.<Point> = new <Point>[new Point(0, 0), new Point(1, 0), new Point(0, 1), new Point(1, 1)];
    private static const RANK_OFFSET_MATRIX:Matrix = new Matrix(1, 0, 0, 1, 2, 4);
    private static const NAME_OFFSET_MATRIX:Matrix = new Matrix(1, 0, 0, 1, 20, 0);
    private static const MIN_MOVE_SPEED:Number = 0.004;
    private static const MAX_MOVE_SPEED:Number = 0.0096;
    private static const MIN_ATTACK_FREQ:Number = 0.0015;
    private static const MAX_ATTACK_FREQ:Number = 0.008;
    private static const MIN_ATTACK_MULT:Number = 0.5;
    private static const MAX_ATTACK_MULT:Number = 2;
    private static const LOW_HEALTH_CT_OFFSET:int = 128;
    private static var newP:Point = new Point();
    private static var lowHealthCT:Dictionary = new Dictionary();

    public static function fromPlayerXML(name:String, playerXML:XML):Player {
        var objectType:int = int(playerXML.ObjectType);
        var objXML:XML = ObjectLibrary.xmlLibrary_[objectType];
        var player:Player = new Player(objXML);
        player.name_ = name;
        player.level_ = int(playerXML.Level);
        player.exp_ = int(playerXML.Exp);
        player.equipment_ = ConversionUtil.toIntVector(playerXML.Equipment);
        var data:Vector.<Object> = ConversionUtil.ArrayToObject(playerXML.ItemDatas, ";");
        for(var i:int = 0; i < data.length; i++)
            player.equipData_[i] = JSON.parse(String(data[i]));
        player.maxHP_ = int(playerXML.MaxHitPoints);
        player.hp_ = int(playerXML.HitPoints);
        player.maxMP_ = int(playerXML.MaxMagicPoints);
        player.mp_ = int(playerXML.MagicPoints);
        player.attack_ = int(playerXML.Attack);
        player.defense_ = int(playerXML.Defense);
        player.speed_ = int(playerXML.Speed);
        player.dexterity_ = int(playerXML.Dexterity);
        player.vitality_ = int(playerXML.HpRegen);
        player.wisdom_ = int(playerXML.MpRegen);
        player.tex1Id_ = int(playerXML.Tex1);
        player.tex2Id_ = int(playerXML.Tex2);
        player.hasBackpack_ = Boolean(playerXML.HasBackpack == 1);
        return player;
    }

    public function Player(objectXML:XML) {
        this.ip_ = new IntPoint();
        var injector:Injector = StaticInjectorContext.getInjector();
        this.addTextLine = injector.getInstance(AddTextLineSignal);
        this.factory = injector.getInstance(CharacterFactory);
        super(objectXML);
        this.attackMax_ = int(objectXML.Attack.@max);
        this.defenseMax_ = int(objectXML.Defense.@max);
        this.speedMax_ = int(objectXML.Speed.@max);
        this.dexterityMax_ = int(objectXML.Dexterity.@max);
        this.vitalityMax_ = int(objectXML.HpRegen.@max);
        this.wisdomMax_ = int(objectXML.MpRegen.@max);
        this.maxHPMax_ = int(objectXML.MaxHitPoints.@max);
        this.maxMPMax_ = int(objectXML.MaxMagicPoints.@max);
        texturingCache_ = new Dictionary();
    }


    private var famePortrait_:BitmapData = null;
    public var skinId:int;
    public var skin:AnimatedChar;
    public var accountId_:int = -1;
    public var credits_:int = 0;
    public var numStars_:int = 0;
    public var fame_:int = 0;
    public var nameChosen_:Boolean = false;
    public var currFame_:int = 0;
    public var nextClassQuestFame_:int = -1;
    public var legendaryRank_:int = -1;
    public var guildName_:String = null;
    public var guildRank_:int = -1;
    public var isFellowGuild_:Boolean = false;
    public var isPartyMember_:Boolean = false;
    public var breath_:int = -1;
    public var maxMP_:int = 200;
    public var mp_:Number = 0;
    public var nextLevelExp_:int = 1000;
    public var exp_:int = 0;
    public var attack_:int = 0;
    public var speed_:int = 0;
    public var dexterity_:int = 0;
    public var vitality_:int = 0;
    public var wisdom_:int = 0;
    public var maxHPBoost_:int = 0;
    public var maxMPBoost_:int = 0;
    public var attackBoost_:int = 0;
    public var defenseBoost_:int = 0;
    public var speedBoost_:int = 0;
    public var vitalityBoost_:int = 0;
    public var wisdomBoost_:int = 0;
    public var dexterityBoost_:int = 0;
    public var healthPotionCount_:int = 0;
    public var magicPotionCount_:int = 0;
    public var attackMax_:int = 0;
    public var defenseMax_:int = 0;
    public var speedMax_:int = 0;
    public var dexterityMax_:int = 0;
    public var vitalityMax_:int = 0;
    public var wisdomMax_:int = 0;
    public var maxHPMax_:int = 0;
    public var maxMPMax_:int = 0;
    public var dropBoost:int = 0;
    public var xpTimer:int;
    public var rank:int;
    public var chatColor:int;
    public var nameChatColor:int;
    public var xpBoost_:int = 0;
    public var baseStat:int = 0;
    public var points:int = 0;
    public var hasBackpack_:Boolean = false;
    public var starred_:Boolean = false;
    public var ignored_:Boolean = false;
    public var upgraded_:Boolean = false;
    public var partyId_:int = 0;
    public var distSqFromThisPlayer_:Number = 0;
    public var attackPeriod_:int = 0;
    public var nextAltAttack_:int = 0;
    public var nextTeleportAt_:int = 0;
    public var isDefaultAnimatedChar:Boolean = true;
    //editor8182381 — Heartbeat sound when low HP (independent of SFX toggle)
    private var lastHeartbeatTime_:int = 0;
    private static var heartbeatSound_:Sound = null;
    private var heartbeatChannel_:SoundChannel = null;
    private var heartbeatGraceTime_:int = 0; //editor8182381 — grace period before stopping heartbeat
    protected var rotate_:Number = 0;
    protected var relMoveVec_:Point = null;
    protected var moveMultiplier_:Number = 1;
    protected var slideVelX_:Number = 0;
    protected var slideVelY_:Number = 0;
    protected var healingEffect_:HealingEffect = null;
    protected var nearestMerchant_:Merchant = null;
    private var addTextLine:AddTextLineSignal;
    private var factory:CharacterFactory;
    private var ip_:IntPoint;
    private var breathBackFill_:GraphicsSolidFill = null;
    private var breathBackPath_:GraphicsPath = null;
    private var breathFill_:GraphicsSolidFill = null;
    private var breathPath_:GraphicsPath = null;
    public var projectileSpeedMult_:Number = 1;
    public var ridingEntityId_:int = -1;
    public var ridingDesiredX_:Number = -1;
    public var ridingDesiredY_:Number = -1;
    public var lastRaftX_:Number = 0;
    public var lastRaftY_:Number = 0;
    public var raftInitialized_:Boolean = false;
    public var dashCooldownEnd_:int = 0;
    private static const DASH_COOLDOWN_MS:int = 5000;
    private static const DASH_CIRCLE_RADIUS:Number = 7;
    private static const DASH_CIRCLE_SEGMENTS:int = 32;
    private var dashArcFill_:GraphicsSolidFill = null;
    private var dashArcPath_:GraphicsPath = null;
    private var dashBgFill_:GraphicsSolidFill = null;
    private var dashBgPath_:GraphicsPath = null;

    override public function moveTo(x:Number, y:Number):Boolean {
        var ret:Boolean = super.moveTo(x, y);
        if (map_.gs_.isNexus_) {
            this.nearestMerchant_ = this.getNearbyMerchant();
        }
        return ret;
    }

    public function getFamePortrait(_arg_1:int):BitmapData
    {
        var _local_2:MaskedImage;
        var _local_3:int;
        if (this.famePortrait_ == null)
        {
            _local_2 = animatedChar_.imageFromDir(AnimatedChar.RIGHT, AnimatedChar.STAND, 0);
            _local_3 = int(((4 / _local_2.image_.width) * _arg_1));
            this.famePortrait_ = TextureRedrawer.resize(_local_2.image_, _local_2.mask_, _local_3, true, tex1Id_, tex2Id_);
            this.famePortrait_ = GlowRedrawer.outlineGlow(this.famePortrait_, 0);
        }
        return (this.famePortrait_);
    }

    public function getFameBonus():int
    {
        var _local_3:int;
        var _local_4:XML;
        var _local_1:int;
        var _local_2:uint;
        while (_local_2 < GeneralConstants.NUM_EQUIPMENT_SLOTS)
        {
            if (((equipment_) && (equipment_.length > _local_2)))
            {
                _local_3 = equipment_[_local_2];
                if (_local_3 != -1)
                {
                    _local_4 = ObjectLibrary.xmlLibrary_[_local_3];
                    if (((!(_local_4 == null)) && (_local_4.hasOwnProperty("FameBonus"))))
                    {
                        _local_1 = (_local_1 + int(_local_4.FameBonus));
                    }
                }
            }
            _local_2++;
        }
        return (_local_1);
    }

    override public function update(time:int, dt:int):Boolean {
        var playerAngle:Number = NaN;
        var moveSpeed:Number = NaN;
        var moveVecAngle:Number = NaN;
        var d:int = 0;

        if (this.dropBoost && !isPaused() && !map_.gs_.isNexus_ && !map_.gs_.isVault_) {

            this.dropBoost = this.dropBoost - dt;
            if (this.dropBoost < 0) {
                this.dropBoost = 0;
            }
        }
        if (this.xpTimer && !isPaused() && !map_.gs_.isNexus_ && !map_.gs_.isVault_) {
            this.xpTimer = this.xpTimer - dt;
            if (this.xpTimer < 0) {
                this.xpTimer = 0;
            }
        }

        if (isHealing() && !isPaused() && !(Parameters.data_.reduceParticles == 0)) {
            if (this.healingEffect_ == null) {
                this.healingEffect_ = new HealingEffect(this);
                map_.addObj(this.healingEffect_, x_, y_);
            }
        }
        else if (this.healingEffect_ != null) {
            map_.removeObj(this.healingEffect_.objectId_);
            this.healingEffect_ = null;
        }

        if (map_.player_ == this && isPaused()) {
            return true;
        }

        // Raft carry: add raft's interpolated delta to player position each frame
        if (this.ridingEntityId_ > 0 && map_ != null && map_.player_ == this) {
            var raftObj:GameObject = map_.goDict_[this.ridingEntityId_];
            if (raftObj != null && raftObj.props_.isRaft_) {
                var raftDx:Number = raftObj.x_ - this.lastRaftX_;
                var raftDy:Number = raftObj.y_ - this.lastRaftY_;
                this.lastRaftX_ = raftObj.x_;
                this.lastRaftY_ = raftObj.y_;
                if (this.raftInitialized_) {
                    x_ += raftDx;
                    y_ += raftDy;
                }
                this.raftInitialized_ = true;
            }
        }

        if (this.relMoveVec_ != null) {
            // Lock camera rotation while on raft (bounds are axis-aligned in world space)
            if (this.ridingEntityId_ > 0 && map_ != null) {
                var rotMount:GameObject = map_.goDict_[this.ridingEntityId_];
                if (rotMount != null && rotMount.props_.isRaft_) {
                    this.rotate_ = 0;
                    Parameters.data_.cameraAngle = 0;
                }
            }
            playerAngle = Parameters.data_.cameraAngle;
            if (this.rotate_ != 0) {
                playerAngle = playerAngle + dt * Parameters.PLAYER_ROTATE_SPEED * this.rotate_;
                Parameters.data_.cameraAngle = playerAngle;
            }
            if (this.relMoveVec_.x != 0 || this.relMoveVec_.y != 0) {
                moveSpeed = this.getMoveSpeed();
                moveVecAngle = Math.atan2(this.relMoveVec_.y, this.relMoveVec_.x);
                moveVec_.x = moveSpeed * Math.cos(playerAngle + moveVecAngle);
                moveVec_.y = moveSpeed * Math.sin(playerAngle + moveVecAngle);
            }
            else {
                moveVec_.x = 0;
                moveVec_.y = 0;
            }
            if (square_ != null && square_.props_.push_) {
                moveVec_.x = moveVec_.x - square_.props_.animate_.dx_ / 1000;
                moveVec_.y = moveVec_.y - square_.props_.animate_.dy_ / 1000;
            }
            // Slide (ice) physics: slideAmount_ 0-1, higher = more slippery
            var slideAmt:Number = (square_ != null) ? square_.props_.slideAmount_ : 0;
            if (slideAmt > 0) {
                // friction: how fast slide velocity decays (lower = more slippery)
                var friction:Number = 1 - slideAmt; // slideAmt=1 → friction=0 (pure ice)
                var dtSec:Number = dt / 1000;
                // Decay factor per frame: friction^dt, approximated as exp(-k*dt)
                var decay:Number = Math.pow(friction, dtSec * 10);
                if (this.relMoveVec_.x != 0 || this.relMoveVec_.y != 0) {
                    // Player has input: blend slide velocity toward desired velocity
                    this.slideVelX_ = this.slideVelX_ * decay + moveVec_.x * (1 - decay);
                    this.slideVelY_ = this.slideVelY_ * decay + moveVec_.y * (1 - decay);
                } else {
                    // No input: slide velocity decays toward zero
                    this.slideVelX_ = this.slideVelX_ * decay;
                    this.slideVelY_ = this.slideVelY_ * decay;
                    // Stop if very slow
                    if (Math.abs(this.slideVelX_) < 0.0001 && Math.abs(this.slideVelY_) < 0.0001) {
                        this.slideVelX_ = 0;
                        this.slideVelY_ = 0;
                    }
                }
                moveVec_.x = this.slideVelX_;
                moveVec_.y = this.slideVelY_;
            } else {
                // Not on slide tile: reset slide velocity to current movement
                this.slideVelX_ = moveVec_.x;
                this.slideVelY_ = moveVec_.y;
            }
            this.walkTo(x_ + dt * moveVec_.x, y_ + dt * moveVec_.y);
        }
        else if (!super.update(time, dt)) {
            return false;
        }

        // Raft bounds clamping: keep player within raft area
        if (this.ridingEntityId_ > 0 && map_ != null && map_.player_ == this) {
            var raftClamp:GameObject = map_.goDict_[this.ridingEntityId_];
            if (raftClamp != null && raftClamp.props_.isRaft_) {
                // 3x4 tile raft, bottom-center anchored
                var clampedX:Number = Math.max(raftClamp.x_ - 1.5, Math.min(raftClamp.x_ + 1.5, x_));
                var clampedY:Number = Math.max(raftClamp.y_ - 3.0, Math.min(raftClamp.y_, y_));
                if (clampedX != x_ || clampedY != y_) {
                    x_ = clampedX;
                    y_ = clampedY;
                }
            }
        }

        // Riding: snap mount to player + sync animation (but NOT for rafts)
        if (this.ridingEntityId_ > 0 && map_ != null) {
            var mount:GameObject = map_.goDict_[this.ridingEntityId_];
            if (mount != null && !mount.props_.isRaft_) {
                mount.isLocalMount_ = true;
                mount.moveTo(x_, y_);
                mount.moveVec_.x = moveVec_.x;
                mount.moveVec_.y = moveVec_.y;
                if (moveVec_.x != 0 || moveVec_.y != 0) {
                    mount.facing_ = Math.atan2(moveVec_.y, moveVec_.x);
                }
            }
        }

        if (map_.player_ == this && square_.props_.maxDamage_ > 0 && square_.lastDamage_ + 500 < time && !isInvincible() && (square_.obj_ == null || !square_.obj_.props_.protectFromGroundDamage_)) {
            d = map_.gs_.gsc_.getNextDamage(square_.props_.minDamage_, square_.props_.maxDamage_);
            damage( d, null, hp_ <= d, null, false);
            map_.gs_.gsc_.groundDamage(time, x_, y_);
            square_.lastDamage_ = time;
        }

        //editor8182381 — Heartbeat sound when low HP (plays independently of SFX toggle)
        if (map_.player_ == this && Parameters.data_.playHeartbeat && hp_ > 0 && maxHP_ > 0 && hp_ < maxHP_ * 0.3) {
            this.heartbeatGraceTime_ = 1500; //editor8182381 — reset grace timer while low HP
            var hpRatio:Number = hp_ / (maxHP_ * 0.3);
            var beatInterval:int = 300 + hpRatio * 700;
            if (time - this.lastHeartbeatTime_ >= beatInterval) {
                var hbVol:Number = Parameters.data_.heartbeatVolume * (0.6 + (1 - hpRatio) * 0.4);
                if (heartbeatSound_ == null) {
                    heartbeatSound_ = SoundEffectLibrary.load("heartbeat");
                }
                try {
                    this.heartbeatChannel_ = heartbeatSound_.play(0, 0, new SoundTransform(hbVol));
                } catch (e:Error) {}
                this.lastHeartbeatTime_ = time;
            }
        } else if (this.heartbeatChannel_ != null) {
            //editor8182381 — don't .stop() mid-sample (causes pop). Let last beat finish naturally, just stop scheduling new ones.
            this.heartbeatChannel_ = null;
            this.lastHeartbeatTime_ = 0;
        }

        return true;
    }

    override protected function generateNameBitmapData(nameText:SimpleText):BitmapData {
        if (this.isPartyMember_) {
            nameText.setColor(Parameters.PARTY_MEMBER_COLOR)
        }
        else if (this.isFellowGuild_) {
            nameText.setColor(Parameters.FELLOW_GUILD_COLOR);
        }
        else if (this.nameChosen_) {
            nameText.setColor(Parameters.NAME_CHOSEN_COLOR);
        }
        var nameBitmapData:BitmapData = new BitmapData(nameText.width, 64, true, 0);
        nameBitmapData.draw(nameText, null);
        nameBitmapData.applyFilter(nameBitmapData, nameBitmapData.rect, PointUtil.ORIGIN, new GlowFilter(0, 1, 3, 3, 2, 1));
        return nameBitmapData;
    }

    override public function computeSortVal(camera:Camera):void {
        super.computeSortVal(camera);
        if (this.ridingEntityId_ > 0) {
            this.sortVal_ += 1;
        }
        // When touching a tall wall and behind it from camera view,
        // bump player sort down so wall draws on top
        if (this == map_.player_)
        {
            var pi:int = int(this.x_);
            var pj:int = int(this.y_);
            var nbrX:Array = [0,1,0,-1];
            var nbrY:Array = [-1,0,1,0];
            for (var d:int = 0; d < 4; d++)
            {
                var sq:Square = map_.lookupSquare(pi + nbrX[d], pj + nbrY[d]);
                if (sq != null && sq.obj_ is Wall && !sq.obj_.dead_
                    && ObjectLibrary.customWallSlices_[sq.obj_.objectType_] != null)
                {
                    var dx:Number = this.x_ - sq.obj_.x_;
                    var dy:Number = this.y_ - sq.obj_.y_;
                    var distSq:Number = dx * dx + dy * dy;
                    if (distSq < 2.25)
                    {
                        var camCos:Number = Math.cos(camera.angleRad_ + Math.PI / 2);
                        var camSin:Number = Math.sin(camera.angleRad_ + Math.PI / 2);
                        var dot:Number = dx * camCos + dy * camSin;
                        // Dynamic sort bump based on camera angle:
                        // dot < 0.6: player is behind or beside wall
                        // Linearly scale: dot=0.6 → bump=-4, dot=-1 → bump=-12
                        if (dot < 0.6)
                        {
                            var t:Number = (0.6 - dot) / 1.6; // 0 at dot=0.6, 1 at dot=-1
                            if (t > 1) t = 1;
                            this.sortVal_ -= 4 + Math.round(t * 8);
                            break;
                        }
                    }
                }
            }
        }
    }

    override public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int):void {
        switch (Parameters.data_.hideList) {
            case 1:
                if (this != map_.player_ && !this.starred_) return;
                break;
            case 2:
                if (this != map_.player_ && !this.isFellowGuild_) return;
                break;
            case 3:
                if (this != map_.player_ && !this.isPartyMember_) return;
                break;
            case 4:
                if (this != map_.player_ && !this.starred_ && !this.isFellowGuild_ && !this.isPartyMember_) return;
                break;
        }
        if (this.ridingEntityId_ > 0 && map_ != null) {
            var drawMount:GameObject = map_.goDict_[this.ridingEntityId_];
            if (drawMount == null || !drawMount.props_.isRaft_) {
                this.posS_[4] -= 20;
            }
        }
        super.draw(graphicsData, camera, time);
        if (this.ridingEntityId_ > 0 && map_ != null) {
            var drawMount2:GameObject = map_.goDict_[this.ridingEntityId_];
            if (drawMount2 == null || !drawMount2.props_.isRaft_) {
                this.posS_[4] += 20;
            }
        }
        if (this != map_.player_) {
            drawName(graphicsData, camera);
        }
        else if (this.breath_ >= 0) {
            this.drawBreathBar(graphicsData, time);
        }
    }

    override protected function getTexture(camera:Camera, time:int):BitmapData {
        var image:MaskedImage = null;
        var walkPer:int = 0;
        var dict:Dictionary = null;
        var rv:Number = NaN;
        var p:Number = 0;
        var action:int = AnimatedChar.STAND;
        if (time < attackStart_ + this.attackPeriod_) {
            facing_ = attackAngle_;
            p = (time - attackStart_) % this.attackPeriod_ / this.attackPeriod_;
            action = AnimatedChar.ATTACK;
        }
        else if (moveVec_.x != 0 || moveVec_.y != 0) {
            if (moveVec_.y != 0 || moveVec_.x != 0) {
                facing_ = Math.atan2(moveVec_.y, moveVec_.x);
            }
            if (this.ridingEntityId_ > 0 && map_ != null) {
                var animMount:GameObject = map_.goDict_[this.ridingEntityId_];
                if (animMount != null && animMount.props_.isRaft_) {
                    // Raft: show walking animation normally
                    walkPer = 3.5 / this.getMoveSpeed();
                    p = time % walkPer / walkPer;
                    action = AnimatedChar.WALK;
                } else {
                    // Regular mount: stand still
                    action = AnimatedChar.STAND;
                }
            } else {
                walkPer = 3.5 / this.getMoveSpeed();
                p = time % walkPer / walkPer;
                action = AnimatedChar.WALK;
            }
        }
        if (this.isHexed()) {
            this.isDefaultAnimatedChar && this.setToRandomAnimatedCharacter();
        }
        else if (!this.isDefaultAnimatedChar) {
            this.makeSkinTexture();
        }
        if (camera.isHallucinating_) {
            image = new MaskedImage(getHallucinatingTexture(), null);
        }
        else {
            image = animatedChar_.imageFromFacing(facing_, camera, action, p);
        }
        var tex1Id:int = tex1Id_;
        var tex2Id:int = tex2Id_;
        var texture:BitmapData = null;
        if (this.nearestMerchant_ != null) {
            dict = texturingCache_[this.nearestMerchant_];
            if (dict == null) {
                texturingCache_[this.nearestMerchant_] = new Dictionary();
            }
            else {
                texture = dict[image];
            }
            tex1Id = this.nearestMerchant_.getTex1Id(tex1Id_);
            tex2Id = this.nearestMerchant_.getTex2Id(tex2Id_);
        }
        else {
            texture = texturingCache_[image];
        }
        if (texture == null) {
            texture = TextureRedrawer.resize(image.image_, image.mask_, size_, false, tex1Id, tex2Id);
            if (this.nearestMerchant_ != null) {
                texturingCache_[this.nearestMerchant_][image] = texture;
            }
            else {
                texturingCache_[image] = texture;
            }
        }
        if (hp_ < maxHP_ * 0.2) {
            rv = int(Math.abs(Math.sin(time / 200)) * 10) / 10;
            var ct:ColorTransform = lowHealthCT[rv];
            if (ct == null) {
                ct = new ColorTransform(1, 1, 1, 1,
                        rv * LOW_HEALTH_CT_OFFSET,
                        -rv * LOW_HEALTH_CT_OFFSET,
                        -rv * LOW_HEALTH_CT_OFFSET);
                lowHealthCT[rv] = ct;
            }
            texture = CachingColorTransformer.transformBitmapData(texture, ct);
        }
        var filteredTexture:BitmapData = texturingCache_[texture];
        if (filteredTexture == null) {
            filteredTexture = GlowRedrawer.outlineGlow(texture, this.glowColor_);
            texturingCache_[texture] = filteredTexture;
        }
        if (this.isCursed()) {
            filteredTexture = CachingColorTransformer.filterBitmapData(filteredTexture, CURSED_FILTER);
        }
        if (isPaused() || isStasis() || isPetrified()) {
            filteredTexture = CachingColorTransformer.filterBitmapData(filteredTexture, PAUSED_FILTER);
        }
        else if (isInvisible()) {
            filteredTexture = CachingColorTransformer.alphaBitmapData(filteredTexture, 40);
        }
        return filteredTexture;
    }

    //editor8182381 — Classless: always use skin portrait, no rank icons
    override public function getPortrait():BitmapData {
        return super.getPortrait();
    }

    override public function setAttack(containerType:int, attackAngle:Number):void {
        var weaponXML:XML = ObjectLibrary.xmlLibrary_[containerType];
        if (weaponXML == null || !weaponXML.hasOwnProperty("RateOfFire")) {
            return;
        }
        var rateOfFire:Number = Number(weaponXML.RateOfFire);

        this.attackPeriod_ = 1 / this.attackFrequency() * (1 / rateOfFire);
        super.setAttack(containerType, attackAngle);
    }

    public function setRelativeMovement(rotate:Number, relMoveVecX:Number, relMoveVecY:Number):void {
        var temp:Number = NaN;
        if (this.relMoveVec_ == null) {
            this.relMoveVec_ = new Point();
        }
        this.rotate_ = rotate;
        this.relMoveVec_.x = relMoveVecX;
        this.relMoveVec_.y = relMoveVecY;
        if (isConfused()) {
            temp = this.relMoveVec_.x;
            this.relMoveVec_.x = -this.relMoveVec_.y;
            this.relMoveVec_.y = -temp;
            this.rotate_ = -this.rotate_;
        }
    }

    public function setCredits(credits:int):void {
        this.credits_ = credits;
    }

    public function setParty():void {
        var go:GameObject = null;
        var player:Player = null;
        var isPartyMember:Boolean = false;
        var myPlayer:Player = map_.player_;
        if (myPlayer == this) {
            for each(go in map_.goDict_) {
                player = go as Player;
                if (player != null && player != this) {
                    player.setParty();
                }
            }
        }
        else {
            isPartyMember = myPlayer != null && myPlayer.partyId_ != 0 && myPlayer.partyId_ == this.partyId_;
            if (isPartyMember != this.isPartyMember_) {
                this.isPartyMember_ = isPartyMember;
                nameBitmapData_ = null;
            }
        }
    }

    public function setGuildName(guildName:String):void {
        var go:GameObject = null;
        var player:Player = null;
        var isFellowGuild:Boolean = false;
        this.guildName_ = guildName;
        var myPlayer:Player = map_.player_;
        if (myPlayer == this) {
            for each(go in map_.goDict_) {
                player = go as Player;
                if (player != null && player != this) {
                    player.setGuildName(player.guildName_);
                }
            }
        }
        else {
            isFellowGuild = myPlayer != null && myPlayer.guildName_ != null && myPlayer.guildName_ != "" && myPlayer.guildName_ == this.guildName_;
            if (isFellowGuild != this.isFellowGuild_) {
                this.isFellowGuild_ = isFellowGuild;
                nameBitmapData_ = null;
            }
        }
    }

    public function isTeleportEligible(player:Player):Boolean {
        return !(player.isPaused() || player.isInvisible());
    }

    public function msUtilTeleport():int {
        var time:int = getTimer();
        return Math.max(0, this.nextTeleportAt_ - time);
    }

    public function teleportTo(player:Player):Boolean {
        if (isPaused()) {
            this.addTextLine.dispatch(new AddTextLineVO(Parameters.ERROR_CHAT_NAME, "Can not teleport while paused."));
            return false;
        }
        var msUtil:int = this.msUtilTeleport();
        if (msUtil > 0) {
            this.addTextLine.dispatch(new AddTextLineVO(Parameters.ERROR_CHAT_NAME, "You can not teleport for another " + int(msUtil / 1000 + 1) + " seconds."));
            return false;
        }
        if (!this.isTeleportEligible(player)) {
            if (player.isInvisible()) {
                this.addTextLine.dispatch(new AddTextLineVO(Parameters.ERROR_CHAT_NAME, "Can not teleport to " + player.name_ + " while they are invisible."));
            }
            this.addTextLine.dispatch(new AddTextLineVO(Parameters.ERROR_CHAT_NAME, "Can not teleport to " + player.name_));
            return false;
        }
        map_.gs_.gsc_.teleport(player.objectId_);
        this.nextTeleportAt_ = getTimer() + MS_BETWEEN_TELEPORT;
        return true;
    }

    public function levelUpEffect(text:String):void {
        this.levelUpParticleEffect();
        map_.mapOverlay_.addStatusText(new CharacterStatusText(this, text, 65280, 2000));
    }

    public function handleLevelUp(isUnlock:Boolean):void {
        SoundEffectLibrary.play("level_up");
        if (isUnlock) {
            this.levelUpEffect("New Class Unlocked!");
        }
        else {
            this.levelUpEffect("Level Up!");
        }
    }

    public function levelUpParticleEffect():void {
        map_.addObj(new LevelUpEffect(this, 4278255360, 20), x_, y_);
    }

    public function handleExpUp(exp:int):void {
        if (level_ == 20) {
            return;
        }
        map_.mapOverlay_.addStatusText(new CharacterStatusText(this, "+" + exp + " EXP", 65280, 1000));
    }

    public function handleFameUp(fame:int):void {
        if (level_ != 20) {
            return;
        }
        if (fame > 0) {
            map_.mapOverlay_.addStatusText(new CharacterStatusText(this, "+" + fame + " Fame", 0xE25F00, 1000));
        }
    }

    public function walkTo(x:Number, y:Number):Boolean {
        // On raft: skip tile passability check — raft bounds clamp handles it
        if (this.ridingEntityId_ > 0 && map_ != null) {
            var raftWalk:GameObject = map_.goDict_[this.ridingEntityId_];
            if (raftWalk != null && raftWalk.props_.isRaft_) {
                return this.moveTo(x, y);
            }
        }
        this.modifyMove(x, y, newP);
        return this.moveTo(newP.x, newP.y);
    }

    public function modifyMove(x:Number, y:Number, newP:Point):void {
        if (isParalyzed() || isPetrified()) {
            newP.x = x_;
            newP.y = y_;
            return;
        }
        var dx:Number = x - x_;
        var dy:Number = y - y_;
        if (dx < MOVE_THRESHOLD && dx > -MOVE_THRESHOLD && dy < MOVE_THRESHOLD && dy > -MOVE_THRESHOLD) {
            this.modifyStep(x, y, newP);
            return;
        }
        var stepSize:Number = MOVE_THRESHOLD / Math.max(Math.abs(dx), Math.abs(dy));
        var d:Number = 0;
        newP.x = x_;
        newP.y = y_;
        var done:Boolean = false;
        while (!done) {
            if (d + stepSize >= 1) {
                stepSize = 1 - d;
                done = true;
            }
            this.modifyStep(newP.x + dx * stepSize, newP.y + dy * stepSize, newP);
            d = d + stepSize;
        }
    }

    public function modifyStep(x:Number, y:Number, newP:Point):void {
        var nextXBorder:Number = NaN;
        var nextYBorder:Number = NaN;
        var xCross:Boolean = x_ % 0.5 == 0 && x != x_ || int(x_ / 0.5) != int(x / 0.5);
        var yCross:Boolean = y_ % 0.5 == 0 && y != y_ || int(y_ / 0.5) != int(y / 0.5);
        if (!xCross && !yCross || this.isValidPosition(x, y)) {
            newP.x = x;
            newP.y = y;
            return;
        }
        if (xCross) {
            nextXBorder = x > x_ ? Number(int(x * 2) / 2) : Number(int(x_ * 2) / 2);
            if (int(nextXBorder) > int(x_)) {
                nextXBorder = nextXBorder - 0.01;
            }
        }
        if (yCross) {
            nextYBorder = y > y_ ? Number(int(y * 2) / 2) : Number(int(y_ * 2) / 2);
            if (int(nextYBorder) > int(y_)) {
                nextYBorder = nextYBorder - 0.01;
            }
        }
        if (!xCross) {
            newP.x = x;
            newP.y = nextYBorder;
            return;
        }
        if (!yCross) {
            newP.x = nextXBorder;
            newP.y = y;
            return;
        }
        var xBorderDist:Number = x > x_ ? Number(x - nextXBorder) : Number(nextXBorder - x);
        var yBorderDist:Number = y > y_ ? Number(y - nextYBorder) : Number(nextYBorder - y);
        if (xBorderDist > yBorderDist) {
            if (this.isValidPosition(x, nextYBorder)) {
                newP.x = x;
                newP.y = nextYBorder;
                return;
            }
            if (this.isValidPosition(nextXBorder, y)) {
                newP.x = nextXBorder;
                newP.y = y;
                return;
            }
        }
        else {
            if (this.isValidPosition(nextXBorder, y)) {
                newP.x = nextXBorder;
                newP.y = y;
                return;
            }
            if (this.isValidPosition(x, nextYBorder)) {
                newP.x = x;
                newP.y = nextYBorder;
                return;
            }
        }
        newP.x = nextXBorder;
        newP.y = nextYBorder;
    }

    public function isValidPosition(x:Number, y:Number):Boolean {
        var square:Square = map_.getSquare(x, y);
        if (square_ != square && (square == null || !square.isWalkable())) {
            return false;
        }
        var xFrac:Number = x - int(x);
        var yFrac:Number = y - int(y);
        if (xFrac < 0.5) {
            if (this.isFullOccupy(x - 1, y)) {
                return false;
            }
            if (yFrac < 0.5) {
                if (this.isFullOccupy(x, y - 1) || this.isFullOccupy(x - 1, y - 1)) {
                    return false;
                }
            }
            else if (yFrac > 0.5) {
                if (this.isFullOccupy(x, y + 1) || this.isFullOccupy(x - 1, y + 1)) {
                    return false;
                }
            }
        }
        else if (xFrac > 0.5) {
            if (this.isFullOccupy(x + 1, y)) {
                return false;
            }
            if (yFrac < 0.5) {
                if (this.isFullOccupy(x, y - 1) || this.isFullOccupy(x + 1, y - 1)) {
                    return false;
                }
            }
            else if (yFrac > 0.5) {
                if (this.isFullOccupy(x, y + 1) || this.isFullOccupy(x + 1, y + 1)) {
                    return false;
                }
            }
        }
        else if (yFrac < 0.5) {
            if (this.isFullOccupy(x, y - 1)) {
                return false;
            }
        }
        else if (yFrac > 0.5) {
            if (this.isFullOccupy(x, y + 1)) {
                return false;
            }
        }
        return true;
    }

    public function isFullOccupy(x:Number, y:Number):Boolean {
        var square:Square = map_.lookupSquare(x, y);
        return square == null || square.tileType_ == 255 || square.obj_ != null && square.obj_.props_.fullOccupy_;
    }

    public function onMove():void {
        var square:Square = map_.getSquare(x_, y_);
        if (square.props_.sinking_) {
            sinkLevel_ = Math.min(sinkLevel_ + 1, Parameters.MAX_SINK_LEVEL);
            this.moveMultiplier_ = 0.1 + (1 - sinkLevel_ / Parameters.MAX_SINK_LEVEL) * (square.props_.speed_ - 0.1);
        }
        else {
            sinkLevel_ = 0;
            this.moveMultiplier_ = square.props_.speed_;
        }
        // On raft: always normal walk speed (tile speed affects raft drift instead)
        if (this.ridingEntityId_ > 0 && map_ != null) {
            var raftMount:GameObject = map_.goDict_[this.ridingEntityId_];
            if (raftMount != null && raftMount.props_.isRaft_) {
                sinkLevel_ = 0;
                this.moveMultiplier_ = 1.0;
            }
        }
    }

    public function attackFrequency():Number {
        if (isDazed()) {
            return MIN_ATTACK_FREQ;
        }
        var attFreq:Number = MIN_ATTACK_FREQ + this.dexterity_ / 75 * (MAX_ATTACK_FREQ - MIN_ATTACK_FREQ);
        if (isBerserk()) {
            attFreq = attFreq * 1.25;
        }
        return attFreq;
    }

    public function getPortrait2():BitmapData {
        var image:MaskedImage = null;
        var size:int = 0;
        if (portrait2_ == null) {
            image = animatedChar_.imageFromDir(AnimatedChar.RIGHT, AnimatedChar.STAND, 0);
            size = 4 / image.image_.width * 100;
            portrait2_ = TextureRedrawer.resize(image.image_, image.mask_, size, true, tex1Id_, tex2Id_);
        }
        return portrait2_;
    }

    public function useAltWeapon(xS:Number, yS:Number, useType:int):Boolean {
        var activateXML:XML = null;
        var now:int = 0;
        var angle:Number = NaN;
        var mpCost:int = 0;
        var cooldown:int = 0;
        if (map_ == null || isPaused()) {
            return false;
        }

        if(map_.disableAbilities_){
            return false;
        }

        var itemType:int = equipment_[1];
        if (itemType == -1) {
            return false;
        }
        var objectXML:XML = ObjectLibrary.xmlLibrary_[itemType];
        if (objectXML == null || !objectXML.hasOwnProperty("Usable")) {
            return false;
        }
        var pW:Point = map_.pSTopW(xS, yS);
        if (pW == null) {
            SoundEffectLibrary.play("error");
            return false;
        }

        // Night vision: override target to shoot straight ahead based on camera angle
        if (this.isNightVision()) {
            var forwardAngle:Number = Parameters.data_.cameraAngle - Math.PI / 2;
            pW.x = x_ + 6 * Math.cos(forwardAngle);
            pW.y = y_ + 6 * Math.sin(forwardAngle);
        }

        var shoot:Boolean = false;
        for each(activateXML in objectXML.Activate) {
            if (activateXML.toString() == ActivationType.TELEPORT) {
                if (!this.isValidPosition(pW.x, pW.y)) {
                    SoundEffectLibrary.play("error");
                    return false;
                }
            }
            if (activateXML.toString() == ActivationType.SHOOT) {
                shoot = true;
            }
        }
        now = getTimer();
        if (useType == UseType.START_USE) {
            if (now < this.nextAltAttack_) {
                SoundEffectLibrary.play("error");
                return false;
            }

            mpCost = int(objectXML.MpCost);
            if (mpCost > this.mp_) {
                SoundEffectLibrary.play("no_mana");
                return false;
            }

            cooldown = 500;
            if (objectXML.hasOwnProperty("Cooldown")) {
                cooldown = Number(objectXML.Cooldown) * 1000;
            }
            this.nextAltAttack_ = now + cooldown;
            map_.gs_.gsc_.useItem(now, objectId_, 1, itemType, pW.x, pW.y, useType);
            if (shoot) {
                angle = Math.atan2(yS, xS);
                this.doShoot(now, itemType, objectXML, Parameters.data_.cameraAngle + angle, false);
            }
        }
        else if (objectXML.hasOwnProperty("MultiPhase")) {
            map_.gs_.gsc_.useItem(now, objectId_, 1, itemType, pW.x, pW.y, useType);

            mpCost = int(objectXML.MpEndCost);
            if (mpCost <= this.mp_) {
                angle = Math.atan2(yS, xS);
                this.doShoot(now, itemType, objectXML, Parameters.data_.cameraAngle + angle, false);
            }
        }
        return true;
    }

    public function attemptAttackAngle(angle:Number):void {
        this.shoot(Parameters.data_.cameraAngle + angle);
    }

    public function isHexed():Boolean {
        return (condition_[ConditionEffect.CE_FIRST_BATCH] & ConditionEffect.HEXED_BIT) != 0;
    }

    public function isInventoryFull():Boolean {
        var len:int = equipment_.length;
        for (var i:uint = 4; i < len; i++) {
            if (equipment_[i] <= 0) {
                return false;
            }
        }
        return true;
    }

    public function nextAvailableInventorySlot():int {
        var len:int = this.hasBackpack_ ? int(equipment_.length- GeneralConstants.NUM_INVENTORY_SLOTS) : int(equipment_.length - GeneralConstants.NUM_INVENTORY_SLOTS - GeneralConstants.NUM_BACKPACK_SLOTS);
        for (var i:uint = 4; i < len; i++) {
            if (equipment_[i] == -1) {
                return i;
            }
        }
        return -1;
    }

    public function swapInventoryIndex(current:String):int {
        var start:int = 0;
        var end:int = 0;
        if (!this.hasBackpack_) {
            return -1;
        }

        if (current == TabStripModel.BACKPACK) {
            start = GeneralConstants.NUM_EQUIPMENT_SLOTS;
            end = GeneralConstants.NUM_EQUIPMENT_SLOTS + GeneralConstants.NUM_INVENTORY_SLOTS;
        }
        else {
            start = GeneralConstants.NUM_EQUIPMENT_SLOTS + GeneralConstants.NUM_INVENTORY_SLOTS;
            end = equipment_.length;
        }

        for (var i:uint = start; i < end; i++) {
            if (equipment_[i] == -1) {
                return i;
            }
        }
        return -1;
    }

    public function getPotionCount(objectType:int):int {
        switch (objectType) {
            case PotionInventoryModel.HEALTH_POTION_ID:
                return this.healthPotionCount_;
            case PotionInventoryModel.MAGIC_POTION_ID:
                return this.magicPotionCount_;
            default:
                return 0;
        }
    }

    private function drawDashIndicator(graphicsData:Vector.<IGraphicsData>, time:int):void {
        var now:int = getTimer();
        var remaining:int = this.dashCooldownEnd_ - now;

        if (this.dashArcFill_ == null) {
            this.dashArcFill_ = new GraphicsSolidFill(0x60B0E0, 0.9);
            this.dashArcPath_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());
            this.dashBgFill_ = new GraphicsSolidFill(0x222222, 0.6);
            this.dashBgPath_ = new GraphicsPath(new Vector.<int>(), new Vector.<Number>());
        }

        var cx:Number = posS_[0];
        var cy:Number = posS_[1] + DEFAULT_HP_BAR_Y_OFFSET + DEFAULT_HP_BAR_HEIGHT + 10;
        var r:Number = DASH_CIRCLE_RADIUS;
        var progress:Number = remaining <= 0 ? 1.0 : 1.0 - (remaining / Number(DASH_COOLDOWN_MS));
        if (progress > 1.0) progress = 1.0;
        if (progress < 0) progress = 0;

        var i:int;
        var angle:Number;

        // Background circle (dark)
        this.dashBgPath_.commands.length = 0;
        this.dashBgPath_.data.length = 0;
        this.dashBgPath_.commands.push(GraphicsPathCommand.MOVE_TO);
        this.dashBgPath_.data.push(cx, cy - r);
        for (i = 1; i <= DASH_CIRCLE_SEGMENTS; i++) {
            angle = -Math.PI / 2 + (i / Number(DASH_CIRCLE_SEGMENTS)) * Math.PI * 2;
            this.dashBgPath_.commands.push(GraphicsPathCommand.LINE_TO);
            this.dashBgPath_.data.push(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
        }
        graphicsData.push(this.dashBgFill_);
        graphicsData.push(this.dashBgPath_);
        graphicsData.push(GraphicsUtil.END_FILL);

        // Progress arc (blue, counter-clockwise from top)
        if (progress > 0) {
            var arcEnd:Number = progress * Math.PI * 2;
            var arcSegments:int = Math.max(2, int(progress * DASH_CIRCLE_SEGMENTS));

            this.dashArcPath_.commands.length = 0;
            this.dashArcPath_.data.length = 0;

            // Pie slice: center → top → arc → center
            this.dashArcPath_.commands.push(GraphicsPathCommand.MOVE_TO);
            this.dashArcPath_.data.push(cx, cy);
            this.dashArcPath_.commands.push(GraphicsPathCommand.LINE_TO);
            this.dashArcPath_.data.push(cx, cy - r);

            for (i = 1; i <= arcSegments; i++) {
                angle = -Math.PI / 2 + (i / Number(arcSegments)) * arcEnd;
                this.dashArcPath_.commands.push(GraphicsPathCommand.LINE_TO);
                this.dashArcPath_.data.push(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
            }

            this.dashArcPath_.commands.push(GraphicsPathCommand.LINE_TO);
            this.dashArcPath_.data.push(cx, cy);

            // Bright pulse when fully ready
            if (progress >= 1.0) {
                var pulse:Number = 0.7 + 0.3 * Math.abs(Math.sin(time / 400));
                this.dashArcFill_.alpha = pulse;
            } else {
                this.dashArcFill_.alpha = 0.9;
            }

            graphicsData.push(this.dashArcFill_);
            graphicsData.push(this.dashArcPath_);
            graphicsData.push(GraphicsUtil.END_FILL);
        }

        GraphicsFillExtra.setSoftwareDrawSolid(this.dashArcFill_, true);
        GraphicsFillExtra.setSoftwareDrawSolid(this.dashBgFill_, true);
    }

    protected function drawBreathBar(graphicsData:Vector.<IGraphicsData>, time:int):void {
        var b:Number = NaN;
        var bw:Number = NaN;
        if (this.breathPath_ == null) {
            this.breathBackFill_ = new GraphicsSolidFill();
            this.breathBackPath_ = new GraphicsPath(GraphicsUtil.QUAD_COMMANDS, new Vector.<Number>());
            this.breathFill_ = new GraphicsSolidFill(2542335);
            this.breathPath_ = new GraphicsPath(GraphicsUtil.QUAD_COMMANDS, new Vector.<Number>());
        }
        if (this.breath_ <= Parameters.BREATH_THRESH) {
            b = (Parameters.BREATH_THRESH - this.breath_) / Parameters.BREATH_THRESH;
            this.breathBackFill_.color = MoreColorUtil.lerpColor(5526612, 16711680, Math.abs(Math.sin(time / 300)) * b);
        }
        else {
            this.breathBackFill_.color = 5526612;
        }
        var w:int = DEFAULT_HP_BAR_WIDTH;
        var yOffset:int = DEFAULT_HP_BAR_Y_OFFSET + DEFAULT_HP_BAR_HEIGHT;
        var h:int = DEFAULT_HP_BAR_HEIGHT;
        this.breathBackPath_.data.length = 0;
        this.breathBackPath_.data.push(posS_[0] - w, posS_[1] + yOffset, posS_[0] + w, posS_[1] + yOffset, posS_[0] + w, posS_[1] + yOffset + h, posS_[0] - w, posS_[1] + yOffset + h);
        graphicsData.push(this.breathBackFill_);
        graphicsData.push(this.breathBackPath_);
        graphicsData.push(GraphicsUtil.END_FILL);
        if (this.breath_ > 0) {
            bw = this.breath_ / 100 * 2 * w;
            this.breathPath_.data.length = 0;
            this.breathPath_.data.push(posS_[0] - w, posS_[1] + yOffset, posS_[0] - w + bw, posS_[1] + yOffset, posS_[0] - w + bw, posS_[1] + yOffset + h, posS_[0] - w, posS_[1] + yOffset + h);
            graphicsData.push(this.breathFill_);
            graphicsData.push(this.breathPath_);
            graphicsData.push(GraphicsUtil.END_FILL);
        }
        GraphicsFillExtra.setSoftwareDrawSolid(this.breathFill_, true);
        GraphicsFillExtra.setSoftwareDrawSolid(this.breathBackFill_, true);
    }

    private function getNearbyMerchant():Merchant {
        var p:Point = null;
        var m:Merchant = null;
        var dx:int = x_ - int(x_) > 0.5 ? int(1) : int(-1);
        var dy:int = y_ - int(y_) > 0.5 ? int(1) : int(-1);
        for each(p in NEARBY) {
            this.ip_.x_ = x_ + dx * p.x;
            this.ip_.y_ = y_ + dy * p.y;
            m = map_.merchLookup_[this.ip_];
            if (m != null) {
                return PointUtil.distanceSquaredXY(m.x_, m.y_, x_, y_) < 1 ? m : null;
            }
        }
        return null;
    }

    private function getMoveSpeed():Number {
        if (isSlowed()) {
            return MIN_MOVE_SPEED * this.moveMultiplier_;
        }
        var moveSpeed:Number = MIN_MOVE_SPEED + this.speed_ / 75 * (MAX_MOVE_SPEED - MIN_MOVE_SPEED);
        if (isSpeedy() || isNinjaSpeedy()) {
            moveSpeed = moveSpeed * 1.35;
        }
        moveSpeed = moveSpeed * this.moveMultiplier_;
        return moveSpeed;
    }

    private function attackMultiplier():Number {
        if (isWeak()) {
            return MIN_ATTACK_MULT;
        }
        var attMult:Number = MIN_ATTACK_MULT + this.attack_ / 75 * (MAX_ATTACK_MULT - MIN_ATTACK_MULT);
        if (isDamaging()) {
            attMult = attMult * 1.25;
        }
        return attMult;
    }

    private function makeSkinTexture():void {
        var image:MaskedImage = this.skin.imageFromAngle(0, AnimatedChar.STAND, 0);
        animatedChar_ = this.skin;
        texture_ = image.image_;
        mask_ = image.mask_;
        this.isDefaultAnimatedChar = true;
    }

    private function setToRandomAnimatedCharacter():void {
        var hexTransformList:Vector.<XML> = ObjectLibrary.hexTransforms_;
        var randIndex:uint = Math.floor(Math.random() * hexTransformList.length);
        var randomPetType:int = hexTransformList[randIndex].@type;
        var textureData:TextureData = ObjectLibrary.typeToTextureData_[randomPetType];
        texture_ = textureData.texture_;
        mask_ = textureData.mask_;
        animatedChar_ = textureData.animatedChar_;
        this.isDefaultAnimatedChar = false;
    }

    private function shoot(attackAngle:Number):void {
        if(map_.disableShooting_){
            return;
        }

        if (map_ == null || isStunned() || isPaused() || isPetrified()) {
            return;
        }
        var weaponType:int = equipment_[0];
        if (weaponType == -1) {
            return;
        }
        var weaponXML:XML = ObjectLibrary.xmlLibrary_[weaponType];
        var time:int = getTimer();
        var rateOfFire:Number = Number(weaponXML.RateOfFire);

        this.attackPeriod_ = 1 / this.attackFrequency() * (1 / rateOfFire);

        if (time < attackStart_ + this.attackPeriod_) {
            return;
        }

        doneAction(map_.gs_, Tutorial.ATTACK_ACTION);
        attackAngle_ = attackAngle;
        attackStart_ = time;
        this.doShoot(attackStart_, weaponType, weaponXML, attackAngle_, true, true);
    }

    private function doShoot(time:int, weaponType:int, weaponXML:XML, attackAngle:Number, useMult:Boolean, hasSpeedMult:Boolean = false):void {
        var bulletId:uint = 0;
        var proj:Projectile = null;
        var minDamage:int = 0;
        var maxDamage:int = 0;
        var attMult:Number = NaN;
        var damage:int = 0;
        var numProjs:int = Boolean(weaponXML.hasOwnProperty("NumProjectiles")) ? int(int(weaponXML.NumProjectiles)) : int(1);
        var arcGap:Number = (Boolean(weaponXML.hasOwnProperty("ArcGap")) ? Number(weaponXML.ArcGap) : 11.25) * Trig.toRadians;
        var totalArc:Number = arcGap * (numProjs - 1);
        var angle:Number = attackAngle - totalArc / 2;
        var speedMult:Number = isInspired() ? 1.25 : 1;
        for (var i:int = 0; i < numProjs; i++) {
            bulletId = getBulletId();
            proj = FreeList.newObject(Projectile) as Projectile;
            proj.reset(weaponType, 0, objectId_, bulletId, angle, time, speedMult);
            minDamage = int(proj.projProps_.minDamage_);
            maxDamage = int(proj.projProps_.maxDamage_);
            attMult = useMult ? Number(this.attackMultiplier()) : Number(1);
            damage = map_.gs_.gsc_.getNextDamage(minDamage, maxDamage) * attMult;
            if (time > map_.gs_.moveRecords_.lastClearTime_ + 600) {
                damage = 0;
            }
            proj.setDamage(damage);
            if (i == 0 && proj.sound_ != null) {
                SoundEffectLibrary.play(proj.sound_, 0.75, false);
            }
            map_.addObj(proj, x_ + Math.cos(attackAngle) * 0.3, y_ + Math.sin(attackAngle) * 0.3);
            angle += arcGap;
            map_.gs_.gsc_.playerShoot(time, proj);
        }
    }
}
}
