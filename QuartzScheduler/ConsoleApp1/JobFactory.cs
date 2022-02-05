using Quartz;
using Quartz.Simpl;
using Quartz.Spi;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ConsoleApp1
{
    internal class JobFactory : SimpleJobFactory
    {
        private readonly IServiceProvider _provider;

        public JobFactory(IServiceProvider provider)
        {
            _provider = provider;
        }

        public override IJob NewJob(TriggerFiredBundle bundle, IScheduler scheduler)
        {
            //return base.NewJob(bundle, scheduler);

            try
            {
                // this will inject dependencies that the job requires
                return (IJob)this._provider.GetService(bundle.JobDetail.JobType);
            }
            catch (Exception)
            {

                throw new SchedulerException();
            }
        }
    }
}
