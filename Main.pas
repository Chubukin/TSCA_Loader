unit Main;

interface
uses
  Winapi.ShellAPI, System.SysUtils, System.IOUtils, Winapi.Windows,
  ExtUnit ;

procedure StartLoader;

var
  PathHomeProgramm, PathExchangeFolder:string;
  TSCAServerMain,TSCAServerSecondary:string;
  ClientInfoUserName, ClientInfoPCNames:string;
  TSCA_LoaderName, TSCA_LoaderPath, TSCA_LoaderVersion:string;

implementation

procedure StartLoader;
var
  ErrorConectionInfo:string;
begin
  TSCA_LoaderVersion:='1.0.0';
  TSCA_LoaderName:='';
  TSCA_LoaderPath:='';
  ErrorConectionInfo:='';
  PathHomeProgramm:= Trim(GetEnvironmentVariable('APPDATA')+'\TSCA_Client\');
  PathExchangeFolder:='';
  TSCA_LoaderPath:=ExtractFilePath(ParamStr(0));
  TSCA_LoaderName:=ExtractFileName(GetModuleName(0));
  ClientInfoUserName:=Trim(GetEnvironmentVariable('USERNAME'));
  ClientInfoPCNames:=Trim(GetEnvironmentVariable('COMPUTERNAME'));
  TSCAServerMain:='80.254.106.235';
  TSCAServerSecondary:='85.198.126.90';
  if TDirectory.Exists(PathHomeProgramm)=False then TDirectory.CreateDirectory(PathHomeProgramm);
  if TDirectory.Exists(PathHomeProgramm+PathExchangeFolder)=False then TDirectory.CreateDirectory(PathHomeProgramm+PathExchangeFolder);
  SetLog('--------------------------------------------------------------------------');
  SetLog('Запуск Loader c ПК '+ClientInfoPCNames+' от имени пользователя '+ClientInfoUserName);
  if IniFileRead('LoaderInit') = '' then
  begin
    IniFileWrite('LoaderInit','On');
    IniFileWrite('LoaderName','');
    IniFileWrite('LoaderPath','');
    IniFileWrite('LoaderVersion','');
    IniFileWrite('LogLevel','LogOff');
    IniFileWrite('ConnectTimeout','');
    IniFileWrite('ServerPort','');
    IniFileWrite('ClientVersion','');
    IniFileWrite('ClientLastUpdate','');
  end;
  if IniFileRead('LoaderName') <> TSCA_LoaderName then IniFileWrite('LoaderName',TSCA_LoaderName) ;
  if IniFileRead('LoaderPath') <> TSCA_LoaderPath then IniFileWrite('LoaderPath',TSCA_LoaderPath) ;
  if IniFileRead('LoaderVersion') <> TSCA_LoaderVersion then IniFileWrite('LoaderVersion',TSCA_LoaderVersion) ;
  SetLog('Обмен с сервером');
  SetLog('Значение ClientLastUpdate '+IniFileRead('ClientLastUpdate')+' Текущая дата '+FormatDateTime('yyyy-mm-dd',Now));
  if IniFileRead('ClientLastUpdate') <> FormatDateTime('yyyy-mm-dd',Now) then
  begin
    SetLog('Начало обмена с сервером');
    TSCAServerExchage;
    SetLog('Окончание обмена с сервером');
  end
  else
  begin
    SetLog('Пропуск обмена с сервером');
  end;
  SetLog('Запуск Клиента');
  if FileExists(PathHomeProgramm+'TSCA_Client.exe')=True then
  begin
    SetLog('Клиент обнаружен и запущен');
    ShellExecute(0,'open',PChar(PathHomeProgramm+'TSCA_Client.exe'),nil,nil,1);
  end
  else
  begin
    SetLog('Клиент не обнаружен');
    ErrorConectionInfo:=ErrorConectionInfo+'Ошибка запуска программы.'+#13#10;
    ErrorConectionInfo:=ErrorConectionInfo+'―――――――――――――――――――――――――――――――'+#13#10;
    ErrorConectionInfo:=ErrorConectionInfo+'Код ошибки: 2'+#13#10;
    ErrorConectionInfo:=ErrorConectionInfo+'Для решения проблемы свяжитесь с нами по почте oai@lubidom.ru или по телефону 8 (8639) 27 76 55';
    MessageBox(0,PChar(ErrorConectionInfo),PChar('TSCA Loader'),MB_ICONERROR+MB_OK+MB_DEFBUTTON2);
  end ;
  SetLog('Остановка Loader');
end;

end.
