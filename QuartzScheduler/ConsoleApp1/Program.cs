// See https://aka.ms/new-console-template for more information
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Quartz;
using Quartz.Impl;
using Serilog;
using System.Collections.Specialized;

namespace ConsoleApp1
{

    class Program
    {
        private static IScheduler _quartzScheduler;

        /********************************/
        /*       Top-Down version       */
        /********************************/
        //public static async Task Main(string[] args)
        //{
        //    _quartzScheduler = ConfigureQuartz();

        //    IJobDetail job = JobBuilder.Create<SimpleJob>()
        //        .WithIdentity("simpleJob", "quartzExamples")
        //        .Build();

        //    ITrigger trigger = TriggerBuilder.Create()
        //        .WithIdentity("testTrigger", "quartzExamples")
        //        .StartNow()
        //        .WithSimpleSchedule(x => x.WithIntervalInSeconds(5).WithRepeatCount(5))
        //        .Build();

        //    Console.WriteLine("Running Scheduler ...");
        //    await _quartzScheduler.ScheduleJob(job, trigger);

        //    Console.ReadKey(true);
        //    await _quartzScheduler.Shutdown();

        //    Console.WriteLine("... Scheduler Finished");
        //}

        /********************************/
        /* Dependency Injection version */
        /********************************/
        public static async Task Main(string[] args)
        {
            var builder = new ConfigurationBuilder();
            BuildCOnfig(builder);

            _quartzScheduler = ConfigureQuartz();

            Log.Logger = new LoggerConfiguration()
                .ReadFrom.Configuration(builder.Build())
                .Enrich.FromLogContext()
                .WriteTo.Console()
                .CreateLogger();

            Log.Logger.Information("Registered Serilog service");

            var host = Host.CreateDefaultBuilder()
                .ConfigureServices((context, services) =>
                {
                    services.AddTransient<ISchedulingService, SchedulingService>();
                    services.AddSingleton(provider => _quartzScheduler);

                })
                .UseSerilog()
                .Build();

            Log.Logger.Information("Registered Scheduling service");
            Log.Logger.Information("Registered Quartz Scheduler");

            var svc = ActivatorUtilities.CreateInstance<SchedulingService>(host.Services);

            Log.Logger.Information("Running Scheduler ...");

            svc.Run();

            Console.ReadKey(true);
            
            await _quartzScheduler.Shutdown();

            Log.Logger.Information("... Scheduler Finished");
        }


        static void BuildCOnfig(IConfigurationBuilder builder)
        {
            builder.SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .AddJsonFile($"appsettings.{Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "production"}.json", optional: true)
                .AddEnvironmentVariables();
        }

        static IScheduler ConfigureQuartz()
        {
            NameValueCollection props = new NameValueCollection{
                { "Quartz.serializer.type", "binary" }
            };

            StdSchedulerFactory factory = new StdSchedulerFactory(props);
            var scheduler = factory.GetScheduler().Result;
            scheduler.Start().Wait();

            return scheduler;
        }

        private void OnShutDown()
        {
            if (!_quartzScheduler.IsShutdown) _quartzScheduler.Shutdown();
        }
    }
}