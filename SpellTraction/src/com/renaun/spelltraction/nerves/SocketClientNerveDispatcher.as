package com.renaun.spelltraction.nerves
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.Socket;
	import flash.system.Security;
	import flash.utils.ByteArray;

public class SocketClientNerveDispatcher implements INerveDispatcher
{
	public function SocketClientNerveDispatcher()
	{
	}
	
	private var receiveFunction:Function;
	private var socket:Socket;

	private var receiveBuffer:ByteArray;
	
	public function sendMessage(msg:ByteArray, sendTo:int = -1):void
	{
		if (!socket.connected)
			return;
		out("sent message: " + msg.bytesAvailable);
		socket.writeBytes(msg);
		socket.flush();
	}
	
	public function setReceiveHandler(receiveFunction:Function):void
	{
		this.receiveFunction = receiveFunction;
	}
	
	public function connect(ip:String, port:int):void
	{
		try
		{
			receiveBuffer = new ByteArray();
			Security.loadPolicyFile("xmlsocket://"+ip+":8843");
			socket = new Socket();
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.addEventListener(Event.CONNECT, connectHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityHandler);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketData);
			socket.addEventListener(Event.CLOSE, connectHandler);
			socket.connect(ip, port);
		}
		catch (error:Error)
		{
			out("error: " + error.message);
		}
	}	
	
	protected function socketData(event:ProgressEvent):void
	{
		// TODO Auto-generated method stub
		out("Progress: " + event.type + " - " + socket.bytesAvailable);
		receiveBuffer.clear();
		socket.readBytes(receiveBuffer);
		receiveFunction(receiveBuffer);
	}
	
	protected function securityHandler(event:SecurityErrorEvent):void
	{
		// TODO Auto-generated method stub
		
		// TODO Auto-generated method stub
		out("Security: "+ event.text);
	}
	
	protected function connectHandler(event:Event):void
	{
		// TODO Auto-generated method stub
		out("Connected:" + event.type);
		//socket.writeUTFBytes("HELLO;" + String.fromCharCode(0) );
		//socket.flush();
	}
	
	protected function ioErrorHandler(event:IOErrorEvent):void
	{
		// TODO Auto-generated method stub
		out("ioError: "+ event.text);
	}
	
	private function out(msg:String):void
	{
		// TODO Auto Generated method stub
		trace("[SocketNerveDispatcher]"+msg + "\n");
	}
}
}