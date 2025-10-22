@echo off
REM Muda para o diretório onde o script está localizado
cd /d "%~dp0"

REM Configuração do projeto
set OSSCAD=C:\oss-cad-suite
set TOP=top
set LPF=colorlight_i9.lpf
set PACKAGE=CABGA381
set BUILDDIR=build
REM Adicione a lista de fontes (ex.: top.sv e tico.sv)
setlocal enabledelayedexpansion
set SRCS=
for %%F in (*.sv) do set SRCS=!SRCS! "%%F"
REM Verifica argumentos
if "%1"=="" goto :menu
if /i "%1"=="synth" goto :synth
if /i "%1"=="pnr" goto :pnr
if /i "%1"=="bitstream" goto :bitstream
if /i "%1"=="flash" goto :flash
if /i "%1"=="all" goto :all
if /i "%1"=="clean" goto :clean
if /i "%1"=="check" goto :check
echo Opcao invalida: %1
goto :menu

:menu
echo ============================================================
echo Build System - Colorlight i9
echo ============================================================
echo.
echo Opcoes disponiveis:
echo   build.bat synth      - Apenas sintese (Yosys)
echo   build.bat pnr        - Sintese + Place and Route
echo   build.bat bitstream  - Gera bitstream completo
echo   build.bat flash      - Grava bitstream existente
echo   build.bat all        - Fluxo completo + gravacao
echo   build.bat clean      - Limpa arquivos de build
echo   build.bat check      - Verifica ferramentas
echo.
echo   build.bat            - Mostra este menu
echo ============================================================
pause
exit /b 0

:check
echo ============================================================
echo Verificando instalacao...
echo ============================================================
call "%OSSCAD%\environment.bat" 
if errorlevel 1 (
    echo ERRO: OSS CAD Suite nao encontrado em %OSSCAD%
    goto :erro
)
echo Verificando yosys...
yosys -V
echo Verificando nextpnr-ecp5...
nextpnr-ecp5 --version
echo Verificando ecppack...
ecppack --help >nul 2>&1
echo Verificando openFPGALoader...
openFPGALoader --help >nul 2>&1
echo.
echo Todas as ferramentas encontradas!
pause
exit /b 0

:clean
echo ============================================================
echo Limpando arquivos de build...
echo ============================================================
if exist "%BUILDDIR%" (
    rmdir /s /q "%BUILDDIR%"
    echo Pasta %BUILDDIR% removida
) else (
    echo Nada para limpar
)
pause
exit /b 0

:synth
echo ============================================================
echo [1/3] Yosys - Sintese...
echo ============================================================
call "%OSSCAD%\environment.bat" 
if not exist "%BUILDDIR%" mkdir "%BUILDDIR%"
yosys -p "read_verilog -sv %SRCS%; synth_ecp5 -top %TOP% -json %BUILDDIR%\%TOP%.json"
if errorlevel 1 goto :erro
echo Sintese concluida: %BUILDDIR%\%TOP%.json
if "%1"=="synth" pause
exit /b 0

:pnr
call :synth
echo ============================================================
echo [2/3] nextpnr-ecp5 - Place and Route...
echo ============================================================
nextpnr-ecp5 --json %BUILDDIR%\%TOP%.json --lpf %LPF% --textcfg %BUILDDIR%\%TOP%.config --45k --package %PACKAGE% --speed 6 --freq 25
if errorlevel 1 goto :erro
echo Place and Route concluido: %BUILDDIR%\%TOP%.config
if "%1"=="pnr" pause
exit /b 0

:bitstream
call :pnr
echo ============================================================
echo [3/3] ecppack - Gerando bitstream...
echo ============================================================
ecppack %BUILDDIR%\%TOP%.config %BUILDDIR%\%TOP%.bit
if errorlevel 1 goto :erro
echo Bitstream gerado: %BUILDDIR%\%TOP%.bit
if "%1"=="bitstream" pause
exit /b 0

:flash
call "%OSSCAD%\environment.bat"
if not exist "%BUILDDIR%\%TOP%.bit" (
    echo ERRO: %BUILDDIR%\%TOP%.bit nao existe!
    echo Execute: build.bat bitstream
    goto :erro
)
echo ============================================================
echo Gravando na FPGA...
echo ============================================================
echo Arquivo: %BUILDDIR%\%TOP%.bit
openFPGALoader.exe -b colorlight-i9 --unprotect-flash -f -v "%BUILDDIR%\%TOP%.bit"
if errorlevel 1 goto :erro
echo Gravacao concluida!
pause
exit /b 0

:all
call :bitstream
call :flash
echo ============================================================
echo Processo completo finalizado com sucesso!
echo ============================================================
pause
exit /b 0

:erro
echo ============================================================
echo ERRO no processo!
echo ============================================================
pause
exit /b 1