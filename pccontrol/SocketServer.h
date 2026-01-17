#ifndef SERVER_H
#define SERVER_H

#import <Foundation/Foundation.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>

#define PORT 6000
#define ADDR "0.0.0.0"

void socketServer();
void readStream(CFReadStreamRef readStream, CFStreamEventType eventype, void * clientCallBackInfo);
void TCPServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
int notifyClient(UInt8* msg, CFWriteStreamRef client);

#endif
