#ifndef JSPRINTERDLL_H
#define JSPRINTERDLL_H

// Prevent winsock.h from being included before winsock2.h
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

// Include winsock2.h first to avoid conflicts with windows.h
#include <winsock2.h>
#include <windows.h>

// Prevent macro redefinitions
#pragma warning(disable: 4005)  // macro redefinition warning

#ifdef JSPRINTERDLL_EXPORTS
#define JSPRINTERDLL_API __declspec(dllexport)
#else
#define JSPRINTERDLL_API __declspec(dllimport)
#endif

#define NullParameter   -1

enum EnPrinterPort
{
  PP_COM,
  PP_LPT,
  PP_USB,
  PP_NET
};
enum EnPrinterInstruction
{

  PI_SeletCutModeAndCutPaper,//1D 56 M N
  PI_SelectPrintMode,//1B 21 N
  PI_PrintDownLoadedBMP,//1D 2F M
  PI_GenerateDrawerPlse,//1B 70 M T1 T2
  PI_PrintSingleBeeper,//1B 42 N T
  PI_PrintSingleBeeperAndAlarmLightFlashes//1B 43 M T N
};
enum EnStateFlag
{
  SF_Failed,//Operation Failled
  SF_Success//Operation Success
};



/********Functions to be called on Lan port**************/
JSPRINTERDLL_API BOOL _stdcall InitNetSev(); 

JSPRINTERDLL_API int _stdcall ConnectNetPort(SOCKET *lpSocket,
	SOCKADDR_IN * pPrinterAddr,   
	timeval *lpTimeout);  

JSPRINTERDLL_API int _stdcall WriteToNetPort(SOCKET *lpSocket,
	char *SendBuf,
	DWORD SendBufSize);

JSPRINTERDLL_API int _stdcall ReadFromNetPort(SOCKET *lpSocket,
	char *RecvBuf,    
	DWORD RecvBufSize);  

JSPRINTERDLL_API BOOL _stdcall CloseNetPor(SOCKET *lpSocket);

JSPRINTERDLL_API  BOOL _stdcall CloseNetServ();





/********Functions to be called on USB port**************/
JSPRINTERDLL_API HANDLE  _stdcall OpenUsb();


JSPRINTERDLL_API BOOL  _stdcall WriteUsb(HANDLE hUsb,
	char *SendBuf,								
	DWORD SendBufSize,							
	LPDWORD lpNumberOfBytesWriten);				


JSPRINTERDLL_API BOOL  _stdcall ReadUsb(HANDLE hUsb,                
char *ReadBuf,               
DWORD ReadBufSize,			
LPDWORD lpNumberOfBytesRead); 
JSPRINTERDLL_API BOOL  _stdcall CloseUsb(HANDLE hUsb);





/********Functions to be called on Lpt port**************/
JSPRINTERDLL_API HANDLE  _stdcall OpenLptW(LPCWSTR LptName);
JSPRINTERDLL_API HANDLE  _stdcall OpenLptA(LPCSTR lpLptName); 

JSPRINTERDLL_API BOOL _stdcall WriteLpt(HANDLE hLpt,
	 char *SendBuf,
	 DWORD SendBufSize,
	 LPDWORD BytesWritten);

JSPRINTERDLL_API BOOL _stdcall CloseLpt(HANDLE hLpt);


/****************Functions to be called on Serial port**************/
JSPRINTERDLL_API HANDLE _stdcall OpenComW(LPCWSTR lpCom,DWORD BaudRate);

JSPRINTERDLL_API HANDLE _stdcall OpenComA(LPCSTR lpCom,DWORD BaudRate);

JSPRINTERDLL_API BOOL _stdcall ReadCom(HANDLE hCom,                
			 char *ReadBuf,               
			 DWORD ReadBufSize, 
			 LPDWORD lpNumberOfBytesRead); 

JSPRINTERDLL_API BOOL _stdcall WriteCom(HANDLE hCom,char *SendBuf,DWORD SendBufSize,LPDWORD BytesWritten);

JSPRINTERDLL_API BOOL _stdcall CloseCom(HANDLE hCom);

/****Brief commands called by functions in EnPrinterInstruction******/

/**
  * @brief : Sends the specified simple command
  * @pPort : specified communication port(the specified port must OPEN)
  * @portHandle :specified port handle or socket
  * @pInstr :specified  the command
  * @parameter1 :command parameter1
  * @parameter2 :command parameter2
  * @parameter3 :command parameter3
  * @parameter4 :command parameter4(If doesn't use it,use NullParameter(-1) to replace.)
  * @retval: If the operation is succeed or not.
  * @date  : [2015/01/05 15:28]  ---Lee
  */
JSPRINTERDLL_API  EnStateFlag _stdcall SendInstruction(
       EnPrinterPort pPort,
       void * portHandle,
       EnPrinterInstruction pInstr,
       int parameter1,
       int parameter2,
       int parameter3,
       int parameter4
  );

#endif // JSPRINTERDLL_H
