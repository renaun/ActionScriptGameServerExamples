/* -*- Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4 -*- */
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
 *   Renaun Erickson <renaun@gmail.com>.
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

#ifndef __avmplus_ServerSocket__
#define __avmplus_ServerSocket__

#include <ev.h>


#define BUFFER_SIZE 1024

namespace avmplus
{
    
    
    struct socket_io
    {
        ev_io io;
        int fd;
        ServerSocketObject* socketObject;
    };
    
    struct timer_io
    {
        ev_timer io;
        ServerSocketObject* socketObject;
    };
    
    class ServerSocketClass : public ClassClosure
    {
    public:
        ServerSocketClass(VTable *vtable);
        
        ScriptObject *createInstance(VTable *ivtable, ScriptObject *delegate);
        
        ServerSocketObject* constructSocket();
        
        DECLARE_SLOTS_ServerSocketClass;
    };
    
    class ServerSocketObject : public ScriptObject
    {
    private:
        
        struct ev_loop *loop_ev;
        int _socket;
    public:
        ServerSocketObject(VTable *vtable, ScriptObject *delegate);
        
        ~ServerSocketObject();
        
        
        REALLY_INLINE static ServerSocketObject* create(MMgc::GC* gc, VTable* ivtable, ScriptObject* delegate)
        {
            return new (gc, ivtable->getExtraSize()) ServerSocketObject(ivtable, delegate);
        }
        
        //static int total_clients;  // Total number of connected clients
        static void accept_cb(struct ev_loop *loop, struct ev_io *watcher, int revents);
        static void read_cb(struct ev_loop *loop, struct ev_io *watcher, int revents);
        static void loop_cb(struct ev_loop *loop, struct ev_timer *timer, int revents);
        
        void setConnectCallback(FunctionObject* f);
        void setSocketDataCallback(FunctionObject* f);
        void setLoopCallback(FunctionObject* f);
        void setErrorCallback(FunctionObject* f);
        bool _listen(Stringp host, const int port);
        bool _loop(float milliseconds);
        int _send(int client_fd, ByteArrayObject *data);
        bool _shutdown(int client_fd);
        
        int getLastError();
        
        struct socket_io *w_client;
        
        DRCWB(ByteArrayObject*) _buffer;
        DRCWB(FunctionObject*)      GC_POINTER(acceptCallback);
        DRCWB(FunctionObject*)      GC_POINTER(socketDataCallback);
        DRCWB(FunctionObject*)      GC_POINTER(loopCallback);
        DRCWB(FunctionObject*)      GC_POINTER(socketErrorCallback);
                
        DECLARE_SLOTS_ServerSocketObject;
    };

   
}

#endif /* __avmplus_ServerSocket__ */

