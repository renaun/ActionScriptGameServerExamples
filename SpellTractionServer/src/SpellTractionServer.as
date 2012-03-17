/*
include "../../SpellTractionLibrary/src/com/renaun/spelltraction/nerves/INerveDispatcher.as";
include "../../SpellTractionLibrary/src/com/renaun/data/LinkedList.as";
include "../../SpellTractionLibrary/src/com/renaun/data/LinkedListNode.as";
include "../../SpellTractionLibrary/src/com/renaun/spelltraction/heart/IBeatable.as";
include "../../SpellTractionLibrary/src/com/renaun/spelltraction/data/UserData.as";
include "../../SpellTractionLibrary/src/com/renaun/spelltraction/brain/BrainCommands.as";
include "../../SpellTractionLibrary/src/com/renaun/spelltraction/nerves/IServerNerveSystem.as";
include "com/renaun/spelltraction/brain/ServerBrain.as";
include "com/renaun/spelltraction/nerves/ServerNerveSystem.as";
include "com/renaun/spelltraction/nerves/SocketServerNerveDispatcher.as";
*/
import avmplus.ClientSocket;
import avmplus.ServerSocket;

import com.renaun.spelltraction.brain.ServerBrain;
import com.renaun.spelltraction.nerves.ServerNerveSystem;
import com.renaun.spelltraction.nerves.SocketServerNerveDispatcher;

import flash.utils.ByteArray;
function loopHandler():void
{
	if (!ss.listening)
		ss.listen("10.111.33.190", 12122); // ec2-107-20-128-129.compute-1.amazonaws.com
	else
	{
		serverBrain.beat();
	}
}

var serverBrain:ServerBrain;
var serverNerve:ServerNerveSystem;
serverBrain = new ServerBrain();

var serverDispatcher:SocketServerNerveDispatcher = new SocketServerNerveDispatcher();
serverNerve = new ServerNerveSystem(serverBrain, serverDispatcher);
serverBrain.addNerve(serverNerve);
var ss:ServerSocket = serverDispatcher.createServerSocket(serverNerve);
//var ss:ServerSocket = new ServerSocket(connectHandler);
ss.loop.add(loopHandler);
ss.start(250);
