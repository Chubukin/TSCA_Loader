unit ExtUnit;

interface
uses
  System.IniFiles, System.SyncObjs, System.SysUtils, System.IOUtils, System.Classes, IdTCPClient, Winapi.Windows;

type
TLanDataPackage = Record
  CommandStr : string;
  CommandStrLen:integer;
  CommandParameters : string;
  CommandParametersLen:integer;
  CommandData : widestring;
  CommandDataLen:integer;
  DataFileName:String;
  DataFileNameLen:integer;
  DataFileNameList:string;
  DataFileNameListLen:integer;
end;

TLanClient = class (TIdTCPClient)
public
  IsConnected:boolean;
end;

TLanClientEvent = class
  procedure LanClientConnected(Sender: TObject);
  procedure LanClientDisconnected(Sender: TObject);
end;

  function IniFileRead(DParam:string):String;
  function IniFileWrite(DParam,DValue:string):String;
  function TSCAServerConect(TSCAServerName:string):boolean;
  function GetParseStringParams(SourceString: string; NumberParameter:integer):String;
  function GetParseStringCount(SourceString: string):Integer;
  function GetParseParameter(SourceString: string; ReturnValue:integer):String;
  function GetOSArchitectureToStr(const a: TOSVersion.TArchitecture): string;
  function GetOSInfo: string;
  procedure SetLog(TextLog:string);
  procedure TSCAServerExchage;
  procedure SaveDataToStream(DataIn:TLanDataPackage; var StreamOut: TMemoryStream);
  procedure LoadDataFromStream(StreamIn: TMemoryStream; var DataOut:TLanDataPackage);

var
  CS_SetLog: TCriticalSection;
  LanClient:TLanClient;
  LanClientEvent:TLanClientEvent;

implementation
uses Main;

function GetOSArchitectureToStr(const a: TOSVersion.TArchitecture): string;
begin
  case a of
    arIntelX86: Result := 'x86';
    arIntelX64: Result := 'x64';
  else
    Result := 'UNKNOWN OS Architecture';
  end;
end;

function GetOSInfo: string;
var
  SPInfo:string;
begin
  try
    Result:='';
    if TOSVersion.ServicePackMajor > 0 then SPInfo:='SP '+ IntToStr(TOSVersion.ServicePackMajor)+' ' else SPInfo:='';
    Result:=TOSVersion.Name+' '+SPInfo+GetOSArchitectureToStr(TOSVersion.Architecture);
  except
    on E: Exception do Result:='Ошибка определения версии ОС';
  end;
end;

procedure SaveDataToStream(DataIn:TLanDataPackage; var StreamOut: TMemoryStream);
var
  StreanFileTemp : TMemoryStream;
  CountFiles,i:integer;
  FileNameTmp:string;
begin
  DataIn.CommandStrLen:=Length(DataIn.CommandStr);
  DataIn.CommandParametersLen:=Length(DataIn.CommandParameters);
  DataIn.CommandDataLen:=Length(DataIn.CommandData);
  DataIn.DataFileNameLen:=Length(DataIn.DataFileName);
  DataIn.DataFileNameList:=''; // DataIn.DataFileName Должен быть в формате Файл01;файл02;
  CountFiles:=GetParseStringCount(DataIn.DataFileName);
  if CountFiles > 0 then
  begin
    SetLog('Файлов: '+IntToStr(CountFiles)) ;
    for I := 0 to CountFiles-1 do
    begin
      FileNameTmp:= GetParseStringParams(DataIn.DataFileName, i);
      if FileExists(PathHomeProgramm+PathExchangeFolder+FileNameTmp)=True then
      begin
        SetLog('Предварительный поиск: Файл '+FileNameTmp+' найден');
        try
          try
            StreanFileTemp:=TMemoryStream.Create;
            StreanFileTemp.LoadFromFile(PathHomeProgramm+PathExchangeFolder+FileNameTmp);
            DataIn.DataFileNameList:=DataIn.DataFileNameList+FileNameTmp+':'+IntToStr(StreanFileTemp.Size)+';';
          finally
            FreeAndNil(StreanFileTemp);
          end;
        except
        on E: Exception do SetLog('Ошибка отправки файла данных '+E.ClassName + ': ' + E.Message);
        end;
      end
      else
        SetLog('Предварительный поиск:  Файл '+FileNameTmp+' НЕ найден') ;
    end;
  end;
  SetLog('Список передаваемых файлов: '+DataIn.DataFileNameList) ;
  DataIn.DataFileNameListLen:=Length(DataIn.DataFileNameList);
  //SetLog('Данные SaveDataToStream CommandStr '+DataIn.CommandStr+' CommandParameters '+DataIn.CommandParameters+' CommandData '+DataIn.CommandData+' DataFileName '+DataIn.DataFileName+' DataFileNameList '+DataIn.DataFileNameList);
  //SetLog('Данные SaveDataToStream CommandStrLen '+IntToStr(DataIn.CommandStrLen)+' CommandParametersLen '+IntToStr(DataIn.CommandParametersLen)+' CommandDataLen '+IntToStr(DataIn.CommandDataLen)+' DataFileNameLen '+IntToStr(DataIn.DataFileNameLen)+' DataFileNameListLen '+IntToStr(DataIn.DataFileNameListLen));
  StreamOut.Write(DataIn.CommandStrLen, SizeOf(DataIn.CommandStrLen));
  if(SizeOf(DataIn.CommandStrLen) > 0)then StreamOut.Write(DataIn.CommandStr[1], DataIn.CommandStrLen * SizeOf(DataIn.CommandStr[1]));
  StreamOut.Write(DataIn.CommandParametersLen, SizeOf(DataIn.CommandParametersLen));
  if(SizeOf(DataIn.CommandParametersLen) > 0)then StreamOut.Write(DataIn.CommandParameters[1], DataIn.CommandParametersLen * SizeOf(DataIn.CommandParameters[1]));
  StreamOut.Write(DataIn.CommandDataLen, SizeOf(DataIn.CommandDataLen));
  if(SizeOf(DataIn.CommandDataLen) > 0)then StreamOut.Write(DataIn.CommandData[1], DataIn.CommandDataLen * SizeOf(DataIn.CommandData[1]));
  StreamOut.Write(DataIn.DataFileNameListLen, SizeOf(DataIn.DataFileNameListLen));
  if (DataIn.DataFileNameLen > 0) and (CountFiles > 0) then
  begin
    if(SizeOf(DataIn.DataFileNameListLen) > 0)then StreamOut.Write(DataIn.DataFileNameList[1], DataIn.DataFileNameListLen * SizeOf(DataIn.DataFileNameList[1]));
    CountFiles:=GetParseStringCount(DataIn.DataFileNameList);
    if CountFiles > 0 then
    begin
      for I := 0 to CountFiles-1 do
      begin
        FileNameTmp:= GetParseParameter(GetParseStringParams(DataIn.DataFileNameList, i),0);
        if FileExists(PathHomeProgramm+PathExchangeFolder+FileNameTmp)=True then
        begin
          SetLog('Файл для отправки '+FileNameTmp+' найден');
          try
            try
              StreanFileTemp:=TMemoryStream.Create;
              StreanFileTemp.LoadFromFile(PathHomeProgramm+PathExchangeFolder+FileNameTmp);
              StreamOut.CopyFrom(StreanFileTemp,StreanFileTemp.Size);
              SetLog('StreamOut.Position '+InttOsTR(StreamOut.Position)) ;
            finally
              FreeAndNil(StreanFileTemp);
            end;
          except
          on E: Exception do SetLog('Ошибка отправки файла данных '+E.ClassName + ': ' + E.Message);
          end;
        end
        else
          SetLog('Файл для отправки '+FileNameTmp+' НЕ найден') ;
      end;
    end;
  end;
end;

procedure LoadDataFromStream(StreamIn: TMemoryStream; var DataOut:TLanDataPackage );
var
  StreanFileTemp : TMemoryStream;
  CountFiles, i, SizeFileTmp:integer;
  FileNameTmp:string;
begin
  StreamIn.Position:=0;
  StreamIn.Read(DataOut.CommandStrLen, SizeOf(DataOut.CommandStrLen));
  if(DataOut.CommandStrLen > 0)then begin
    SetLength(DataOut.CommandStr, DataOut.CommandStrLen);
    StreamIn.Read(DataOut.CommandStr[1], DataOut.CommandStrLen * SizeOf(DataOut.CommandStr[1]));
  end else DataOut.CommandStr := '';
  StreamIn.Read(DataOut.CommandParametersLen, SizeOf(DataOut.CommandParametersLen));
  if(DataOut.CommandParametersLen > 0)then begin
    SetLength(DataOut.CommandParameters, DataOut.CommandParametersLen);
    StreamIn.Read(DataOut.CommandParameters[1], DataOut.CommandParametersLen * SizeOf(DataOut.CommandParameters[1]));
  end else DataOut.CommandParameters := '';
  StreamIn.Read(DataOut.CommandDataLen, SizeOf(DataOut.CommandDataLen));
  if(DataOut.CommandStrLen > 0)then begin
    SetLength(DataOut.CommandData, DataOut.CommandDataLen);
    StreamIn.Read(DataOut.CommandData[1], DataOut.CommandDataLen * SizeOf(DataOut.CommandData[1]));
  end else DataOut.CommandData := '';
  StreamIn.Read(DataOut.DataFileNameListLen, SizeOf(DataOut.DataFileNameListLen));
  if DataOut.DataFileNameListLen > 0 then
  begin
    SetLength(DataOut.DataFileNameList, DataOut.DataFileNameListLen);
    StreamIn.Read(DataOut.DataFileNameList[1], DataOut.DataFileNameListLen * SizeOf(DataOut.DataFileNameList[1]));
    SetLog('Получено описание Файлов: '+DataOut.DataFileNameList);
    CountFiles:=GetParseStringCount(DataOut.DataFileNameList);
    if CountFiles > 0 then
    begin
      SetLog('Описано файлов: '+IntToStr(CountFiles));
      for I := 0 to CountFiles-1 do
      begin
        FileNameTmp:= GetParseParameter(GetParseStringParams(DataOut.DataFileNameList, i),0);
        SizeFileTmp:=StrToInt(GetParseParameter(GetParseStringParams(DataOut.DataFileNameList, i),1));
        SetLog('Файл описан '+FileNameTmp + ' размер ' + IntToStr(SizeFileTmp));
        try
          try
            StreanFileTemp:=TMemoryStream.Create;
            StreanFileTemp.CopyFrom(StreamIn,SizeFileTmp);
            StreanFileTemp.SaveToFile(PathHomeProgramm+PathExchangeFolder+FileNameTmp);
            if FileExists(PathHomeProgramm+PathExchangeFolder+FileNameTmp)=True then SetLog('Файл '+PathHomeProgramm+PathExchangeFolder+FileNameTmp+' найден') else SetLog('Файл '+PathHomeProgramm+PathExchangeFolder+FileNameTmp+' НЕ найден') ;
            DataOut.DataFileName:=DataOut.DataFileName+FileNameTmp+';';
          finally
            FreeAndNil(StreanFileTemp);
          end;
        except
          on E: Exception do SetLog('Ошибка получения файла данных '+E.ClassName + ': ' + E.Message);
        end;
      end;
    end;
  end
  else
  begin
    DataOut.DataFileNameList := '';
    DataOut.DataFileNameListLen:=0;
  end;
  //SetLog('Данные LoadFromStream CommandStr '+DataOut.CommandStr+' CommandParameters '+DataOut.CommandParameters+' CommandData '+DataOut.CommandData+' DataFileName '+DataOut.DataFileName+' DataFileNameList '+DataOut.DataFileNameList);
  //SetLog('Данные LoadFromStream CommandStrLen '+IntToStr(DataOut.CommandStrLen)+' CommandParametersLen '+IntToStr(DataOut.CommandParametersLen)+' CommandDataLen '+IntToStr(DataOut.CommandDataLen)+' DataFileNameLen '+IntToStr(DataOut.DataFileNameLen)+' DataFileNameListLen '+IntToStr(DataOut.DataFileNameListLen));
end;

procedure TLanClientEvent.LanClientConnected(Sender: TObject);
begin
inherited;
 //FLanSendRecord_Client.M_Log.Lines.Add('LanClientConnected');
end;

procedure TLanClientEvent.LanClientDisconnected(Sender: TObject);
begin
 //FLanSendRecord_Client.M_Log.Lines.Add('LanClientDisconnected');
end;

function IniFileRead(DParam:string):String;
var
  RFileIni: TIniFile;
begin
  Result:='';
  if FileExists(PathHomeProgramm + 'ConfigFile.ini') then
  begin
    RFileIni:= TIniFile.Create(PathHomeProgramm + 'ConfigFile.ini');
    try
      Result:=Trim(RFileIni.ReadString('Main',DParam,''));
    finally
      RFileIni.Free;
    end;
  end;
end;

function IniFileWrite(DParam,DValue:string):String;
var
  WFileIni: TIniFile;
begin
  Result:='';
  WFileIni:= TIniFile.Create(Trim(PathHomeProgramm) + 'ConfigFile.ini');
  try
    WFileIni.WriteString('Main',DParam,DValue);
    Result:='Данные записаны';
  finally
    WFileIni.Free;
  end;
end;

procedure SetLog(TextLog:string);
var
  LogFile: TextFile;
  LogLevel:string;
  NameLogFile:String;
begin
  NameLogFile:='';
  LogLevel:=Trim(IniFileRead('LogLevel')) ;
  if LogLevel = 'LogOn' then
  begin
    CS_SetLog.Enter;
    if TDirectory.Exists(PathHomeProgramm+'Logs\')=False then TDirectory.CreateDirectory(PathHomeProgramm+'Logs\');
    AssignFile(LogFile, PathHomeProgramm+'Logs\TSCALog_'+FormatDateTime('yyyy-mm-dd',Now)+'.txt');
    if FileExists(PathHomeProgramm+'Logs\TSCALog_'+FormatDateTime('yyyy-mm-dd',Now)+'.txt')=False then
    begin
      ReWrite(LogFile);
      CloseFile(LogFile);
    end;
    Append(LogFile);
    WriteLn(LogFile,FormatDateTime('yyyy-mm-dd hh:nn:ss',Now)+' [TSCA Loader] > '+TextLog);
    CloseFile(LogFile);
    CS_SetLog.Leave;
  end;
end;

procedure TSCAServerExchage;
var
  SendingDataStream: TMemoryStream;
  LanDataPackageSending,LanDataPackageReceiving:TLanDataPackage;
begin
  LanClient:=TLanClient.Create;
  LanClientEvent:=TLanClientEvent.Create;
  try
    LanClient.OnConnected:=LanClientEvent.LanClientConnected;
    LanClient.OnDisconnected:=LanClientEvent.LanClientDisconnected;
    if TSCAServerConect(TSCAServerMain) = false then TSCAServerConect(TSCAServerSecondary);
    sleep(500);
    try
      if LanClient.Connected then
      begin
        LanClient.CheckForGracefulDisconnect(False);
        LanClient.IOHandler.CheckForDisconnect(False,true);
      end;
    except
      on E: Exception do
      begin
        if LanClient.Connected then
        begin
          LanClient.IOHandler.CloseGracefully;
          LanClient.Disconnect;
          SetLog('LanClient Easy Disconnected');
        end;
        SetLog('Ошибка соединения '+E.ClassName + ': ' + E.Message);
      end;
    end;
    if (LanClient <> nil) and (LanClient.Connected) then
    begin
      SetLog('Формирование данных для отправки');
      LanDataPackageSending.CommandStr:='TSCALoader:CheckUpdate;';
      LanDataPackageSending.CommandParameters:='ClientInfoPCNames:'+Trim(ClientInfoPCNames+';'+'ClientInfoUserName:'+ClientInfoUserName+';'+'GetOSInfo:'+Trim(GetOSInfo)+';');
      LanDataPackageSending.CommandData:='TSCALoaderClientVersion:'+IniFileRead('ClientVersion')+';';
      LanDataPackageSending.DataFileName:=Trim('');
      try
        SetLog('Передаваемые данные');
        SetLog('Данные CommandStr: '+LanDataPackageSending.CommandStr);
        SetLog('Данные CommandParameters: '+LanDataPackageSending.CommandParameters);
        SetLog('Данные CommandData: '+LanDataPackageSending.CommandData);
        SetLog('Данные DataFileName: '+LanDataPackageSending.DataFileName);
        try
          SendingDataStream:=TMemoryStream.Create ;
          SaveDataToStream(LanDataPackageSending,SendingDataStream);
          SetLog('Обьем Пакета: '+IntToStr(SizeOf(LanDataPackageSending)));
          SetLog('Обьем Потока: '+IntToStr(SendingDataStream.Size));
          LanClient.IOHandler.Write(SendingDataStream, 0, True);
        finally
          FreeAndNil(SendingDataStream);
        end;
        SetLog('Данные переданы');
      except
        on E: Exception do SetLog('Ошибка передачи данных'+E.ClassName + ': ' + E.Message);
      end;
      sleep(1000);
      try
        SetLog('Под готовка к получению данных');
        try
          SendingDataStream:=TMemoryStream.Create ;
          LanClient.IOHandler.ReadStream(SendingDataStream, -1, False);
          LoadDataFromStream(SendingDataStream,LanDataPackageReceiving);

          SetLog('Обьем Пакета '+IntToStr(SizeOf(LanDataPackageReceiving)));
          SetLog('Обьем Потока '+IntToStr(SendingDataStream.Size));
          SetLog('Данные получены CommandStr: '+LanDataPackageReceiving.CommandStr);
          SetLog('Данные получены CommandParameters: '+LanDataPackageReceiving.CommandParameters);
          SetLog('Данные получены CommandData: '+LanDataPackageReceiving.CommandData);
          SetLog('Данные получены DataFileName: '+LanDataPackageReceiving.DataFileName);
          IniFileWrite('ClientLastUpdate',FormatDateTime('yyyy-mm-dd',Now)) ;
        finally
          FreeAndNil(SendingDataStream);
        end;
        SetLog('Данные получены');
      except
        on E: Exception do SetLog('Ошибка передачи данных'+E.ClassName + ': ' + E.Message);
      end;
    end;
    SetLog('Проверка соединения перед отключением');
    try
      if LanClient.Connected then
      begin
        LanClient.IOHandler.CheckForDisconnect(false,true);
        if not LanClient.IOHandler.InputBufferIsEmpty then LanClient.IOHandler.InputBuffer.Clear;
        LanClient.Disconnect;
        LanClient.Socket.Close;
      end;
    except
      on E: Exception do  SetLog('Ошибка отключение от сервера. '+E.ClassName + ': ' + E.Message);
    end;
  finally
    sleep(500);
    if LanClient <> nil then FreeAndNil(LanClient);
    if LanClientEvent <> nil then FreeAndNil(LanClientEvent);
  end;
end;

function TSCAServerConect(TSCAServerName:string):boolean;
var
  ConnectTimeoutTime, ServerPort:integer;
begin
  Result:=False;
  LanClient.Host:=Trim(TSCAServerName);
  if IniFileRead('ServerPort') <> '' then
  begin
    try
      ServerPort:=StrToInt(IniFileRead('ServerPort'));
    except
      on E: Exception do
      begin
        SetLog('Ошибка определения ServerPort '+E.ClassName + ': ' + E.Message);
        ServerPort:=30380;
      end;
    end;
  end
  else
  begin
    ServerPort:=30380;
  end;
  LanClient.Port:=ServerPort;
  if IniFileRead('ConnectTimeout') <> '' then
  begin
    try
      ConnectTimeoutTime:=StrToInt(IniFileRead('ConnectTimeout'));
    except
      on E: Exception do
      begin
        SetLog('Ошибка определения ConnectTimeout '+E.ClassName + ': ' + E.Message);
        ConnectTimeoutTime:=10000;
      end;
    end;
  end
  else
  begin
    ConnectTimeoutTime:=10000;
  end;
  LanClient.ConnectTimeout:=ConnectTimeoutTime;
  SetLog('Соединение с серверам '+LanClient.Host+' через порт '+IntToStr(LanClient.Port)+' ConnectTimeout '+IntToStr(LanClient.ConnectTimeout));
  try
    LanClient.Connect;
    Sleep(500);
    SetLog('Соединение с сервером '+LanClient.Host+' Установлено');
    Result:=True;
  except
    on E: Exception do
    begin
      SetLog('Ошибка соединение с сервером '+E.ClassName + ': ' + E.Message);
      Result:=False;
    end;
  end;
end;

function GetParseStringParams(SourceString: string; NumberParameter:integer):String;
var
  i:integer;
  StringTemp:string;
begin
  // Формат строки Param01:Value01;Param02:Value02;
  if (Length(SourceString)>0) and
     (Pos(';',SourceString)>0) and
     (NumberParameter <= GetParseStringCount(SourceString)) and
     (GetParseStringCount(SourceString)>0) and
     (NumberParameter>=0)  then
  begin
    for I := 0 to GetParseStringCount(SourceString)-1 do
    begin
      StringTemp :=Copy(SourceString,1,Pos(';',SourceString)-1);
      Delete(SourceString,1,Length(StringTemp)+1);
      if i=NumberParameter then
      begin
        Result :=StringTemp;
        break;
      end;
    end;
  end
  else
  begin
    Result :='';
  end;
end;

function GetParseStringCount(SourceString: string):Integer;
var
  i,ParamCount:integer;
begin
  ParamCount:=0;
  if (Length(SourceString)>0) and (Pos(';',SourceString)>0) then
  begin
    for I := 1 to Length(SourceString) do if SourceString[i] = ';' then inc(ParamCount);
    Result:=ParamCount;
  end
  else
  begin
    Result:=0;
  end;
end;

function GetParseParameter(SourceString: string; ReturnValue:integer):String;
begin
  if (Length(SourceString)>0) and
     (Pos(':',SourceString)>0) and
     (ReturnValue<2) and
     (ReturnValue>-1)then
  begin
    if ReturnValue=0 then Result :=Copy(SourceString,1,Pos(':',SourceString)-1);
    if ReturnValue=1 then Result :=Copy(SourceString,Pos(':',SourceString)+1,Length(SourceString)-Pos(':',SourceString));
  end
  else
    Result:='';
end;

initialization
 CS_SetLog:= TCriticalSection.Create;
 {здесь располагается код инициализации}

finalization
 CS_SetLog.Free;
 {здесь располагается код финализации}

end.
