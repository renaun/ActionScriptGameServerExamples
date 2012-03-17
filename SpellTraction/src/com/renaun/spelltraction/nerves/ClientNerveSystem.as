package com.renaun.spelltraction.nerves
{
	import com.renaun.spelltraction.brain.BrainCommands;
	import com.renaun.spelltraction.brain.ClientBrain;
	import com.renaun.spelltraction.data.UserData;
	
	import flash.utils.ByteArray;

public class ClientNerveSystem
{
	public static const COMMAND_ADD_USER:int = 0x01;
	
	public function ClientNerveSystem(clientBrain:ClientBrain, dispatcher:INerveDispatcher)
	{
		this.clientBrain = clientBrain;
		this.dispatcher = dispatcher;
		this.dispatcher.setReceiveHandler(receiveHandler);
		if (!receiveBuffer1)
			receiveBuffer1 = new ByteArray();
		if (!receiveBuffer2)
			receiveBuffer2 = new ByteArray();
		receiveBuffer = receiveBuffer1;
		if (!sendBuffer)
			sendBuffer = new ByteArray();
	}
	private var clientBrain:ClientBrain;
	private var dispatcher:INerveDispatcher;
	
	private var receiveBuffer:ByteArray;
	private var receiveBuffer1:ByteArray;
	private var receiveBuffer2:ByteArray;
	private var receiveIsOne:Boolean = true;
	private var sendBuffer:ByteArray; 
	
	public function receiveHandler(incomingBytes:ByteArray):void
	{
		var commandType:int = 0;
		var id:int = 0;
		var len:int = 0;
		var shape:int = 0;
		var color:int = 0;
		var xPos:int = 0;
		var yPos:int = 0;
		
		receiveBuffer.position = receiveBuffer.length;
		incomingBytes.readBytes(receiveBuffer, receiveBuffer.length);

		var readable:Boolean = receiveBuffer.bytesAvailable > 1;
		//trace(bytes.length + " - " + bytes.bytesAvailable);
		if (!readable)
			return;
		while(readable)
		{
			commandType = receiveBuffer.readByte();
			trace("CLIENT RECEIVE: " + commandType + " - " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable);
			switch (commandType)
			{
				case BrainCommands.ACCEPT_RESPONSE:
					if (receiveBuffer.bytesAvailable < 2)
					{
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readUnsignedShort();
					clientBrain.accepted(id);
					break;
				case BrainCommands.USER_LETTERS:
					len = receiveBuffer.readByte();
					if (receiveBuffer.bytesAvailable < len)
					{
						receiveBuffer.position -= 2;
						readable = false;
						break;
					}
					var wordList:String = receiveBuffer.readUTFBytes(len);
					clientBrain.setWordList(wordList);
					break;
				case BrainCommands.ATTRACTOR_INFO:
					if (receiveBuffer.bytesAvailable < 11)
					{
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readUnsignedShort();
					shape = receiveBuffer.readByte();
					color = receiveBuffer.readUnsignedInt();
					xPos = receiveBuffer.readUnsignedShort();
					yPos = receiveBuffer.readUnsignedShort();
					clientBrain.addAttractor(id, shape, color, xPos, yPos);
					break;
				case BrainCommands.USER_LOCATIONS:
					//trace("Number of USER_LOCATIONS " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable);
					if (receiveBuffer.bytesAvailable < 6)
					{
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readUnsignedShort();
					xPos = receiveBuffer.readUnsignedShort();
					yPos = receiveBuffer.readUnsignedShort();
					clientBrain.changeUserPosition(id, xPos, yPos);
					break;
				case BrainCommands.USER_CHANGES:
					//trace("Number of USER_CHANGES " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable);
					var addRemove:int = 0;
					if (receiveBuffer.bytesAvailable < 8)
					{
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readUnsignedShort();
					//trace("adding: " + id);
					addRemove = receiveBuffer.readByte();
					shape = receiveBuffer.readByte();
					color = receiveBuffer.readUnsignedInt();
						
					if (addRemove == 1)
					{
						clientBrain.addUser(id, shape, color);
					}
					if (addRemove != 1)
						clientBrain.removeUser(id);
				
					break;
				default:
					
					readable = false;
					break;
			}
			readable = readable && receiveBuffer.bytesAvailable > 1;
		}
		// if true read remain bytes into receiveBuffer2 and set that as new buffer
		if (receiveIsOne)
		{
			receiveIsOne = !receiveIsOne;
			receiveBuffer2.readBytes(receiveBuffer, 0, receiveBuffer.bytesAvailable);
			receiveBuffer = receiveBuffer2;
			receiveBuffer1.clear();
		}
		else
		{
			receiveIsOne = !receiveIsOne;
			receiveBuffer1.readBytes(receiveBuffer, 0, receiveBuffer.bytesAvailable);
			receiveBuffer = receiveBuffer1;
			receiveBuffer2.clear();
		}
	}
	
	public function connect(ip:String, port:int):void
	{
		//sendBuffer.clear();
		//sendBuffer.writeByte(BrainCommands.USER_CONNECT);
		dispatcher.connect(ip, port);
	}
	
	public function joinGame(user:UserData):void
	{
		
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.USER_JOIN_GAME);
		sendBuffer.writeShort(user.appID);
		sendBuffer.writeByte(user.shape);
		sendBuffer.writeUnsignedInt(user.color);
		dispatcher.sendMessage(sendBuffer);
	}
	
	public function move(user:UserData):void
	{
		
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.USER_LOCATION);
		sendBuffer.writeShort(user.appID);
		sendBuffer.writeShort(user.xPos);
		sendBuffer.writeShort(user.yPos);
		dispatcher.sendMessage(sendBuffer);
	}
}
}