using Microsoft.Extensions.Logging;
using Quartz;
using Serilog;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApp1
{
    internal class SimpleJob : IJob
    {
        public async Task Execute(IJobExecutionContext context)
        {
            var message = $"Simple Job - Execute at {DateTime.Now.ToString()}";
            Console.WriteLine(message);
        }
    }

    internal class SimpleJobDI : IJob
    {
        public async Task Execute(IJobExecutionContext context)
        {
            var message = $"Simple Job DI - Execute at {DateTime.Now.ToString()}";
            Log.Logger.Information(message);
        }
    }
}
