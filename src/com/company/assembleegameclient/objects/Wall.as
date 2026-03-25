package com.company.assembleegameclient.objects
{
   import com.company.assembleegameclient.engine3d.Face3D;
   import com.company.assembleegameclient.map.AnimateProperties;
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

      override public function computeSortVal(camera:Camera) : void
      {
         var slices:Vector.<BitmapData> = ObjectLibrary.customWallSlices_[objectType_];
         if(slices != null && slices.length > 1)
         {
            // Tall wall: sort using z=1 (just above base)
            this.posW_.length = 0;
            this.posW_.push(this.x_,this.y_,0,this.x_,this.y_,1);
            this.posS_.length = 0;
            camera.wToS_.transformVectors(this.posW_,this.posS_);
            this.sortVal_ = int(this.posS_[4]);
         }
         else
         {
            super.computeSortVal(camera);
         }
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

         // Check if the ground at this wall's position has flow/wave animation
         var mySq:Square = square_;
         var animType:int = 0;
         if(mySq != null && mySq.props_ != null && mySq.props_.animate_ != null)
         {
            animType = mySq.props_.animate_.type_;
         }
         if(animType != AnimateProperties.NO_ANIMATE)
         {
            var animDx:Number = mySq.props_.animate_.dx_;
            var animDy:Number = mySq.props_.animate_.dy_;
            var xOff:Number = 0;
            var yOff:Number = 0;
            if(animType == AnimateProperties.WAVE_ANIMATE)
            {
               xOff = Math.sin(animDx * time / 1000);
               yOff = Math.sin(animDy * time / 1000);
            }
            else if(animType == AnimateProperties.FLOW_ANIMATE)
            {
               xOff = animDx * time / 1000;
               yOff = animDy * time / 1000;
               xOff = xOff - Math.floor(xOff);
               yOff = yOff - Math.floor(yOff);
            }
            var animUVT:Vector.<Number> = new <Number>[xOff,yOff,0, 1+xOff,yOff,0, 1+xOff,1+yOff,0, xOff,1+yOff,0];
            for each(face in this.faces_)
            {
               face.setUVT(animUVT);
               face.bitmapFill_.repeat = true;
            }
            this.topFace_.setUVT(animUVT);
            this.topFace_.bitmapFill_.repeat = true;
         }

         if(ObjectLibrary.customWallComposite_[objectType_] != null)
         {
            // Custom tall wall: faces 0-3 = N,E,S,W full height
            // Skip any face whose direction has a wall neighbor
            for(var sf:int = 0; sf < this.faces_.length; sf++)
            {
               face = this.faces_[sf];
               sq = map_.lookupSquare(x_ + sqX[sf], y_ + sqY[sf]);
               if(sq != null && sq.obj_ is Wall && !sq.obj_.dead_)
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

         // Check for split wall textures (custom walls with spriteSize > 8)
         var slices:Vector.<BitmapData> = ObjectLibrary.customWallSlices_[objectType_];
         var upperTex:BitmapData = ObjectLibrary.customWallUpper_[objectType_];
         var compTex:BitmapData = ObjectLibrary.customWallComposite_[objectType_];
         if (slices != null && slices.length > 1 && compTex != null)
         {
            var h:int = slices.length; // total height in units
            // Slight overlap (e) to eliminate sub-pixel seam gaps between faces
            var e:Number = 0.02;
            var topVin:Vector.<Number> = new <Number>[xi-e,yi-e,h, xi+1+e,yi-e,h, xi+1+e,yi+1+e,h, xi-e,yi+1+e,h];
            this.topFace_ = new Face3D(this.topTexture_,topVin,UVT,false,true);
            this.topFace_.bitmapFill_.repeat = true;
            // Single full-height faces per direction, extended slightly past corners
            // faces_[0..3] = N,E,S,W full height
            // N face: extend x range by e on each side, extend z up by e
            this.addSplitFace(xi-e, yi, h+e, xi+1+e, yi, h+e, h+e, compTex, false);
            // E face
            this.addSplitFace(xi+1, yi-e, h+e, xi+1, yi+1+e, h+e, h+e, compTex, false);
            // S face
            this.addSplitFace(xi+1+e, yi+1, h+e, xi-e, yi+1, h+e, h+e, compTex, true);
            // W face
            this.addSplitFace(xi, yi+1+e, h+e, xi, yi-e, h+e, h+e, compTex, true);
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

      private function addSplitFace(x0:Number, y0:Number, z0:Number, x1:Number, y1:Number, z1:Number, faceH:Number, tex:BitmapData, flipU:Boolean = false) : void
      {
         // Face spanning faceH units of height
         var vin:Vector.<Number> = new <Number>[x0,y0,z0,x1,y1,z1,x1,y1,z1 - faceH,x0,y0,z0 - faceH];
         var face:Face3D = new Face3D(tex,vin,flipU ? UVT_FLIP : UVT,true,true);
         face.bitmapFill_.repeat = true;
         this.faces_.push(face);
      }
   }
}
