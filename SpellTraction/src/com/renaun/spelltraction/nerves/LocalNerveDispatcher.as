package com.renaun.spelltraction.nerves
{
import flash.utils.ByteArray;

public class LocalNerveDispatcher implements INerveDispatcher
{
	public function LocalNerveDispatcher(isClient:Boolean = true)
	{
		this.client = client;
		this.server = server;
		this.isClient = isClient;
	}
	
	private var receiveFunction:Function;
	private var client:ClientNerveSystem;
	private var server:IServerNerveSystem;
	private var isClient:Boolean;
	
	public function setNerves(client:ClientNerveSystem, server:IServerNerveSystem):void
	{
		
		this.client = client;
		this.server = server;
	}
	
	public function sendMessage(msg:ByteArray, sendTo:int = -1):void
	{
		if (isClient)
			server.receiveHandler(msg);
		else
			client.receiveHandler(msg);
	}
	
	public function setReceiveHandler(receiveFunction:Function):void
	{
		receiveFunction = receiveFunction;
	}
	
	public function connect(ip:String, port:int):void
	{
		server.accept();
	}
}
}