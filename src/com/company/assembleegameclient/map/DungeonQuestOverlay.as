package com.company.assembleegameclient.map
{
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFieldAutoSize;
    import flash.filters.DropShadowFilter;
    import flash.filters.GlowFilter;

    public class DungeonQuestOverlay extends Sprite
    {
        private var label_:TextField;
        private var questText_:TextField;

        public function DungeonQuestOverlay()
        {
            super();
            this.visible = false;

            // "Quest:" label
            var labelFmt:TextFormat = new TextFormat();
            labelFmt.font = "Myriad Pro";
            labelFmt.size = 16;
            labelFmt.color = 0xFFD700;
            labelFmt.bold = true;

            label_ = new TextField();
            label_.defaultTextFormat = labelFmt;
            label_.embedFonts = true;
            label_.selectable = false;
            label_.autoSize = TextFieldAutoSize.LEFT;
            label_.text = "Quest:";
            label_.filters = [new DropShadowFilter(1, 45, 0x000000, 1, 2, 2)];
            addChild(label_);

            // Quest text
            var textFmt:TextFormat = new TextFormat();
            textFmt.font = "Myriad Pro";
            textFmt.size = 15;
            textFmt.color = 0xFFFFFF;
            textFmt.bold = false;

            questText_ = new TextField();
            questText_.defaultTextFormat = textFmt;
            questText_.embedFonts = true;
            questText_.selectable = false;
            questText_.autoSize = TextFieldAutoSize.LEFT;
            questText_.x = label_.textWidth + 8;
            questText_.filters = [new DropShadowFilter(1, 45, 0x000000, 1, 2, 2)];
            addChild(questText_);
        }

        public function show(text:String):void
        {
            questText_.text = "\"" + text + "\"";
            this.visible = true;
        }

        public function hide():void
        {
            this.visible = false;
        }
    }
}
