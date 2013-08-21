enum {
	pasvftp=0,epsvftp,portftp,lprtftp, eprtftp
};

#define DATASTR(args) [ args dataUsingEncoding:NSUTF8StringEncoding ]

#define SERVER_PORT 20000
#define READ_TIMEOUT -1

#define FTP_CLIENT_REQUEST 0

#ifdef DEBUG
#define TRACE(a, ...) NSLog(a, ##__VA_ARGS__)
#else
#define TRACE(a, ...)
#endif

enum {
	
	clientSending=0, clientReceiving=1, clientQuiet=2,clientSent=3
};
