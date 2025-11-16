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
    public class EventCategoryService : BaseCRUDService<EventCategoryResponse, EventCategory, EventCategoryInsertRequest, EventCategoryUpdateRequest>, IEventCategoryService
    {
        private readonly BookNestDbContext _dbContext;
        public EventCategoryService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
            
        }

        public override async Task<EventCategoryResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var eventCategory = await _dbContext.EventCategories
                                      .Include(ec => ec.Events)
                                      .FirstOrDefaultAsync(ec => ec.Id == id, cancellationToken);

            if(eventCategory == null)
            {
                return null;
            }

            return MapToResponse(eventCategory);
        }
    }
}
