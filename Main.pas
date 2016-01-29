unit Main;

interface
uses
  Winapi.ShellAPI, System.SysUtils, System.IOUtils, Winapi.Windows,
  ExtUnit ;

procedure StartLoader;

var
  PathHomeProgramm :string;
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
  TSCA_LoaderPath:=ExtractFilePath(ParamStr(0));
  TSCA_LoaderName:=ExtractFileName(GetModuleName(0));
  ClientInfoUserName:=Trim(GetEnvironmentVariable('USERNAME'));
  ClientInfoPCNames:=Trim(GetEnvironmentVariable('COMPUTERNAME'));
  if TDirectory.Exists(PathHomeProgramm)=False then TDirectory.CreateDirectory(PathHomeProgramm);
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
    IniFileWrite('ServersName','');
    IniFileWrite('ClientVersion','');
    IniFileWrite('ClientLastUpdate','');
    IniFileWrite('ClientFileName','');
    IniFileWrite('ErrConInfo_Type','');
    IniFileWrite('ErrConInfo_Line1','');
    IniFileWrite('ErrConInfo_Line2','');
  end;
  if IniFileRead('LoaderName') <> TSCA_LoaderName then IniFileWrite('LoaderName',TSCA_LoaderName) ;
  if IniFileRead('LoaderPath') <> TSCA_LoaderPath then IniFileWrite('LoaderPath',TSCA_LoaderPath) ;
  if IniFileRead('LoaderVersion') <> TSCA_LoaderVersion then IniFileWrite('LoaderVersion',TSCA_LoaderVersion) ;
  SetLog('Обмен с сервером');
  SetLog('Значение ClientLastUpdate '+IniFileRead('ClientLastUpdate')+' Текущая дата '+FormatDateTime('yyyy-mm-dd',Now));
  if IniFileRead('ClientLastUpdate') <> FormatDateTime('yyyy-mm-dd',Now) then
  begin
    if GetParseStringCount(IniFileRead('ServersName')) > 0 then
    begin
      SetLog('Начало обмена с сервером');
      TSCAServerExchage;
      SetLog('Окончание обмена с сервером');
    end
    else
      SetLog('Не указаны адреса сервера');
  end
  else
  begin
    SetLog('Пропуск обмена с сервером');
  end;
  SetLog('Запуск Клиента');
  if FileExists(PathHomeProgramm+IniFileRead('ClientFileName'))=True then
  begin
    SetLog('Клиент обнаружен и запущен');
    ShellExecute(0,'open',PChar(PathHomeProgramm+IniFileRead('ClientFileName')),nil,nil,1);
  end
  else
  begin
    SetLog('Клиент не обнаружен');
    ErrorConectionInfo:=ErrorConectionInfo+'Ошибка запуска программы.'+#13#10;   // вынос в ини    ErrConInfo_Err
    ErrorConectionInfo:=ErrorConectionInfo+'―――――――――――――――――――――――――――――――'+#13#10;
    ErrorConectionInfo:=ErrorConectionInfo+'Ошибка: '+IniFileRead('ErrConInfo_Type')+#13#10;
    ErrorConectionInfo:=ErrorConectionInfo+IniFileRead('ErrConInfo_Line1')+#13#10;
    ErrorConectionInfo:=ErrorConectionInfo+IniFileRead('ErrConInfo_Line2');
    MessageBox(0,PChar(ErrorConectionInfo),PChar('TSCA Loader'),MB_ICONERROR+MB_OK+MB_DEFBUTTON2);
  end ;
  SetLog('Остановка Loader');
end;

end.
