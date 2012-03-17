package com.renaun.data
{
public class LinkedListNode
{
	public var next:LinkedListNode;
	public var prev:LinkedListNode;
	public var data:*;
	public function LinkedListNode(data:*=undefined)
	{
		this.data = data;
	}
}
}