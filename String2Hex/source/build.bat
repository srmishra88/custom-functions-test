@rem parse input arguments
@set sourceFile=
@set dataSize=
@set installationDir=
@set vcvarDir=
@set originalPath=
@echo off
:loop
if "%1"=="" goto endloop
if "%1"=="-file"            set "sourceFile=%~2" && goto parseNextArg
if "%1"=="-dmxInstallDir"   set "installationDir=%~2" && goto parseNextArg
if "%1"=="-bit"             set "dataSize=%~2" && goto parseNextArg
if "%1"=="-compilerDir"     set "vcvarDir=%~2" && goto parseNextArg
goto printUsageAndExit
 
:parseNextArg 
shift
shift
goto loop

:endloop
@set originalPath=%PATH%
@call :validateSourceFile || goto :error
@call :validateCompilerLocation || goto :error
@call :validateInstallDir || goto :error
@call :setUpBuildDir || goto :error
@call :validateBitVersion || goto :error
@call :setupCompiler || goto :error
@call :compileAndLink || goto :error
@if %dataSize%==32 goto end 
@rem build both 64|32 version of library for 64 bit dmexpress
@set dataSize=32
@call :setupCompiler || goto :error
@call :compileAndLink || goto :error
@goto end

:compileAndLink
@set libraryName=%sourceFile:~0,-4%
@set targetFile=%libraryName%_%dataSize%.dll
@if exist %targetFile% @del /F %targetFile%
@call cl "%sourceFile%" /EHa /MD /c /I"%installationDir%\Include" /Fo"%buildDir%\%libraryName%.obj" || exit /B 1
@call link /dll /out:"%buildDir%\%targetFile%" "%buildDir%\%libraryName%.obj" || exit /B 1
@call mt -manifest "%buildDir%\%targetFile%.manifest" -outputresource:"%buildDir%\%targetFile%;#2" || exit /B 1
@copy "%buildDir%\%targetFile%" "%currentDir%"
@echo Build %targetFile% successfully
@echo.
goto:eof 

:validateSourceFile
@if "%sourceFile%"=="" goto printUsageAndExit
@if not exist "%sourceFile%" ( 
            echo Cannot find the source file "%sourceFile%"
            exit /B 1)
@exit /B 0
goto:eof 

:validateCompilerLocation 
@if "%vcvarDir%"=="" goto printUsageAndExit
@if not exist "%vcvarDir%" (
                echo Cannot find the compiler directory "%vcvarDir%"
                exit /B 1)
@set vcvarBatch=%vcvarDir%\vcvarsall.bat
@if not exist "%vcvarBatch%" (
                echo Cannot find the "%vcvarBatch%" script in the compiler directory.
                exit /B 1)
@echo Use compiler from "%vcvarDir%"
@exit /B 0
goto:eof 

:validateInstallDir
@if not exist "%installationDir%" set installationDir=C:\Program Files\DMExpress
@if not exist "%installationDir%" set installationDir=C:\Program Files (x86)\DMExpress
@if not exist "%installationDir%" goto dmxInstallDirNotFound
@set headerFilePath=%installationDir%\Include\dmx_custom_functions.h
@if not exist "%headerFilePath%" goto headerFileMissing
@echo Use header file "%headerFilePath%" for the build
goto:eof 

:validateBitVersion
@if "%dataSize%"=="" call :autoDetectBitVersion || goto autoDetectFailed
@if "%dataSize%" neq "32" if "%dataSize%" neq "64" goto printUsageAndExit
goto:eof 

:setUpBuildDir
@set currentDir="%cd%"
@set currentDir=%currentDir:~1,-1%
@set buildDir="%currentDir%\build"
@set buildDir=%buildDir:~1,-1%
@if exist "%buildDir%" @rmdir /s /q "%buildDir%"
@mkdir "%buildDir%"
goto:eof 

:autoDetectBitVersion
@set dmexpressExe=%installationDir%\Programs\DMExpress.exe
@if not exist "%dmexpressExe%" exit /B 1
@echo off
@set tmpFile=%buildDir%\tmp
@if exist "%tmpFile%" @del /F "%tmpFile%"
"%dmexpressExe%" dummy >"%tmpFile%" 2>&1
findstr /C:64-bit "%tmpFile%" >NUL
@if %errorlevel% equ 0 ( set dataSize=64
                        exit /B 0)
findstr /C:32-bit "%tmpFile%" >NUL
if %errorlevel% equ 0 ( set dataSize=32
                        exit /B 0)
@exit /B 1
goto:eof 

:setupCompiler
@if %dataSize%==32 ( call "%vcvarBatch%" x86 || goto compilerSetupFailed
                    ) else ( call "%vcvarBatch%" x64 || goto compilerSetupFailed )
@set compiler=cl
@where %compiler%> NUL 2>&1
@if %errorlevel% neq 0 goto compilerNotFound
@exit /B 0
goto:eof 

:dmxInstallDirNotFound
@echo Cannot detect the DMExpress installation directory. Please specify the DMExpress installation directory with the '-dmxInstallDir' option.
@exit /B 1

:headerFileMissing
@echo Cannot find the mandatory header file "%headerFilePath%"
@exit /B 1

:compilerNotFound
@echo Cannot find the compiler cl.exe in the directory or in the path
@exit /B 1
:autoDetectFailed
@echo Failed to auto-detect the bit level of DMExpress. Please specify the bit level of the library with the '-bit' option.
@exit /B 1

:compilerSetupFailed
@if %dataSize%==32 ( set option=x86) else ( set option=x64)
@echo Failed to set up the C++ compiler. Please specify a different compiler directory or make sure the command "%vcvarBatch% %option%" can run successfully.
@exit /B 1

:printUsageAndExit
@echo Usage: build -file ^<fileName^> -compilerDir ^<compilerDirectory^> [-dmxInstallDir ^<installDirectory^>] [-bit 32^|64]
@echo.
@echo Example:
@echo build -file SampleCustomFunctions.cpp -compilerDir "C:\Program Files (x86)\Microsoft Visual Studio 9.0\VC"
@echo.
@echo build -file FileA.cpp -compilerDir "C:\Program Files (x86)\Microsoft Visual Studio 8.0\VC" -dmxInstallDir "D:\My Program\DMExpress"
@echo.
@echo build -file FileB.cpp -compilerDir "C:\Program Files (x86)\Microsoft Visual Studio 10.0\VC" -dmxInstallDir D:\Tmp\DMExpress -bit 64
@exit /B 1

:end
@set PATH=%originalPath%
@exit /B 0

:error
@set PATH=%originalPath%
@exit /B %errorlevel%