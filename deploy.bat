@echo off
rem Step 1: Copy 'profiles' folder to the parent directory if missing
if not exist "..\profiles" xcopy ".\profiles\*" "..\profiles" /E /I /H /Q >nul

rem Step 2: Switch to the parent directory before running punktf
pushd ".."
punktf.exe --verbose deploy --source . --profile windows
popd
