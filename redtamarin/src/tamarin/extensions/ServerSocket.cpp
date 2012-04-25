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
 * Portions created by the Initial Developer are Copyright (C) 1993-2006
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


#include "avmshell.h"

#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <netinet/in.h>
#include <ev.h>

namespace avmplus
{
    
    ServerSocketClass::ServerSocketClass(VTable *vtable)
    : ClassClosure(vtable)
    {
        createVanillaPrototype();
    }
    
    
    
    ScriptObject* ServerSocketClass::createInstance(VTable* ivtable, ScriptObject* prototype)
    {
        return ServerSocketObject::create(ivtable->gc(), ivtable, prototype);
    }
    
    
    ServerSocketObject* ServerSocketClass::constructSocket()
    {
        VTable* ivtable = this->ivtable();
        return (ServerSocketObject*)ServerSocketObject::create(ivtable->gc(), ivtable, prototypePtr());
    }
    
    
    ServerSocketObject::ServerSocketObject(VTable *vtable, ScriptObject *delegate)
    : ScriptObject(vtable, delegate)
    {
        _buffer = toplevel()->byteArrayClass()->constructByteArray();
        _buffer->set_length(0);
    }
    
    ServerSocketObject::~ServerSocketObject()
    {
        //Platform::GetInstance()->destroySocket(_socket);
        //_socket = NULL;
        _buffer->clear();
        _buffer = NULL;
    }
    
    /**
     *  Save the connect callback for later use
     */    
    void ServerSocketObject::setConnectCallback(FunctionObject* f)
    {
        AvmCore *core = this->core();
        // Listeners MUST be functions or null
        if ( core->isNullOrUndefined(f->atom()) )
        {
            f = 0;
        }
        else if (!AvmCore::istype(f->atom(), core->traits.function_itraits))
        {
            toplevel()->argumentErrorClass()->throwError( kInvalidArgumentError, core->toErrorString("Function"));
            //return undefinedAtom;
        }
        acceptCallback = f;
    }
    
    /**
     *  Save the socketData callback for later use
     */    
    void ServerSocketObject::setSocketDataCallback(FunctionObject* f)
    {
        AvmCore *core = this->core();
        // Listeners MUST be functions or null
        if ( core->isNullOrUndefined(f->atom()) )
        {
            f = 0;
        }
        else if (!AvmCore::istype(f->atom(), core->traits.function_itraits))
        {
            toplevel()->argumentErrorClass()->throwError( kInvalidArgumentError, core->toErrorString("Function"));
            //return undefinedAtom;
        }
        printf("Setting socketDataCallback \n");
        socketDataCallback = f;
    }
    
    /**
     *  Save the connect callback for later use
     */    
    void ServerSocketObject::setLoopCallback(FunctionObject* f)
    {
        AvmCore *core = this->core();
        // Listeners MUST be functions or null
        if ( core->isNullOrUndefined(f->atom()) )
        {
            f = 0;
        }
        else if (!AvmCore::istype(f->atom(), core->traits.function_itraits))
        {
            toplevel()->argumentErrorClass()->throwError( kInvalidArgumentError, core->toErrorString("Function"));
            //return undefinedAtom;
        }
        loopCallback = f;
    }
    
    /**
     *  Save the error callback for later use
     */    
    void ServerSocketObject::setErrorCallback(FunctionObject* f)
    {
        AvmCore *core = this->core();
        // Listeners MUST be functions or null
        if ( core->isNullOrUndefined(f->atom()) )
        {
            f = 0;
        }
        else if (!AvmCore::istype(f->atom(), core->traits.function_itraits))
        {
            toplevel()->argumentErrorClass()->throwError( kInvalidArgumentError, core->toErrorString("Function"));
            //return undefinedAtom;
        }
        socketErrorCallback = f;
    }
    
    /**
     *  Start game loop timer
     */
    bool ServerSocketObject::_loop(float milliseconds)
    {
        
        loop_ev = ev_default_loop(0);
        struct timer_io w_loop;
        w_loop.socketObject = this;
        
        ev_timer_init (&w_loop.io, loop_cb, milliseconds, milliseconds);
        ev_timer_start (loop_ev, &w_loop.io);
        
        ev_loop(loop_ev, 0);
        return false;
    }
    
    /**
     *  Start listening for incoming ClientSocket connections
     */
    bool ServerSocketObject::_listen(Stringp host, const int port)
    {
        //struct ev_loop *loop = ev_default_loop(0);
        
        struct socket_io w_accept;
        
        StUTF8String hostUTF8(host);
        const char* hostAddr = hostUTF8.c_str();
        
        // Create server socket
        if( (w_accept.fd = socket(PF_INET, SOCK_STREAM, 0)) < 0 )
        {
            printf("socket Error.\n");
            //perror("socket error");
            return false;
        }
        
        // flag it as non-blocking
# ifdef WIN32
        u_long iMode = 1;
        ioctlsocket(w_accept.fd, FIONBIO, &iMode);
# else
        int flags = fcntl(w_accept.fd, F_GETFL, 0);
        fcntl(w_accept.fd, F_SETFL, (flags > 0 ? flags : 0) | O_NONBLOCK);
# endif
        
        sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        //addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
        addr.sin_addr.s_addr = inet_addr(hostAddr);
        addr.sin_port = htons(port);
        int status = bind(w_accept.fd,
                          reinterpret_cast<struct sockaddr *>(&addr),
                          sizeof(addr));
        if (status != 0)
        {
            printf("Bind Error.\n");
            return false;
        }
        
        _socket = w_accept.fd;
        
        // Start listing on the socket
        if (listen(w_accept.fd, 2) < 0)
        {
            printf("Listen error.\n");
            return false;
        }
        
        w_accept.socketObject = this;
        
        // Initialize and start a watcher to accepts client requests
        ev_io_init(&w_accept.io, accept_cb, w_accept.fd, EV_READ);
        ev_io_start(loop_ev, &w_accept.io);
        
        // Start infinite loop
//        while (1)
//        {
            ev_loop(loop_ev, 0);
//        ev_run(loop_ev, 0);// EVLOOP_NONBLOCK);
//        }
        //printf("Successfully listening.\n");
        return true;
    }
    
    int ServerSocketObject::_send(int client_fd, ByteArrayObject *data)
    {
        if(!data) 
        {
            toplevel()->throwArgumentError(kNullArgumentError, "data");
        }
        //printf("Sending bytes from %i to %i\n", _socket, client_fd);
        const void *bytes = &(data->GetByteArray())[0];
        int sent      = 0;
        int totalSent = 0;
        int bytesleft = data->get_length();
        int flags = 0;
#ifdef AVMPLUS_MAC
        //nothing
#else
        flags |= MSG_NOSIGNAL;
#endif
        flags |= MSG_DONTWAIT;// 
        
        while( totalSent < bytesleft ) 
        {
            sent = send(client_fd, (const char *)bytes+totalSent, bytesleft, flags);
            //printf("Sent %i\n", sent);
            if (sent < 0) {
                //printf("Send Error: %i - %i\n", client_fd, errno);
                // Stop and free watcher if client socket is closing
                return -1;
            }
            totalSent += sent;
            bytesleft -= sent;
        }
        
        return sent;
    }
    
    /* Loop tickle method client requests */
    void ServerSocketObject::loop_cb(struct ev_loop *loop, struct ev_timer *timer, int revents)
    {
        struct timer_io *w_timer = (struct timer_io *)timer;
        
        if(EV_ERROR & revents)
        {
            printf("got invalid event");
            //perror("got invalid event");
            return;
        }
        
        AvmCore *core = w_timer->socketObject->core();
        Atom argv[1] = { w_timer->socketObject->loopCallback->atom() };
        int argc = 0;
        
        TRY(core, kCatchAction_ReportAsError)
        {
            w_timer->socketObject->loopCallback->call(argc, argv);
        }
        CATCH(Exception *exception)
        {
            (void) exception;
            //core->uncaughtException(exception);
        }
        END_CATCH
        END_TRY
    }

    
    /* Accept client requests */
    void ServerSocketObject::accept_cb(struct ev_loop *loop, struct ev_io *watcher, int revents)
    {
        struct socket_io *w_socket = (struct socket_io *)watcher;
        
        int client_sd;
        struct sockaddr_in client_addr;
        socklen_t client_len = sizeof(client_addr);
        //struct socket_io w_client;
        //w_client.io = (struct ev_io) malloc (sizeof(struct ev_io));

        //struct socket_io *w_client = (struct socket_io*) malloc (sizeof(struct socket_io));
        //struct ev_io *w_client2 = (struct ev_io*) malloc (sizeof(struct ev_io));
        //w_client.io = &w_client2
        
        if(EV_ERROR & revents)
        {
            printf("got invalid event");
            //perror("got invalid event");
            return;
        }
        
        // Accept client request
        client_sd = accept(watcher->fd, (struct sockaddr *)&client_addr, &client_len);
        
        AvmCore *core = w_socket->socketObject->core();
        int argc = 2;
        
        if (client_sd < 0)
        {
            
            printf("Accept Error %i - %i\n", watcher->fd, errno);
            Atom argv2[3] = { w_socket->socketObject->socketDataCallback->atom(), core->intToAtom(client_sd), core->intToAtom(errno) };
            w_socket->socketObject->socketErrorCallback->call(argc, argv2);
            //perror("accept error");
            return;
        }

        struct socket_io *wc = (struct socket_io*) calloc(sizeof(socket_io), 1);
        
        wc->socketObject = w_socket->socketObject; // passing in the server instance to have all data callbacks come back on one object
        wc->fd = client_sd;
        // Initialize and start watcher to read client requests
        ev_io_init(&wc->io, read_cb, client_sd, EV_READ);
        ev_io_start(loop, &wc->io);
        
        //printf("Successfully connected with client.\n");
        
        Atom argv[3] = { w_socket->socketObject->acceptCallback->atom(), core->intToAtom(client_sd), core->intToAtom(1) };
        
        
        TRY(core, kCatchAction_ReportAsError)
        {
            w_socket->socketObject->acceptCallback->call(argc, argv);
        }
        CATCH(Exception *exception)
        {
            (void) exception;
            //core->uncaughtException(exception);
        }
        END_CATCH
        END_TRY
    }
    
    /* Read client message */
    void ServerSocketObject::read_cb(struct ev_loop *loop, struct ev_io *watcher, int revents)
    {
        char buffer[BUFFER_SIZE];
        ssize_t read;
        
        if(EV_ERROR & revents)
        {
            perror("got invalid event");
            return;
        }
        //char *buffer = new char[BUFFER_SIZE];
        
        // Receive message from client socket
        read = recv(watcher->fd, buffer, BUFFER_SIZE, 0);
        
        
        struct socket_io *w_socket = (struct socket_io *)watcher;
        AvmCore *core = w_socket->socketObject->core();
        int argc = 2;

        if(read < 0)
        {
            //printf("Read Error: %i - %i\n", watcher->fd, errno);
            Atom argv1[3] = { w_socket->socketObject->socketDataCallback->atom(), core->intToAtom(w_socket->fd), core->intToAtom(errno) };
            w_socket->socketObject->socketErrorCallback->call(argc, argv1);
            // Stop and free watcher if client socket is closing
            //close(watcher->fd);
            if (errno != EAGAIN)
            {
                ev_io_stop(loop,watcher);
                free(watcher);
            }
            return;
        }
        
        if(read == 0)
        {
            // Tell the app a user has disconnected
            Atom argv[3] = { w_socket->socketObject->acceptCallback->atom(), core->intToAtom(w_socket->fd), core->intToAtom(-1) };
            
            w_socket->socketObject->acceptCallback->call(argc, argv);
            
            // Stop and free watcher if client socket is closing
            //close(watcher->fd);
            ev_io_stop(loop,watcher);
            free(watcher);
            //perror("peer might closing");
            //return;
        }
        else
        {
            //printf("Reading bytes:%i\n",(int)read);
            //printf("message:%s\n",buffer);

            w_socket->socketObject->_buffer->clear();
            w_socket->socketObject->_buffer->GetByteArray().Write( buffer, read );
            
            bzero(buffer, read);
            
            Atom argv2[3] = { w_socket->socketObject->socketDataCallback->atom(), core->intToAtom(w_socket->fd), w_socket->socketObject->_buffer->atom() };
            w_socket->socketObject->socketDataCallback->call(argc, argv2);
        }
    }
    
    int ServerSocketObject::getLastError()
    {
#ifdef WIN32
        return WSAGetLastError();
#else
        return errno;
#endif
    }
    
    bool ServerSocketObject::_shutdown(int fd)
    {
        // Shutdown socket for both read and write.
        int status = shutdown(fd, SHUT_RDWR);
        //printf( "PosixSocket::Shutdown status = %d\n", status );
        close(fd);
        return status == 0;
    }
    
}

