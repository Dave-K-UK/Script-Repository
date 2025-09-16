@Echo Off
REM 	*The Variables*
REM 	ID == Servername
REM 	PID == Process ID (obvious one)
REM	QAST == Question Answer Start type
REM	QAWE == Question Answer Windows Explorer
REM	QASNR == Question Answer Service Not Running

Echo This will Force close and re-start the BES Client -
REM :Loop - to repeat the task without having to re-open
:Loop

REM Scrubbing the variables
Set "ID="
Set "PID="
Set "QAST="
Set "QAWE="
Set "QASNR="

Set /P ID= Please Enter Server Name : 

Ping %ID% -n 1
IF %ERRORLEVEL% NEQ 0 Goto Error

REM Using Taskkill for this as the Besclient service is often crashed
For /f "tokens=1,2 delims=: " %%a in ('sc \\%ID% Queryex Besclient ^| find "PID"') do (
	if "%%a"=="PID" set PID=%%b
)
IF %PID% EQU 0 (
	Goto :NotRunning
) else (
	Echo ****************************
	sc \\%ID% Queryex besclient
	)

Echo ****************************
Taskkill /s \\%ID% /PID %PID% /F

REM :AlreadyDown locator for PID failure catch
:AlreadyDown

Echo ****************************
Set /P QAWE= Do you want to browse via windows explorer to the server? Y/N:
IF /i "%QAWE%"=="Y" (
	Explorer.exe "\\%ID%\c$\Program Files (x86)\BigFix Enterprise\BES Client"
	Echo Opening folder
	Pause
) Else (
	Echo *Not* opening folder-
)

Echo ****************************
Echo the start type is:
Sc \\%ID% qc BESClient | findstr "START_TYPE"
Echo ****************************
Set /P QAST= Is that correct? Y/N:
IF /i "%QAST%"=="N" (
	sc \\%ID% config BESClient start= auto
	Echo Start Type Changed to Auto without Delay
) Else (
	Echo Start Type unchanged
)

Echo ****************************
REM :ServiceWasDown locator for PID failure catch
:ServiceWasDown
Echo Starting Besclient service on %ID%
sc \\%ID% Start Besclient

Echo ******The End (server : %ID%)******
Echo Close the window to end, Or to do another:
Goto Loop

REM :NotRunning catch for PID Failure direction
:NotRunning
Echo Looks like the service isn't running
	Set /P QASNR=Would you like to start the service? Y/N:
	IF /i "%QASNR%"=="Y" (
			Goto ServiceWasDown
		) else (
			Goto AlreadyDown
		)

REM :Error locator to catch servers not responding to ping
:Error
Echo ****************************
Echo That server isnt pinging or is incorrect
Echo Close the window to end, Or try again:
Echo ****************************
Goto Loop
