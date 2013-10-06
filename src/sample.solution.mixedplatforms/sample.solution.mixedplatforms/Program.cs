using System;
using System.IO;
using NUnit.Framework;

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

            Assert.That(File.Exists(Path.Combine(assemblyFolder, "nunit.framework.dll")), Is.True);
            Assert.That(File.Exists(Path.Combine(nativeFolder, "dummy.dll")), Is.True);
            Assert.That(File.Exists(Path.Combine(nativeFolder, "dummy2.dll")), Is.True);

            Environment.Exit(0);
        }

    }
}
