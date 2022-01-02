using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Runtime.InteropServices;
using RGiesecke.DllExport;

/* Requires Robert Giesecke's Unmanaged Exports library (https://www.nuget.org/packages/UnmanagedExports)
  
 * To install Unmanaged Exports (DllExport for .Net), run the following command in the Package Manager Console:

 * PM> Install-Package UnmanagedExports
*/

[UnmanagedFunctionPointerAttribute(CallingConvention.StdCall)]
public delegate void nbAddActionDel(int IDNum, string Name, string Hint, byte[] Params, byte NumParams1, byte NumParams2);

[UnmanagedFunctionPointerAttribute(CallingConvention.StdCall)]
public delegate void nbAddFileDel(string FileName, bool AddFlag);

[UnmanagedFunctionPointerAttribute(CallingConvention.StdCall)]
public delegate void nbGetVarDel(string VarName, out string Value);

[UnmanagedFunctionPointerAttribute(CallingConvention.StdCall)]
public delegate void nbSetVarDel(string VarName, string Value);

namespace neoBookPluginExample
{
    public class Class1
    {
        //parameter types for actions
        const byte ACTIONPARAM_NONE = 0, 
                   ACTIONPARAM_ALPHA = 1, 
                   ACTIONPARAM_ALPHASP = 2, 
                   ACTIONPARAM_NUMERIC = 3, 
                   ACTIONPARAM_MIXED = 4, 
                   ACTIONPARAM_FILENAME = 5, 
                   ACTIONPARAM_VARIABLE = 6, 
                   ACTIONPARAM_DATAFILE = 7;

        public static nbSetVarDel nbSetVar = null;
        public static nbGetVarDel nbGetVar = null;

        [DllExport("_nbInitPlugIn")]
        public static void _nbInitPlugIn(IntPtr WinHandle, out string PlugInTitle, out string PlugInPublisher, out string PlugInHint)
        {
            PlugInTitle = "Sample C# PlugIn";
            PlugInPublisher = "NeoSoft";
            PlugInHint = "Use this plug-in to display a Windows message box.";
        }

        [DllExport("_nbAbout")]
        public static void _nbAbout()
        {
            //display this plugin's about box
            Form frmAbout = new AboutBox1();
            frmAbout.ShowDialog();
        }
        
        [DllExport("_nbRegisterPlugIn")]
        public static void _nbRegisterPlugIn(nbAddActionDel AddActionProc, nbAddFileDel AddFileProc, nbGetVarDel VarGetFunc, nbSetVarDel VarSetFunc)
        {
            nbGetVar = VarGetFunc;
            nbSetVar = VarSetFunc;

            //action called csharpMessageBox with two string parameters:
            AddActionProc(1, "csharpMessageBox", "Display a simple Windows message box.", new byte[] { ACTIONPARAM_ALPHA, ACTIONPARAM_ALPHA }, 2, 2);

            //add additional actions here...
        }

        [DllExport("_nbExecAction")]
        public static bool _nbExecAction(int IDNum, IntPtr pParams)
        {
            //convert pchar (pParams) sent from NeoBook to C# string array (cParams)
            string[] cParams = new string[10];
            int j = 0;
            do
              {
                cParams[j] = Marshal.PtrToStringAnsi(Marshal.ReadIntPtr(pParams, 4 * j));
                j++;
              } while (cParams[j - 1] != null);

            //execute the action
            switch (IDNum)
            {
                case 1:
                   //display the message box with user's parameters
                   MessageBox.Show(cParams[0], cParams[1], MessageBoxButtons.OK, MessageBoxIcon.Exclamation);
                   break;
                case 2:
                   //future action
                   break;
            }
            return true;
        }

    }
}
