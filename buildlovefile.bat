@echo off
setlocal

echo Remove old love file...
del /F /Q "LCS.love"

echo Zipping files...
"C:\Program Files\7-Zip\7z.exe" a -tzip "LCS.love" ".\*"
echo Done!

endlocal
echo Created LCS.love