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
    public class OrganizerService : BaseCRUDService<OrganizerResponse, Organizer, OrganizerInsertRequest, OrganizerUpdateRequest>, IOrganizerService
    {
        private readonly BookNestDbContext _dbContext;
        public OrganizerService(BookNestDbContext dbContext, IMapper mapper) : base(dbContext, mapper)
        {
            _dbContext = dbContext;
        }

        public override async Task<OrganizerResponse?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        {
            var organizer = await _dbContext.Organizers
                                    .Include(o => o.Events)
                                    .FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

            if(organizer == null)
            {
                return null;
            }

            return MapToResponse(organizer);
        }
    }
}
