package
{
import com.renaun.spelltraction.brain.ClientBrain;
import com.renaun.spelltraction.heart.Heartbeat;
import com.renaun.spelltraction.nerves.ClientNerveSystem;
import com.renaun.spelltraction.nerves.LocalNerveDispatcher;
import com.renaun.spelltraction.nerves.SocketClientNerveDispatcher;

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
public class SpellTractionSocket extends Sprite
{

	public function SpellTractionSocket()
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
	}
	
	private function test():void
	{
		// TEST CODE 
		// Create test users first then real client user
		//serverBrain.addUser(1001, 1, 0xff0000);
		//serverBrain.addUser(1002, 1, 0xff0000);
		// serverBrain.addUser(1001, 1, 0xff0000);
		
		//serverBrain.addUser(1, 1, 0xffffff);
		//clientBrain.connect("127.0.0.1", 12122, 1, 0x0033ff);
		//clientBrain.connect("ec2-50-16-78-175.compute-1.amazonaws.com", 12122, 1, 0xFF0000);
		clientBrain.connect("ec2-50-17-145-21.compute-1.amazonaws.com", 12122, 1, 0x0000ff);
		
		
		trace("wL: " + clientBrain.clientUser.appID + " - " + clientBrain.clientUser.wordList);
	}
	private var skinHeart:Heartbeat;
	private var clientNerveSystem:ClientNerveSystem;
	
	private var clientBrain:ClientBrain;
	private var socketDispatcher:SocketClientNerveDispatcher;
	
	
	protected function setup():void
	{
		socketDispatcher = new SocketClientNerveDispatcher();
		
		skinHeart = new Heartbeat(30);
		
		clientBrain = new ClientBrain(stage);
		var clientNerve:ClientNerveSystem = new ClientNerveSystem(clientBrain, socketDispatcher);
		
		clientBrain.addNerve(clientNerve);
		skinHeart.addBeatables(clientBrain);
		
		skinHeart.start(stage);
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