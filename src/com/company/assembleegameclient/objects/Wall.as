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
         if(this.wallSize_ > 1)
         {
            // Sort by bottom-right edge so wall draws AFTER objects in front of it
            posW_.length = 0;
            posW_.push(x_ + wallSize_, y_ + wallSize_, 0, x_ + wallSize_, y_ + wallSize_, z_);
            posS_.length = 0;
            camera.wToS_.transformVectors(posW_, posS_);
            sortVal_ = int(posS_[1]);
         }
         else
         {
            super.computeSortVal(camera);
         }
      }

      // Check if ALL tiles along a face edge are blocked by walls
      private function isEdgeBlocked(faceIndex:int) : Boolean
      {
         var s:int = this.wallSize_;
         var xi:int = x_;
         var yi:int = y_;
         var sq:Square = null;
         var i:int;

         switch(faceIndex)
         {
            case 0: // North face — check tiles at y-1, from x to x+s-1
               for(i = 0; i < s; i++)
               {
                  sq = map_.lookupSquare(xi + i, yi - 1);
                  if(sq == null || sq.obj_ == null || !(sq.obj_ is Wall) || sq.obj_.dead_)
                     return false;
               }
               return true;
            case 1: // East face — check tiles at x+s, from y to y+s-1
               for(i = 0; i < s; i++)
               {
                  sq = map_.lookupSquare(xi + s, yi + i);
                  if(sq == null || sq.obj_ == null || !(sq.obj_ is Wall) || sq.obj_.dead_)
                     return false;
               }
               return true;
            case 2: // South face — check tiles at y+s, from x to x+s-1
               for(i = 0; i < s; i++)
               {
                  sq = map_.lookupSquare(xi + i, yi + s);
                  if(sq == null || sq.obj_ == null || !(sq.obj_ is Wall) || sq.obj_.dead_)
                     return false;
               }
               return true;
            case 3: // West face — check tiles at x-1, from y to y+s-1
               for(i = 0; i < s; i++)
               {
                  sq = map_.lookupSquare(xi - 1, yi + i);
                  if(sq == null || sq.obj_ == null || !(sq.obj_ is Wall) || sq.obj_.dead_)
                     return false;
               }
               return true;
         }
         return false;
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
            // Multi-tile wall: check edges for wall culling AND player proximity
            var px:Number = map_.player_.x_;
            var py:Number = map_.player_.y_;
            var s:int = this.wallSize_;
            for(var mf:int = 0; mf < this.faces_.length; mf++)
            {
               face = this.faces_[mf];
               if(this.isEdgeBlocked(mf))
               {
                  face.blackOut_ = true;
               }
               else
               {
                  // Hide face if player is touching that edge
                  var hideForPlayer:Boolean = false;
                  switch(mf)
                  {
                     case 0: // North face — player at y-1, within x range
                        if(py >= y_ - 1 && py < y_ && px >= x_ - 0.5 && px < x_ + s + 0.5)
                           hideForPlayer = true;
                        break;
                     case 1: // East face — player at x+s, within y range
                        if(px >= x_ + s && px < x_ + s + 1 && py >= y_ - 0.5 && py < y_ + s + 0.5)
                           hideForPlayer = true;
                        break;
                     case 2: // South face — player at y+s, within x range
                        if(py >= y_ + s && py < y_ + s + 1 && px >= x_ - 0.5 && px < x_ + s + 0.5)
                           hideForPlayer = true;
                        break;
                     case 3: // West face — player at x-1, within y range
                        if(px >= x_ - 1 && px < x_ && py >= y_ - 0.5 && py < y_ + s + 0.5)
                           hideForPlayer = true;
                        break;
                  }
                  face.blackOut_ = hideForPlayer;
                  if(!hideForPlayer && animations_ != null)
                  {
                     face.setTexture(texture);
                  }
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
         // Top face at z=s, spanning s×s tiles
         var vin:Vector.<Number> = new <Number>[xi,yi,s, xi+s,yi,s, xi+s,yi+s,s, xi,yi+s,s];
         this.topFace_ = new Face3D(this.topTexture_,vin,UVT,false,true);
         this.topFace_.bitmapFill_.repeat = true;
         // 4 side faces, each s tiles wide and s tiles tall
         this.addWall(xi,yi,s, xi+s,yi,s);
         this.addWall(xi+s,yi,s, xi+s,yi+s,s);
         this.addWall(xi+s,yi+s,s, xi,yi+s,s);
         this.addWall(xi,yi+s,s, xi,yi,s);
      }

      private function addWall(x0:Number, y0:Number, z0:Number, x1:Number, y1:Number, z1:Number) : void
      {
         var s:int = this.wallSize_;
         var vin:Vector.<Number> = new <Number>[x0,y0,z0,x1,y1,z1,x1,y1,z1 - s,x0,y0,z0 - s];
         var face:Face3D = new Face3D(texture_,vin,UVT,true,true);
         face.bitmapFill_.repeat = true;
         this.faces_.push(face);
      }
   }
}
