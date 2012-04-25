/* -*- c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4 -*- */
/* vi: set ts=4 sw=4 expandtab: (add to ~/.vimrc: set modeline modelines=5) */
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is [Open Source Virtual Machine.].
 *
 * The Initial Developer of the Original Code is
 * Adobe System Incorporated.
 * Portions created by the Initial Developer are Copyright (C) 2004-2006
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *   Renaun Erickson <renaun@gmail.com>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

package avmplus
{
	import org.osflash.signals.Signal;
	import flash.utils.ByteArray;
	import avmplus.ClientSocket;
	import flash.utils.Dictionary;
	
	import C.errno.*;
    
    /**
     * The Socket class
     * Provides methods to create client and server sockets.
     * 
     * @langversion 3.0
     * @playerversion Flash 9
     * @productversion redtamarin 0.3
     * @since 0.3.0
     * 
     * @see http://code.google.com/p/redtamarin/wiki/Socket
     */
    [native(cls="ServerSocketClass", instance="ServerSocketObject", methods="auto")]
    public class ServerSocket
    {

        /**
         * The Socket constructor.
         * 
         * @productversion redtamarin 0.3
         * @since 0.3.0
         */
        public function ServerSocket(handler:Function)
        {
			connect = new Signal(ClientSocket, Boolean);
			connect.add(handler);
			
			loop = new Signal();
			data = new Signal(ClientSocket,ByteArray);
			error = new Signal(ClientSocket, int);
			
			clientsList = new LinkedList();
			clientsHash = new Dictionary(true);
			
			setConnectCallback(proxyConnectHandler);
			setSocketDataCallback(proxySocketDataHandler);
			setLoopCallback(proxyLoopHandler);
			setErrorCallback(proxyErrorHandler);
			trace("ServerSocket Constructor");
        }
		
		public var id2:int = -10;
		
		public var connect:Signal;
		public var data:Signal;
		public var loop:Signal;
		public var error:Signal;
		
		public function get listening():Boolean
		{
			return _listening;
		}
		public function get numConnections():int
		{
			return _numConnections;
		}
		
		private var clientsList:LinkedList;
		private var clientsHash:Dictionary;
		private var _listening = false;
		private var _numConnections:int = 0;
		
		private native function setConnectCallback(func:Function):void;
		private native function setSocketDataCallback(func:Function):void;
		private native function setLoopCallback(func:Function):void;
		private native function setErrorCallback(func:Function):void;
		
		public native function getLastError():int;
		public var closeOnCommonErrors:Boolean = true;
		
		private native function _listen(address:String, port:uint):Boolean;
		private native function _loop(milliseconds:Number):Boolean;
		private native function _send(fileDescriptor:int, bytes:ByteArray):int;
		private native function _shutdown(fileDescriptor:int):Boolean;
		
		public function close(fileDescriptor:int, justRemoveReference:Boolean = false):Boolean
		{
			if (!clientsHash[fileDescriptor])
				return;
			trace(fileDescriptor + " closing...");
			if (connect && clientsHash[fileDescriptor])
				connect.dispatch(clientsHash[fileDescriptor], false);
			
			clientsHash[fileDescriptor] = null;
			delete clientsHash[fileDescriptor];
			
			var node:LinkedListNode = clientsList.head;
			while (node != null)
			{
				if (node.data == fileDescriptor)
				{
					clientsList.remove(node);
					break;
				}
				node = node.next;
			}
			_numConnections--;
			if (justRemoveReference)
				shutdown(fileDescriptor);
		}
        
        //private native function _accept():Socket;
		
		public function listen(address:String, port:uint):Boolean
		{
			if (_listening)
				return;
			_listening = true;
			// Should hang on this line and not return true
			_listening = _listen(address, port);
			return _listening;
		}
		
		/**
		 *  Expects a number in milliseconds 1000 = 1s
		 */
		public function start(milliseconds:int):void
		{
			_loop(Number(milliseconds/1000));
		}
		
		public function send(fileDescriptor:int, bytes:ByteArray):int
		{
			var sent:int = _send(fileDescriptor, bytes);
			if (sent < 0)
				proxyErrorHandler(fileDescriptor, getLastError());
			return sent;
		}
		
		public function sendToAll(bytes:ByteArray):void
		{
			//trace("sendToAll : " + clientsList.head);
			var node:LinkedListNode = clientsList.head;
			var err:int = 0;
			// TODO handle errors on send
			while (node != null)
			{
				//trace("Sending to : " + int(node.data));
				err = _send(int(node.data), bytes);
					
				node = node.next;
			}
		}
		
		/**
		 * 	Create a linked list of clients for broadcast ability.
		 */
		private function proxySocketDataHandler(fileDescriptor:*, bytes:*):void
		{
			//trace("socketData: " + fileDescriptor + " - " + bytes + " - " + this);
			var b:ByteArray = ByteArray(bytes);
			if (b)
			{
				b.position = 0;
				if (data)
				{
					data.dispatch(clientsHash[fileDescriptor], bytes);
					//trace("socketData2 " + b.length + " - " + b.bytesAvailable);
				}
				
			}
		}
		
		/**
		 * 	Receive error int.
		 */
		private function proxyErrorHandler(fileDescriptor:*, error:*):void
		{
			//trace("proxyErrorHandler: " + fileDescriptor + " - " + error);
			try
			{
				if (closeOnCommonErrors)
				{
					if (error == EBADF)
						close(fileDescriptor, true);
					
					else if (error == ECONNRESET
						|| error == ETIMEDOUT
						|| error == EPIPE)
						close(fileDescriptor);
				}
				if (error)
				{
					//clientsHash[fileDescriptor]
					error.dispatch(null, error);
				}
				
			}
			catch (error:*)
			{
				//trace("TRY/CATCH ERROR - proxyErrorHandler");
			}
		}
				
		/**
		 * 	Create a linked list of clients for broadcast ability.
		 */
		private function proxyConnectHandler(fileDescriptor:*, connected:*):void
		{
			if (connected == 1)
			{
				var client:ClientSocket = new ClientSocket(this, fileDescriptor);
				
				clientsHash[fileDescriptor] = client;
				clientsList.add(new LinkedListNode(fileDescriptor));
				
				if (connect)
					connect.dispatch(client, (connected == 1));

				_numConnections++;
				trace("Connecting: " + fileDescriptor + " conn: " + _numConnections);
			}
			else if (connected == -1) // User Disconnected
			{
				close(fileDescriptor);
			}
			
		}
		/**
		 * 	Create a linked list of clients for broadcast ability.
		 */
		private function proxyDataHandler():void
		{
			//trace("data call");
		}
		
		
		/**
		 * 	Create a linked list of clients for broadcast ability.
		 */
		private function proxyLoopHandler():void
		{
			//trace("loop1");
			if (loop)
				loop.dispatch();
			//trace("loop2");
		}
	}
	
	/**
	 *   A node in a linked list. Its purpose is to hold the data in the
	 *   node as well as links to the previous and next nodes.
	 *   @author Jackson Dunstan
	 */
	class LinkedListNode
	{
		public var next:LinkedListNode;
		public var prev:LinkedListNode;
		public var data:*;
		public function LinkedListNode(data:*=undefined)
		{
			this.data = data;
		}
	}
	
	class LinkedList
	{
		public var head:LinkedListNode = null;
		public var tail:LinkedListNode;
		public var length:int;
		
		public function LinkedList()
		{
		}
		
		public function add(node:LinkedListNode): void
		{
			if (!node)
				return;
			node.prev = this.tail;
			if (this.tail)
			{
				this.tail.next = node;
			}
			else
			{
				this.head = node;
			}
			this.tail = node;
			
			this.length++;
		}
		
		public function remove(node:LinkedListNode): void
		{
			if (!node)
				return;
			var prev:LinkedListNode = node.prev;
			var next:LinkedListNode = node.next;
			if (prev)
				prev.next = next;
			if (next)
				next.prev = prev;
			if (this.head == node)
				this.head = node.next;
			if (this.tail == node)
				this.tail = tail.prev;
			
			node = null;
			this.length--;
		}
	}
}
