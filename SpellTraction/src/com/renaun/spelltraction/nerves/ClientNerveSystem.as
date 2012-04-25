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
		if (clientBrain)
			trace(" ADDED: " + clientBrain.kk + " kk2: " + clientBrain.kk2);
		trace("RECEIVE[receiveBuffer]: " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable + " - " + receiveBuffer.position);
		trace("RECEIVE[incoming]: " + incomingBytes.length + " - " + incomingBytes.bytesAvailable);
		receiveBuffer.position = receiveBuffer.length;
		incomingBytes.readBytes(receiveBuffer, receiveBuffer.length);
		receiveBuffer.position = 0;
		trace("RECEIVE[receiveBuffer2]: " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable + " - " + receiveBuffer.position);
		

		var readable:Boolean = receiveBuffer.bytesAvailable > 1;
		//trace(bytes.length + " - " + bytes.bytesAvailable);
		if (!readable)
			return;
		while(readable)
		{
			commandType = receiveBuffer.readByte();
			//if (commandType != 10 && commandType!= 11)
			trace("CLIENT RECEIVE: " + commandType + " - " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable + " - " + receiveBuffer.position);
			switch (commandType)
			{
				case BrainCommands.ACCEPT_RESPONSE:
					if (receiveBuffer.bytesAvailable < 2)
					{
						trace("REC_BYTERUNOUT - ACCEPT_RESPONE");
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readUnsignedShort();
					clientBrain.accepted(id);
					break;
				case BrainCommands.SCORE_NEW_LETTER:
					if (receiveBuffer.bytesAvailable < 4)
					{
						trace("REC_BYTERUNOUT - SCORE_NEW_LETTER");
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					clientBrain.scoreWordList(receiveBuffer.readUnsignedShort(), receiveBuffer.readUTFBytes(1), receiveBuffer.readUTFBytes(1));
					break;
				case BrainCommands.STATS_UPDATE:
					if (receiveBuffer.bytesAvailable < 16)
					{
						trace("REC_BYTERUNOUT - STATS_UPDATE");
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					clientBrain.setStats(receiveBuffer.readInt(), receiveBuffer.readFloat(), receiveBuffer.readFloat(), receiveBuffer.readFloat());
					trace("CLIENT RECEIVE: " + commandType + " - " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable + " - " + receiveBuffer.position);
					break;
				case BrainCommands.USER_LETTERS:
					len = receiveBuffer.readByte();
					if (receiveBuffer.bytesAvailable < len)
					{
						trace("REC_BYTERUNOUT - USER_LETTERS");
						receiveBuffer.position -= 2;
						readable = false;
						break;
					}
					var wordList:String = receiveBuffer.readUTFBytes(len);
					clientBrain.setWordList(wordList);
					break;
				case BrainCommands.GAME_LETTERS:
					len = receiveBuffer.readByte();
					if (receiveBuffer.bytesAvailable < len)
					{
						trace("REC_BYTERUNOUT - GAME_LETTERS");
						receiveBuffer.position -= 2;
						readable = false;
						break;
					}
					if (len > 0)
						clientBrain.setGameLetters(receiveBuffer.readUTFBytes(len));
					break;
				case BrainCommands.SCORE_LETTER:
					len = receiveBuffer.readByte(); // gridPosition
					if (receiveBuffer.bytesAvailable < 1)
					{
						trace("REC_BYTERUNOUT - SCORE_LETTER");
						receiveBuffer.position -= 2;
						readable = false;
						break;
					}
					clientBrain.scoreGameLetter(len, receiveBuffer.readUTFBytes(1));
					break;
				case BrainCommands.ATTRACTOR_INFO:
					if (receiveBuffer.bytesAvailable < 11)
					{
						trace("REC_BYTERUNOUT - ATTRACTOR_INFO");
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readShort();
					shape = receiveBuffer.readByte();
					color = receiveBuffer.readUnsignedInt();
					xPos = receiveBuffer.readShort();
					yPos = receiveBuffer.readShort();
					clientBrain.addAttractor(id, shape, color, xPos, yPos);
					break;
				case BrainCommands.USER_LOCATIONS:
					//trace("Number of USER_LOCATIONS " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable);
					if (receiveBuffer.bytesAvailable < 6)
					{
						trace("REC_BYTERUNOUT - USER_LOCATIONS");
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readShort();
					xPos = receiveBuffer.readShort();
					yPos = receiveBuffer.readShort();
					clientBrain.changeUserPosition(id, xPos, yPos);
					break;
				case BrainCommands.USER_CHANGES:
					//trace("Number of USER_CHANGES " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable);
					var addRemove:int = 0;
					if (receiveBuffer.bytesAvailable < 8)
					{
						trace("REC_BYTERUNOUT - USER_CHANGES available: " + receiveBuffer.bytesAvailable + " position: " + receiveBuffer.position);
						receiveBuffer.position -= 1;
						readable = false;
						break;
					}
					id = receiveBuffer.readShort();
					addRemove = receiveBuffer.readByte();
					shape = receiveBuffer.readByte();
					if (shape == 5) // Hack to change all non-server and self shapes to opponents
						shape = 1;
					color = receiveBuffer.readUnsignedInt();
					trace("UserChange: " + id + " shape: " + shape + " - " + addRemove + " - " + color + " pos: " + receiveBuffer.position);
					if (true || addRemove > 1 || addRemove < -1)
					{
						if (receiveBuffer.position > 16)
						{
						receiveBuffer.position -= 16;
						trace("Bytes[-16]: " + receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte());
						trace("Bytes[-8]: " + receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte());
						}
						if (receiveBuffer.bytesAvailable > 15)
						{
						trace("Bytes[0]: " + receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte());
						trace("Bytes[+8]: " + receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte() + ","
							+ receiveBuffer.readByte() + "," + receiveBuffer.readByte());
						receiveBuffer.position -= 16;
						}
					}
					if (addRemove == 1)
					{
						clientBrain.addUser(id, shape, color);
					}
					else if (addRemove != 1)
					{
						clientBrain.removeUser(id);
					}
				
					break;
				default:
					trace("DEFAULT COMMAND: " + commandType + " - " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable + " - " + receiveBuffer.position);
					//receiveBuffer.position -= 1;
					readable = true;
					break;
			}
			readable = readable && receiveBuffer.bytesAvailable > 1;
		}
		
		trace("RECEIVE[receiveBufferEND1]: " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable + " - " + receiveBuffer.position);
		if (receiveBuffer.bytesAvailable == 0)
		{
			receiveBuffer.clear();
			return;
		}
		else
		{
			;
		}
		// if true read remain bytes into receiveBuffer2 and set that as new buffer
		if (receiveIsOne)
		{
			receiveIsOne = !receiveIsOne;
			receiveBuffer.readBytes(receiveBuffer2, 0, receiveBuffer.bytesAvailable);
			receiveBuffer = receiveBuffer2;
			receiveBuffer1.clear();
		}
		else
		{
			receiveIsOne = !receiveIsOne;
			receiveBuffer.readBytes(receiveBuffer1, 0, receiveBuffer.bytesAvailable);
			receiveBuffer = receiveBuffer1;
			receiveBuffer2.clear();
		}
		
		trace("RECEIVE[receiveBufferEND2]: " + receiveBuffer.length + " - " + receiveBuffer.bytesAvailable);
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