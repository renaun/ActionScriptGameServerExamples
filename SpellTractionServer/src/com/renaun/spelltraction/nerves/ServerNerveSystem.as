package com.renaun.spelltraction.nerves
{
import com.renaun.spelltraction.brain.BrainCommands;
import com.renaun.spelltraction.brain.ServerBrain;
import com.renaun.spelltraction.data.UserData;

import flash.utils.ByteArray;
import flash.utils.Dictionary;

public class ServerNerveSystem implements IServerNerveSystem
{
	
	
	public function ServerNerveSystem(serverBrain:ServerBrain, dispatcher:INerveDispatcher)
	{
		this.serverBrain = serverBrain;
		this.dispatcher = dispatcher;
		this.dispatcher.setReceiveHandler(receiveHandler);
		if (!receiveBuffer)
			receiveBuffer = new ByteArray();
		if (!sendBuffer)
			sendBuffer = new ByteArray();
		if (!newUserBuffer)
			newUserBuffer = new ByteArray();
		if (!newLocationsBuffer)
			newLocationsBuffer = new ByteArray();
	}
	
	private var serverBrain:ServerBrain;
	private var dispatcher:INerveDispatcher;
	private var waitingForMoreBytes:Boolean = false;
	
	private var receiveBuffer:ByteArray;
	private var sendBuffer:ByteArray;
	private var newUserCount:int = 0;
	private var newUserBuffer:ByteArray;
	private var newLocationsCount:int = 0;
	private var newLocationsBuffer:ByteArray;
	
	
	private var clientAppIDs:Dictionary = new Dictionary(true);
	
	public function getNewID():int
	{
		return serverBrain.getNewID();
	}
	
	public function accept(fd:int, id:int = -1):void
	{
		if (id == -1)
			id = serverBrain.getNewID();
		clientAppIDs[fd] = id;
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.ACCEPT_RESPONSE);
		sendBuffer.writeShort(id);
		//trace("NerveSendAcceptMessage: " + id);
		dispatcher.sendMessage(sendBuffer, id);
	}
	
	public function disconnect(appID:int, fd:int):void
	{
		serverBrain.removeUser(appID);
		clientAppIDs[fd] = null;
		delete clientAppIDs[fd];
	}
	
	public function receiveHandler(fd:int, bytes:ByteArray):void
	{
		// look at bytes, have a game schema?
		bytes.position = 0;
		var commandType:int = bytes.readByte();
		var readable:Boolean = bytes.bytesAvailable > 0;
		var id:int = 0;
		//trace("RECEIVED: " + commandType);
		switch (commandType)
		{
			case BrainCommands.USER_JOIN_GAME:
				id = bytes.readUnsignedShort();
				if (clientAppIDs[fd] != id)
					id = clientAppIDs[fd];
				var shape:int = bytes.readByte();
				var color:int = bytes.readUnsignedInt();
				serverBrain.addUser(id, shape, color);
				break;
			case BrainCommands.USER_LOCATION:
				id = bytes.readUnsignedShort();
				if (clientAppIDs[fd] != id)
					id = clientAppIDs[fd];
				var xPos:int = bytes.readUnsignedShort();
				var yPos:int = bytes.readUnsignedShort();
				serverBrain.userLocation(id, xPos, yPos);
				break;
		}
		
	}
	
	public function sendUserLetters(wordList:String, sendTo:int):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.USER_LETTERS);
		sendBuffer.writeByte(wordList.length);
		sendBuffer.writeUTFBytes(wordList);
		dispatcher.sendMessage(sendBuffer, sendTo);
	}
	
	public function sendAttractorInfo(attractor:UserData, sendTo:int):void
	{
		sendBuffer.clear();
		sendBuffer.writeByte(BrainCommands.ATTRACTOR_INFO);
		sendBuffer.writeShort(attractor.appID);
		sendBuffer.writeByte(attractor.shape);
		sendBuffer.writeUnsignedInt(attractor.color);
		sendBuffer.writeShort(attractor.xPos);
		sendBuffer.writeShort(attractor.yPos);
		dispatcher.sendMessage(sendBuffer, sendTo);
	}
	
	//======= Batch Methods =======//
	
	public function sendUserChange(user:UserData, addDelete:int = 1, forceSend:Boolean = false, sendTo:int = -1):void
	{
		// Limit bytes sent
		if (forceSend)
		{
			if (newUserBuffer.length > 0)
			{
				trace("sendUserChange::forceSend - " + newUserBuffer.length);
				dispatcher.sendMessage(newUserBuffer, sendTo);
				newUserBuffer.clear();
			}
			if (forceSend)
				return;
		}
		
		// 1 byte - command
		// 1 byte - number of user changes
		// 1 short - id
		// 1 byte - Add = 1 , Delete = -1
		// 1 byte - shape
		// 1 unsigned int - color
		newUserBuffer.writeByte(BrainCommands.USER_CHANGES);
		newUserBuffer.writeShort(user.appID);
		newUserBuffer.writeByte(addDelete);
		newUserBuffer.writeByte(user.shape);
		newUserBuffer.writeUnsignedInt(user.color);
	}
	
	
	public function sendUserLocation(user:UserData, forceSend:Boolean = false):void
	{
		// Limit bytes sent
		if (forceSend)
		{
			if (newLocationsBuffer.length > 0)
			{
				dispatcher.sendMessage(newLocationsBuffer);
				newLocationsBuffer.clear();
			}
			if (forceSend)
				return;
		}
		// 1 byte - command
		// 1 byte - number of user changes
		// 1 short - id
		// 1 short - xPos
		// 1 short - yPos
		newLocationsBuffer.writeByte(BrainCommands.USER_LOCATIONS);
		newLocationsBuffer.writeShort(user.appID);
		newLocationsBuffer.writeShort(user.xPos);
		newLocationsBuffer.writeShort(user.yPos);
	}
}
}