package com.renaun.data
{
public class LinkedList
{
	public var head:LinkedListNode = null;
	public var tail:LinkedListNode = null;
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
	
	public function indexOf(node:LinkedListNode): int
	{
		var index:int = -1;
		var cur:LinkedListNode = this.head;
		for (; cur; cur = cur.next)
		{
			index++;
			if (cur == node)
			{
				return index;
			}
		}
		return -1;
	}
	
	public function reset():void
	{
		this.head = null;
		this.tail = null;
		this.length = 0;
	}
}
}