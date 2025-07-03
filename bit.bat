:: This is an example you can edit and use
:: There are numerous parameters you can set, please check Help and Examples folder

@echo off
cd %~dp0
cls

Invoke-WebRequest https://github.com/egg5233/OrionClient_tw/releases/download/1.6.0/OrionClient_win.zip -OutFile OrionClient_win.zip
Expand-Archive OrionClient_win.zip
.\OrionClient_win\OrionClient_win\OrionClient.exe mine -a --pool twbitz --key J5RBZg3WLjXGXLEFypv4hq7D4tBrp2wDFKmg1m1hD6yZ
pause
