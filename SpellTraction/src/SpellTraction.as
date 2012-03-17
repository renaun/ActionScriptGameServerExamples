package
{
import com.renaun.spelltraction.brain.ClientBrain;
import com.renaun.spelltraction.brain.ServerBrain;
import com.renaun.spelltraction.heart.Heartbeat;
import com.renaun.spelltraction.nerves.ClientNerveSystem;
import com.renaun.spelltraction.nerves.LocalNerveDispatcher;
import com.renaun.spelltraction.nerves.ServerNerveSystem;

import flash.display.Sprite;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.MouseEvent;

/**
 * 	Brain - server
 * 	CommHub - shim for communication
 * 	Client - Input interaction and Rendering
 */
[SWF(width="640", height="480", backgroundColor="#f2f2f2")]
public class SpellTraction extends Sprite
{

	public function SpellTraction()
	{
		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		setup();
		test();
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseHandler);
	}
	
	protected function mouseHandler(event:MouseEvent):void
	{
		// TODO Auto-generated method stub
		trace(event.localX + " - " + event.localY);
		clientBrain.move(event.localX, event.localY);
		
		// TEST CODE
		//serverBrain.addUser(1001, 1, 0xff0000);
		serverBrain.userLocation(1001, event.localX+100, event.localY);
		serverBrain.userLocation(1002, event.localX+10, event.localY);
	}
	
	private function test():void
	{
		// TEST CODE 
		// Create test users first then real client user
		serverBrain.addUser(1001, 1, 0xff0000);
		serverBrain.addUser(1002, 1, 0xff0000);
		// serverBrain.addUser(1001, 1, 0xff0000);
		
		//serverBrain.addUser(1, 1, 0xffffff);
		clientBrain.connect("127.0.0.1", 12122, 1, 0x0033ff);

		trace("wL: " + clientBrain.clientUser.id + " - " + clientBrain.clientUser.wordList);
	}
	private var skinHeart:Heartbeat;
	private var serverHeart:Heartbeat;

	private var serverBrain:ServerBrain;

	private var serverNerve:ServerNerveSystem;

	private var clientBrain:ClientBrain;
	private var localClientDispatcher:LocalNerveDispatcher;
	private var localServerDispatcher:LocalNerveDispatcher;
	
	protected function setup():void
	{
		localClientDispatcher = new LocalNerveDispatcher();
		localServerDispatcher = new LocalNerveDispatcher(false);
		
		skinHeart = new Heartbeat(10);
		serverHeart = new Heartbeat(5);
		
		serverBrain = new ServerBrain();
		serverNerve = new ServerNerveSystem(serverBrain, localServerDispatcher);
		
		clientBrain = new ClientBrain(stage);
		var clientNerve:ClientNerveSystem = new ClientNerveSystem(clientBrain, localClientDispatcher);
		
		localClientDispatcher.setNerves(clientNerve, serverNerve);
		localServerDispatcher.setNerves(clientNerve, serverNerve);
		
		serverBrain.addNerve(serverNerve);
		serverHeart.addBeatables(serverBrain);
		clientBrain.addNerve(clientNerve);
		skinHeart.addBeatables(clientBrain);
		
		skinHeart.start(stage);
		serverHeart.start();
	}
	
	
	/*
		Socket Handshake
			Client: Makes connection
			Server: Accepts and returns ACK with client id
	
		User Joins
			Client: User selects shape and color
				- shell UserData is created, ClientBrain.connect() is called
				- ServerBrain accepts
				- ServerBrain sends UserData id
				- ClientBrain joinsGame with id, shape, color
				- ClientBrain sendsPosition with x,y
	
	
	*/
}
}