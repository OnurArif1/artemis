using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class PersonService : IPersonService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public PersonService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdatePersonViewModel viewModel)
    {
        var person = new Person()
        {
            PartyName = viewModel.PartyName,
            PartyType = viewModel.PartyType,
            IsBanned = viewModel.IsBanned,
            DeviceId = viewModel.DeviceId
        };

        await _artemisDbContext.Persons.AddAsync(person);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask<PersonListViewModel> GetList(PersonFilterViewModel filterViewModel)
    {
        var query = _artemisDbContext.Organizations.AsQueryable();
        var count = await query.CountAsync();

        if (!string.IsNullOrWhiteSpace(filterViewModel.PartyName))
        {
            query = query.Where(x => x.PartyName.Contains(filterViewModel.PartyName));
        }

        var persons = await query.OrderByDescending(i => i.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .Select(r => new PersonResultViewModel
            {
                Id = r.Id,
                PartyName = r.PartyName,
                PartyType = r.PartyType,
                IsBanned = r.IsBanned,
                DeviceId = r.DeviceId,
                CreateDate = r.CreateDate
            })
            .ToListAsync();

        return new PersonResultViewModel
        {
            Count = count,
            ResultViewModels = persons
        };
    }

    public async ValueTask Update(CreateOrUpdatePersonViewModel viewModel)
    {
        var query = _artemisDbContext.Persons.AsQueryable();
        var person = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (person is not null)
        {
            person.PartyName = viewModel.PartyName;
            person.PartyType = viewModel.PartyType;
            person.IsBanned = viewModel.IsBanned;
            person.DeviceId = viewModel.DeviceId;
            await _artemisDbContext.SaveChangesAsync();
        }    
    }

    public async ValueTask Delete(int id)
    {
        var person = await _artemisDbContext.Persons.FirstOrDefaultAsync(i => i.Id == id);

        if (person is not null)
        {
            _artemisDbContext.Persons.Remove(person);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}