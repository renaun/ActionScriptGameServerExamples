package com.renaun.spelltraction.nerves
{
	import avmplus.ClientSocket;
	import avmplus.ServerSocket;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;

public class SocketServerNerveDispatcher implements INerveDispatcher
{
	public function SocketServerNerveDispatcher()
	{
	}

	private var receiveFunction:Function;

	private var sendBuffer:ByteArray;
	
	private var clientSockets:Dictionary = new Dictionary(true);
	
	private var server:ServerNerveSystem;
	private var serverSocket:ServerSocket;
	
	public function createServerSocket(server:ServerNerveSystem):ServerSocket
	{
		this.server = server;
		serverSocket = new ServerSocket(connectHandler);
		serverSocket.data.add(socketDataHandler);
		serverSocket.error.add(errorHandler);
		return serverSocket;
	}
	
	public function errorHandler(client:ClientSocket, error:int):void
	{
		if (error != 11)
			trace("SOCKET ERROR: " + error);
	}
	
	public function socketDataHandler(client:ClientSocket, bytes:ByteArray):void
	{
		//trace("received bytes[fd="+client.id+"]: " + bytes.length);
		receiveFunction(client.id, bytes);
	}
	
	public function connectHandler(client:ClientSocket, connect:Boolean):void
	{
		
		if (connect)
		{
			var id:int = server.getNewID();
			clientSockets[id] = client;
			trace("connectHandler: " + id + " fd: " + client.id);
			server.accept(client.id, id);
		}
		else
		{
			var c:ClientSocket;
			for (var key:String in clientSockets)
			{
				c = clientSockets[key];
				if (c == client)
					break;
			}
			trace("disconnecting... " + key);
			server.disconnect(int(key), client.id);
			clientSockets[key] = null;
			delete clientSockets[key];
		}
	}
	
	public function sendMessage(msg:ByteArray, sendTo:int = -1):void
	{
		//trace("sendMessage: " + sendTo + " - " + msg.length);
		if (sendTo == -1) // Broadcast
		{
			
			//trace("sendMessage22: " + msg.readByte());
			msg.position = 0;
			serverSocket.sendToAll(msg);
		}
		else
		{
			if (!clientSockets[sendTo])
				return;
			msg.position = 0;
			//trace("sendMessage33: " + msg.readByte());
			msg.position = 0;
			var fileDescriptor:int = (clientSockets[sendTo] as ClientSocket).id;
			
			//trace("Send msg to " + sendTo + " - " + fileDescriptor);
			var r:int = serverSocket.send(fileDescriptor, msg);
			//trace("SendREsponse: " + r);
		}
	}
	
	public function setReceiveHandler(receiveFunction:Function):void
	{
		this.receiveFunction = receiveFunction;
	}
	
	public function connect(ip:String, port:int):void
	{
		
	}
}
}