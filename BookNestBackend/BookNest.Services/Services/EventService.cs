using AutoMapper;
using BookNest.Model.Requests;
using BookNest.Model.Responses;
using BookNest.Services.BaseServices;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BookNest.Services.Services
{
    public class EventService : BaseCRUDService<EventResponse, Event, EventInsertRequest, EventUpdateRequest>, IEventService
    {
        private readonly BookNestDbContext _dbContext;
        public EventService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        public override async Task<EventResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var eventt = await _dbContext.Events
                               .Include(e => e.EventCategory)
                               .Include(e => e.Organizer)
                               .FirstOrDefaultAsync(e => e.Id == id, cancellationToken);

            if(eventt == null)
            {
                return null;
            }

            return MapToResponse(eventt);
                        
        }

    }
}
