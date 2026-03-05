package kabam.rotmg.ui.view
{
   import kabam.rotmg.account.core.Account;
   import kabam.rotmg.account.core.signals.OpenAccountInfoSignal;
   import kabam.rotmg.application.api.ApplicationSetup;
   import kabam.rotmg.core.model.PlayerModel;
   import kabam.rotmg.core.signals.SetScreenSignal;
   import kabam.rotmg.core.signals.SetScreenWithValidDataSignal;
   import kabam.rotmg.dialogs.control.OpenDialogSignal;
   import kabam.rotmg.ui.model.EnvironmentData;
   import kabam.rotmg.ui.signals.EnterGameSignal;
   import robotlegs.bender.bundles.mvcs.Mediator;

   //editor8182381 — CHANGED: simplified, only playClicked wired (click background to play)
   public class TitleMediator extends Mediator
   {
      [Inject]
      public var view:TitleView;

      [Inject]
      public var playerModel:PlayerModel;

      [Inject]
      public var setScreen:SetScreenSignal;

      [Inject]
      public var setScreenWithValidData:SetScreenWithValidDataSignal;

      [Inject]
      public var enterGame:EnterGameSignal;

      [Inject]
      public var openAccountInfo:OpenAccountInfoSignal;

      [Inject]
      public var account:Account; //editor8182381

      [Inject]
      public var openDialog:OpenDialogSignal;

      [Inject]
      public var setup:ApplicationSetup;

      public function TitleMediator()
      {
         super();
      }

      override public function initialize():void
      {
         this.view.initialize(this.makeEnvironmentData());
         this.view.playClicked.add(this.handleIntentionToPlay);
      }

      private function makeEnvironmentData():EnvironmentData
      {
         var data:EnvironmentData = new EnvironmentData();
         data.isAdmin = this.playerModel.isAdmin();
         data.buildLabel = this.setup.getBuildLabel();
         return data;
      }

      override public function destroy():void
      {
         this.view.playClicked.remove(this.handleIntentionToPlay);
      }

      private function handleIntentionToPlay():void
      {
         //editor8182381 — CHANGED: show login dialog if not registered, otherwise enter game
         if (!this.account.isRegistered())
         {
            this.openAccountInfo.dispatch();
         }
         else
         {
            this.enterGame.dispatch();
         }
      }
   }
}
