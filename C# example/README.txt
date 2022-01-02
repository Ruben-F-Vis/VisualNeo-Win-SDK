---Prerequisites:

Visual Studio 2015 (can be any edition like Pro and Community--- I'm using Community, which is free).

---Setting up:

Place CSharpNeoBookPlugInTemplate.zip (yes the zip file, don't extract it!) in %USERPROFILE%\Documents\Visual Studio 2015\Templates\ProjectTemplates (%USERPROFILE% is an environment variable for windows that is DRIVELETTER:\Users\USERNAME)
Launch Visual Studio 2015 and go to File -> New -> Project...
Expand Templates -> Other Languages and select Visual C#
Select .NET Framework 4.5 at the top-left dropdown box
Find and select NeoBookPlugIn in the list then give the appropriate project name of your choice and click OK

---For building:

Go to Build -> Configuration Manager
Set Configuration for your project in the list to Release and set the Active solution configuration to Release then set Platform for your project in the list to x86 and set the Active solution platform to x86
Right-click on the project (not the solution) in Solution Explorer and click Properties. Click on the Build Events tab then put ren $(TargetPath) $(TargetName).nbp in the Post-build event command line input box. This is so the output file is renamed from projectname.dll to projectname.nbp when the project has finished compiling.
Make sure Solution projectname (1 Project) is selected by clicking on it once (in Solution Explorer toolbar at the left)
Click on Build -> Build Solution
If successful (and you followed the steps for Setting Up and Build correctly), you should get ========== Build: 1 succeeded, 0 failed, 0 up-to-date, 0 skipped ========== in the Output toolbar at the bottom. You can find the compiled plugin in %USERPROFILE%\Documents\Visual Studio 2015\Projects\projetname\projectname\bin\x86\Release as projectname.nbp which you can install it from VisualNeoWin.

---Notes:

If you want a custom icon for your plugin, make a file called package.ico and make it a 32x32 windows icon file. Then, edit it with your favorite image editing software (like Paint.NET or GIMP) to add your icon resized to 32x32 and save it. Make sure your package.ico is at the root folder of your project (where the projectname.csproj file is located at). Now, right-click on the project (not the solution) in Solution Explorer and click Properties. Click on the Application tab then in the Resources sub-section, click the ... button next to the icon input field then browse to your package.ico and select it.
