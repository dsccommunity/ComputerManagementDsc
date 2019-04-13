// This file enables setting of the machine time zone
// using .NET framework classes.
// It can be used to set the time zone when the
// PowerShell time zone cmdlets are not available.
//
// It creates a namespace Microsoft.PowerShell.TimeZone
// containing the classes and structures required to
// set the time zone.
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Security;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Microsoft.PowerShell.TimeZone
{
    [StructLayoutAttribute(LayoutKind.Sequential)]
    public struct SystemTime
    {
        [MarshalAs(UnmanagedType.U2)]
        public short Year;
        [MarshalAs(UnmanagedType.U2)]
        public short Month;
        [MarshalAs(UnmanagedType.U2)]
        public short DayOfWeek;
        [MarshalAs(UnmanagedType.U2)]
        public short Day;
        [MarshalAs(UnmanagedType.U2)]
        public short Hour;
        [MarshalAs(UnmanagedType.U2)]
        public short Minute;
        [MarshalAs(UnmanagedType.U2)]
        public short Second;
        [MarshalAs(UnmanagedType.U2)]
        public short Milliseconds;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct TimeZoneInformation
    {
        [MarshalAs(UnmanagedType.I4)]
        public int Bias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 0x20)]
        public string StandardName;
        public SystemTime StandardDate;
        [MarshalAs(UnmanagedType.I4)]
        public int StandardBias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 0x20)]
        public string DaylightName;
        public SystemTime DaylightDate;
        [MarshalAs(UnmanagedType.I4)]
        public int DaylightBias;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DynamicTimeZoneInformation
    {
        public int Bias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string StandardName;
        public SystemTime StandardDate;
        public int StandardBias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string DaylightName;
        public SystemTime DaylightDate;
        public int DaylightBias;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string TimeZoneKeyName;
        [MarshalAs(UnmanagedType.U1)]
        public bool DynamicDaylightTimeDisabled;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct RegistryTimeZoneInformation
    {
        [MarshalAs(UnmanagedType.I4)]
        public int Bias;
        [MarshalAs(UnmanagedType.I4)]
        public int StandardBias;
        [MarshalAs(UnmanagedType.I4)]
        public int DaylightBias;
        public SystemTime StandardDate;
        public SystemTime DaylightDate;
        public RegistryTimeZoneInformation(TimeZoneInformation tzi)
        {
            this.Bias = tzi.Bias;
            this.StandardDate = tzi.StandardDate;
            this.StandardBias = tzi.StandardBias;
            this.DaylightDate = tzi.DaylightDate;
            this.DaylightBias = tzi.DaylightBias;
        }
        public RegistryTimeZoneInformation(byte[] bytes)
        {
            if ((bytes == null) || (bytes.Length != 0x2c))
            {
                throw new ArgumentException("Argument_InvalidREG_TZI_FORMAT");
            }
            this.Bias = BitConverter.ToInt32(bytes, 0);
            this.StandardBias = BitConverter.ToInt32(bytes, 4);
            this.DaylightBias = BitConverter.ToInt32(bytes, 8);
            this.StandardDate.Year = BitConverter.ToInt16(bytes, 12);
            this.StandardDate.Month = BitConverter.ToInt16(bytes, 14);
            this.StandardDate.DayOfWeek = BitConverter.ToInt16(bytes, 0x10);
            this.StandardDate.Day = BitConverter.ToInt16(bytes, 0x12);
            this.StandardDate.Hour = BitConverter.ToInt16(bytes, 20);
            this.StandardDate.Minute = BitConverter.ToInt16(bytes, 0x16);
            this.StandardDate.Second = BitConverter.ToInt16(bytes, 0x18);
            this.StandardDate.Milliseconds = BitConverter.ToInt16(bytes, 0x1a);
            this.DaylightDate.Year = BitConverter.ToInt16(bytes, 0x1c);
            this.DaylightDate.Month = BitConverter.ToInt16(bytes, 30);
            this.DaylightDate.DayOfWeek = BitConverter.ToInt16(bytes, 0x20);
            this.DaylightDate.Day = BitConverter.ToInt16(bytes, 0x22);
            this.DaylightDate.Hour = BitConverter.ToInt16(bytes, 0x24);
            this.DaylightDate.Minute = BitConverter.ToInt16(bytes, 0x26);
            this.DaylightDate.Second = BitConverter.ToInt16(bytes, 40);
            this.DaylightDate.Milliseconds = BitConverter.ToInt16(bytes, 0x2a);
        }
    }
    public class TokenPrivilegesAccess
    {
        [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
        public static extern int OpenProcessToken(int ProcessHandle, int DesiredAccess,
        ref int tokenhandle);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        public static extern int GetCurrentProcess();
        [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
        public static extern int LookupPrivilegeValue(string lpsystemname, string lpname,
        [MarshalAs(UnmanagedType.Struct)] ref LUID lpLuid);
        [DllImport("advapi32.dll", CharSet = CharSet.Auto)]
        public static extern int AdjustTokenPrivileges(int tokenhandle, int disableprivs,
            [MarshalAs(UnmanagedType.Struct)]ref TOKEN_PRIVILEGE Newstate, int bufferlength,
            int PreivousState, int Returnlength);
        public const int TOKEN_ASSIGN_PRIMARY = 0x00000001;
        public const int TOKEN_DUPLICATE = 0x00000002;
        public const int TOKEN_IMPERSONATE = 0x00000004;
        public const int TOKEN_QUERY = 0x00000008;
        public const int TOKEN_QUERY_SOURCE = 0x00000010;
        public const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
        public const int TOKEN_ADJUST_GROUPS = 0x00000040;
        public const int TOKEN_ADJUST_DEFAULT = 0x00000080;
        public const UInt32 SE_PRIVILEGE_ENABLED_BY_DEFAULT = 0x00000001;
        public const UInt32 SE_PRIVILEGE_ENABLED = 0x00000002;
        public const UInt32 SE_PRIVILEGE_REMOVED = 0x00000004;
        public const UInt32 SE_PRIVILEGE_USED_FOR_ACCESS = 0x80000000;
        public static bool EnablePrivilege(string privilege)
        {
            try
            {
                int token = 0;
                int retVal = 0;
                TOKEN_PRIVILEGE TP = new TOKEN_PRIVILEGE();
                LUID LD = new LUID();
                retVal = OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref token);
                retVal = LookupPrivilegeValue(null, privilege, ref LD);
                TP.PrivilegeCount = 1;
                var luidAndAtt = new LUID_AND_ATTRIBUTES();
                luidAndAtt.Attributes = SE_PRIVILEGE_ENABLED;
                luidAndAtt.Luid = LD;
                TP.Privilege = luidAndAtt;
                retVal = AdjustTokenPrivileges(token, 0, ref TP, 1024, 0, 0);
                return true;
            }
            catch
            {
                return false;
            }
        }
        public static bool DisablePrivilege(string privilege)
        {
            try
            {
                int token = 0;
                int retVal = 0;
                TOKEN_PRIVILEGE TP = new TOKEN_PRIVILEGE();
                LUID LD = new LUID();
                retVal = OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref token);
                retVal = LookupPrivilegeValue(null, privilege, ref LD);
                TP.PrivilegeCount = 1;
                // TP.Attributes should be none (not set) to disable privilege
                var luidAndAtt = new LUID_AND_ATTRIBUTES();
                luidAndAtt.Luid = LD;
                TP.Privilege = luidAndAtt;
                retVal = AdjustTokenPrivileges(token, 0, ref TP, 1024, 0, 0);
                return true;
            }
            catch
            {
                return false;
            }
        }
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct LUID
    {
        internal uint LowPart;
        internal uint HighPart;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct LUID_AND_ATTRIBUTES
    {
        internal LUID Luid;
        internal uint Attributes;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct TOKEN_PRIVILEGE
    {
        internal uint PrivilegeCount;
        internal LUID_AND_ATTRIBUTES Privilege;
    }
    public class TimeZone
    {
        public const int ERROR_ACCESS_DENIED = 0x005;
        public const int CORSEC_E_MISSING_STRONGNAME = -2146233317;
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern bool SetTimeZoneInformation([In] ref TimeZoneInformation lpTimeZoneInformation);
        [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
        private static extern bool SetDynamicTimeZoneInformation([In] ref DynamicTimeZoneInformation lpTimeZoneInformation);
        public static void Set(string name)
        {
            var regTimeZones = Registry.LocalMachine.OpenSubKey("SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones");
            var subKey = regTimeZones.GetSubKeyNames().Where(s => s == name).First();
            string daylightName = (string)regTimeZones.OpenSubKey(subKey).GetValue("Dlt");
            string standardName = (string)regTimeZones.OpenSubKey(subKey).GetValue("Std");
            byte[] tzi = (byte[])regTimeZones.OpenSubKey(subKey).GetValue("TZI");
            var regTzi = new RegistryTimeZoneInformation(tzi);
            TokenPrivilegesAccess.EnablePrivilege("SeTimeZonePrivilege");
            bool didSet;
            if (Environment.OSVersion.Version.Major < 6)
            {
                var tz = new TimeZoneInformation();
                tz.Bias = regTzi.Bias;
                tz.DaylightBias = regTzi.DaylightBias;
                tz.StandardBias = regTzi.StandardBias;
                tz.DaylightDate = regTzi.DaylightDate;
                tz.StandardDate = regTzi.StandardDate;
                tz.DaylightName = daylightName;
                tz.StandardName = standardName;
                didSet = TimeZone.SetTimeZoneInformation(ref tz);
            }
            else
            {
                var tz = new DynamicTimeZoneInformation();
                tz.Bias = regTzi.Bias;
                tz.DaylightBias = regTzi.DaylightBias;
                tz.StandardBias = regTzi.StandardBias;
                tz.DaylightDate = regTzi.DaylightDate;
                tz.StandardDate = regTzi.StandardDate;
                tz.DaylightName = daylightName;
                tz.StandardName = standardName;
                tz.TimeZoneKeyName = subKey;
                tz.DynamicDaylightTimeDisabled = false;
                didSet = TimeZone.SetDynamicTimeZoneInformation(ref tz);
            }
            int lastError = Marshal.GetLastWin32Error();
            TokenPrivilegesAccess.DisablePrivilege("SeTimeZonePrivilege");
            if (! didSet)
            {
                if (lastError == TimeZone.ERROR_ACCESS_DENIED)
                {
                    throw new SecurityException("Access denied changing System TimeZone.");
                }
                else if (lastError == TimeZone.CORSEC_E_MISSING_STRONGNAME)
                {
                    throw new SystemException("Application is not signed.");
                }
                else
                {
                    throw new SystemException("Win32Error: " + lastError + "\nHRESULT: " + Marshal.GetHRForLastWin32Error());
                }
            }
        }
    }
}
