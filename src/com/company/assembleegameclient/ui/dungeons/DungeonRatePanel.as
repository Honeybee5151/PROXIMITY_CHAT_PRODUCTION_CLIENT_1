package com.company.assembleegameclient.ui.dungeons
{
import com.company.assembleegameclient.ui.TextButton;
import com.company.ui.SimpleText;

import flash.display.Graphics;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.filters.DropShadowFilter;
import flash.net.URLLoader;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;
import flash.net.URLVariables;

import kabam.rotmg.account.core.Account;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.application.api.ApplicationSetup;

public class DungeonRatePanel extends Sprite
{
    private static const PANEL_W:int = 300;
    private static const PANEL_H:int = 200;

    private var data_:Object;
    private var browser_:DungeonBrowser;
    private var liked_:Boolean = false;
    private var diffInput_:SimpleText;
    private var likeBtn_:TextButton;
    private var submitBtn_:TextButton;
    private var cancelBtn_:TextButton;
    private var errorText_:SimpleText;

    public function DungeonRatePanel(data:Object, browser:DungeonBrowser)
    {
        super();
        this.data_ = data;
        this.browser_ = browser;

        // Background
        var g:Graphics = this.graphics;
        g.beginFill(0x1a1a2e, 1);
        g.lineStyle(2, 0x5a5a8c);
        g.drawRoundRect(0, 0, PANEL_W, PANEL_H, 10, 10);
        g.endFill();

        // Title
        var title:SimpleText = new SimpleText(18, 0xFFFFFF, false, PANEL_W, 0);
        title.setBold(true);
        title.htmlText = "<p align=\"center\">Rate: " + data.name + "</p>";
        title.filters = [new DropShadowFilter(0, 0, 0, 1, 2, 2)];
        title.updateMetrics();
        title.y = 12;
        addChild(title);

        // Difficulty label
        var diffLabel:SimpleText = new SimpleText(14, 0xCCCCCC, false, 0, 0);
        diffLabel.text = "Difficulty (1-10):";
        diffLabel.updateMetrics();
        diffLabel.x = 20;
        diffLabel.y = 52;
        addChild(diffLabel);

        // Difficulty input field background
        var inputBg:Sprite = new Sprite();
        inputBg.graphics.beginFill(0x0f0f1e, 1);
        inputBg.graphics.lineStyle(1, 0x3a3a5c);
        inputBg.graphics.drawRoundRect(170, 48, 50, 26, 6, 6);
        inputBg.graphics.endFill();
        addChild(inputBg);

        // Difficulty text input
        this.diffInput_ = new SimpleText(14, 0xFFFFFF, true, 40, 20);
        this.diffInput_.x = 175;
        this.diffInput_.y = 51;
        this.diffInput_.border = false;
        this.diffInput_.background = true;
        this.diffInput_.backgroundColor = 0x0f0f1e;
        this.diffInput_.maxChars = 2;
        this.diffInput_.restrict = "0-9";
        this.diffInput_.tabEnabled = false;
        addChild(this.diffInput_);

        // Like label + button
        var likeLabel:SimpleText = new SimpleText(14, 0xCCCCCC, false, 0, 0);
        likeLabel.text = "Like this dungeon?";
        likeLabel.updateMetrics();
        likeLabel.x = 20;
        likeLabel.y = 95;
        addChild(likeLabel);

        this.likeBtn_ = new TextButton(16, "\u2665 No", 80);
        this.likeBtn_.x = 170;
        this.likeBtn_.y = 90;
        this.likeBtn_.addEventListener(MouseEvent.CLICK, this.onLikeToggle);
        addChild(this.likeBtn_);

        // Error text (hidden by default)
        this.errorText_ = new SimpleText(12, 0xFF4444, false, PANEL_W, 0);
        this.errorText_.htmlText = "";
        this.errorText_.updateMetrics();
        this.errorText_.y = 125;
        this.errorText_.visible = false;
        addChild(this.errorText_);

        // Submit
        this.submitBtn_ = new TextButton(14, "Submit", 80);
        this.submitBtn_.x = PANEL_W / 2 - 90;
        this.submitBtn_.y = PANEL_H - 45;
        this.submitBtn_.addEventListener(MouseEvent.CLICK, this.onSubmit);
        addChild(this.submitBtn_);

        // Cancel
        this.cancelBtn_ = new TextButton(14, "Cancel", 80);
        this.cancelBtn_.x = PANEL_W / 2 + 10;
        this.cancelBtn_.y = PANEL_H - 45;
        this.cancelBtn_.addEventListener(MouseEvent.CLICK, this.onCancel);
        addChild(this.cancelBtn_);
    }

    private function onLikeToggle(e:MouseEvent):void
    {
        this.liked_ = !this.liked_;
        this.likeBtn_.setText(this.liked_ ? "\u2665 Yes" : "\u2665 No");
    }

    private function onSubmit(e:MouseEvent):void
    {
        var diffVal:int = parseInt(this.diffInput_.text);

        if (isNaN(diffVal) || diffVal < 1 || diffVal > 10)
        {
            this.errorText_.htmlText = "<p align=\"center\">Enter a number between 1 and 10</p>";
            this.errorText_.updateMetrics();
            this.errorText_.visible = true;
            return;
        }

        this.errorText_.visible = false;

        var setup:ApplicationSetup = StaticInjectorContext.getInjector().getInstance(ApplicationSetup);
        var account:Account = StaticInjectorContext.getInjector().getInstance(Account);
        var url:String = setup.getAppEngineUrl() + "/dungeons/rate";

        var vars:URLVariables = new URLVariables();
        vars.guid = account.getUserId();
        vars.password = account.getPassword();
        vars.dungeonName = this.data_.name;
        vars.difficulty = String(diffVal);
        vars.liked = this.liked_ ? "true" : "false";

        var request:URLRequest = new URLRequest(url);
        request.method = URLRequestMethod.POST;
        request.data = vars;

        var loader:URLLoader = new URLLoader();
        var self:DungeonRatePanel = this;
        loader.addEventListener(Event.COMPLETE, function(e:Event):void {
            self.browser_.onRateComplete();
        });
        loader.addEventListener("ioError", function(e:Event):void {
            self.errorText_.htmlText = "<p align=\"center\">Network error - try again</p>";
            self.errorText_.updateMetrics();
            self.errorText_.visible = true;
        });
        loader.addEventListener("securityError", function(e:Event):void {
            self.errorText_.htmlText = "<p align=\"center\">Security error - try again</p>";
            self.errorText_.updateMetrics();
            self.errorText_.visible = true;
        });
        loader.load(request);
    }

    private function onCancel(e:MouseEvent):void
    {
        this.browser_.onRateComplete();
    }
}
}
