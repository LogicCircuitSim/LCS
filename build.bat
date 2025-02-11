@echo off
setlocal

echo Remove old love file...
del /F /Q "LCS.love"

echo Zipping files...
"C:\Program Files\7-Zip\7z.exe" a -tzip -aou "LCS.love" ".\main.lua" ".\conf.lua" ".\classes.lua" ".\fancyerror.lua" ".\settings.lua" ".\lib" ".\fonts" 
echo Done!

endlocal
echo Created LCS.love