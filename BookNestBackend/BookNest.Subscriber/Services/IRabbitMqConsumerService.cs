using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Subscriber.Services
{
    public interface IRabbitMqConsumerService
    {
        Task StartConsumingAsync();
        Task StopConsumingAsync();
    }
}
