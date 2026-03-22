package com.company.assembleegameclient.objects
{
   import com.company.assembleegameclient.engine3d.Face3D;
   import com.company.assembleegameclient.map.Camera;
   import com.company.assembleegameclient.map.Square;
   import com.company.util.BitmapUtil;
   import flash.display.BitmapData;
   import flash.display.IGraphicsData;

   public class Wall extends GameObject
   {

      private static const UVT:Vector.<Number> = new <Number>[0,0,0,1,0,0,1,1,0,0,1,0];

      private static const UVT_FLIP:Vector.<Number> = new <Number>[1,0,0,0,0,0,0,1,0,1,1,0];

      private static const sqX:Vector.<int> = new <int>[0,1,0,-1];

      private static const sqY:Vector.<int> = new <int>[-1,0,1,0];


      public var faces_:Vector.<Face3D>;

      private var topFace_:Face3D = null;

      private var topTexture_:BitmapData = null;

      private var wallSize_:int = 1;

      public function Wall(objectXML:XML)
      {
         this.faces_ = new Vector.<Face3D>();
         super(objectXML);
         hasShadow_ = false;
         if(objectXML.hasOwnProperty("WallSize"))
         {
            this.wallSize_ = int(objectXML.WallSize);
         }
         var topTextureData:TextureData = ObjectLibrary.typeToTopTextureData_[objectType_];
         this.topTexture_ = topTextureData.getTexture(0);
      }

      override public function setObjectId(objectId:int) : void
      {
         super.setObjectId(objectId);
         var topTextureData:TextureData = ObjectLibrary.typeToTopTextureData_[objectType_];
         this.topTexture_ = topTextureData.getTexture(objectId);
      }

      override public function getColor() : uint
      {
         return BitmapUtil.mostCommonColor(this.topTexture_);
      }

      override public function draw(graphicsData:Vector.<IGraphicsData>, camera:Camera, time:int) : void
      {
         var animTexture:BitmapData = null;
         var face:Face3D = null;
         var sq:Square = null;
         if(texture_ == null)
         {
            return;
         }
         if(this.faces_.length == 0)
         {
            this.rebuild3D();
         }
         var texture:BitmapData = texture_;
         if(animations_ != null)
         {
            animTexture = animations_.getTexture(time);
            if(animTexture != null)
            {
               texture = animTexture;
            }
         }
         if(this.wallSize_ > 1)
         {
            // Multi-tile wall: no face culling (spans multiple grid cells)
            for(var mf:int = 0; mf < this.faces_.length; mf++)
            {
               face = this.faces_[mf];
               face.blackOut_ = false;
               if(animations_ != null)
               {
                  face.setTexture(texture);
               }
               face.draw(graphicsData, camera);
            }
            this.topFace_.draw(graphicsData, camera);
            return;
         }
         if(ObjectLibrary.customWallComposite_[objectType_] != null)
         {
            // Composite wall: 4 faces (N,E,S,W) with neighbor culling, same as original
            for(var sf:int = 0; sf < this.faces_.length; sf++)
            {
               face = this.faces_[sf];
               sq = map_.lookupSquare(x_ + sqX[sf], y_ + sqY[sf]);
               if(sq == null || sq.texture_ == null || sq.obj_ is Wall && !sq.obj_.dead_)
               {
                  face.blackOut_ = true;
               }
               else
               {
                  face.blackOut_ = false;
               }
               face.draw(graphicsData, camera);
            }
            this.topFace_.draw(graphicsData, camera);
            return;
         }
         // Single-tile wall: original face culling logic
         for(var f:int = 0; f < this.faces_.length; f++)
         {
            face = this.faces_[f];
            sq = map_.lookupSquare(x_ + sqX[f],y_ + sqY[f]);
            if(sq == null || sq.texture_ == null || sq != null && sq.obj_ is Wall && !sq.obj_.dead_)
            {
               face.blackOut_ = true;
            }
            else
            {
               face.blackOut_ = false;
               if(animations_ != null)
               {
                  face.setTexture(texture);
               }
            }
            face.draw(graphicsData,camera);
         }
         this.topFace_.draw(graphicsData,camera);
      }

      public function rebuild3D() : void
      {
         this.faces_.length = 0;
         var xi:int = x_;
         var yi:int = y_;
         var s:int = this.wallSize_;

         // Check for composite wall texture (custom walls with spriteSize > 8)
         var compTex:BitmapData = ObjectLibrary.customWallComposite_[objectType_];
         if (compTex != null)
         {
            // Single face per side spanning full height, like the base game
            var h:int = compTex.height / 8; // number of 8×8 slices = wall height in units
            var topVin:Vector.<Number> = new <Number>[xi,yi,h, xi+1,yi,h, xi+1,yi+1,h, xi,yi+1,h];
            this.topFace_ = new Face3D(this.topTexture_,topVin,UVT,false,true);
            this.topFace_.bitmapFill_.repeat = true;
            this.addCompositeWall(xi, yi, h, xi+1, yi, h, compTex, false);
            this.addCompositeWall(xi+1, yi, h, xi+1, yi+1, h, compTex, false);
            this.addCompositeWall(xi+1, yi+1, h, xi, yi+1, h, compTex, true);
            this.addCompositeWall(xi, yi+1, h, xi, yi, h, compTex, true);
         }
         else
         {
            // Original: single cube of s×s×s
            var vin:Vector.<Number> = new <Number>[xi,yi,s, xi+s,yi,s, xi+s,yi+s,s, xi,yi+s,s];
            this.topFace_ = new Face3D(this.topTexture_,vin,UVT,false,true);
            this.topFace_.bitmapFill_.repeat = true;
            this.addWall(xi,yi,s, xi+s,yi,s);
            this.addWall(xi+s,yi,s, xi+s,yi+s,s);
            this.addWall(xi+s,yi+s,s, xi,yi+s,s);
            this.addWall(xi,yi+s,s, xi,yi,s);
         }
      }

      private function addWall(x0:Number, y0:Number, z0:Number, x1:Number, y1:Number, z1:Number) : void
      {
         var s:int = this.wallSize_;
         var vin:Vector.<Number> = new <Number>[x0,y0,z0,x1,y1,z1,x1,y1,z1 - s,x0,y0,z0 - s];
         var face:Face3D = new Face3D(texture_,vin,UVT,true,true);
         face.bitmapFill_.repeat = true;
         this.faces_.push(face);
      }

      private function addCompositeWall(x0:Number, y0:Number, z0:Number, x1:Number, y1:Number, z1:Number, compTex:BitmapData, flipU:Boolean = false) : void
      {
         // Single face spanning full wall height, using composite texture
         var h:int = compTex.height / 8;
         var vin:Vector.<Number> = new <Number>[x0,y0,z0,x1,y1,z1,x1,y1,z1 - h,x0,y0,z0 - h];
         var face:Face3D = new Face3D(compTex,vin,flipU ? UVT_FLIP : UVT,true,true);
         face.bitmapFill_.repeat = true;
         this.faces_.push(face);
      }
   }
}
