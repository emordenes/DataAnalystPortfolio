// See https://aka.ms/new-console-template for more information
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Quartz;

namespace ConsoleApp1
{
    public class SchedulingService : ISchedulingService
    {
        private readonly ILogger<SchedulingService> _log;
        private readonly IConfiguration _config;
        private readonly IScheduler _scheduler;

        public SchedulingService(ILogger<SchedulingService> log, IConfiguration config, IScheduler scheduler)
        {
            _log = log;
            _config = config;
            _scheduler = scheduler;
        }

        public async void Run()
        {
            IJobDetail job = JobBuilder.Create<SimpleJobDI>()
                .WithIdentity("simpleJob", "quartzExamples")
                .Build();

            _log.LogInformation("Created job : simpleJob");

            ITrigger trigger = TriggerBuilder.Create()
                .WithIdentity("testTrigger", "quartzExamples")
                .StartNow()
                .WithSimpleSchedule(x => x.WithIntervalInSeconds(_config.GetValue<int>("LoopSeconds")).WithRepeatCount(_config.GetValue<int>("LoopTimes")))
                .Build();

            _log.LogInformation($"Created trigger : testTrigger -> LoopSeconds {_config.GetValue<int>("LoopSeconds")} -> LoopTimes {_config.GetValue<int>("LoopTimes")}");

            await _scheduler.ScheduleJob(job, trigger);

        }
    }
}