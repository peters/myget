using System;
using System.IO;

namespace sample.solution.mixedplatforms
{
    internal static class Util
    {
        internal static bool IsX64()
        {
            return IntPtr.Size == 8;
        }
    }

    class Program
    {

        internal static bool IsX64 = IntPtr.Size == 8;

        static void Main()
        {
            var assemblyFolder = Path.GetDirectoryName(typeof(Program).Assembly.Location);
            var nativeFolder = Path.Combine(assemblyFolder, Util.IsX64() ? "x64" : "x86");

            if (!File.Exists(Path.Combine(nativeFolder, "dummy.dll")))
            {
                throw new FileNotFoundException("dummy.dll");
            }

            if (!File.Exists(Path.Combine(nativeFolder, "dummy2.dll")))
            {
                throw new FileNotFoundException("dummy2.dll");
            }

            Console.WriteLine("Success.");

            Environment.Exit(0);
        }

    }
}
