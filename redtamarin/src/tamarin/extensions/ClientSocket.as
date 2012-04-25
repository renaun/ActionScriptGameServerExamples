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
    
    /**
     * The ClientSocket class
     * Provides methods to interact with client sockets.
     * 
     * @langversion 3.0
     * @playerversion Flash 9
     * @productversion redtamarin 0.3
     * @since 0.3.0
     * 
     */
    public dynamic class ClientSocket
    {

        /**
         * The ClientSocket constructor.
         * 
         */
        public function ClientSocket(server:ServerSocket, id:int)
        {
			this.server = server;
			_id = id;
        }
		
		private var server:ServerSocket;
		private var _id:int = -1;
		
		public function get id():int
		{
			return _id;
		}
		
		public var data:Signal;
        
        public function send(bytes:ByteArray):void
		{
			server.send(_id, bytes);
		}
		public function sendUTF(msg:String):void
		{
			var b:ByteArray = new ByteArray();
			b.writeUTFBytes(msg);
			b.position = 0;
			send(b);
		}
	}
}
