using System;
using System.IO;
using NUnit.Framework;

namespace sample.solution.anycpu
{
    class Program
    {
        static void Main()
        {
            var assemblyFolder = Path.GetDirectoryName(typeof(Program).Assembly.Location);
            
            Assert.That(File.Exists(Path.Combine(assemblyFolder, "nunit.framework.dll")), Is.True);

            Console.WriteLine("Success.");

            Environment.Exit(0);
        }
    }
}
