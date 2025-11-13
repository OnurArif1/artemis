using Artemis.API.Entities;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace Artemis.API.Services;

public class PersonService : IPersonService
{
    private readonly ArtemisDbContext _artemisDbContext;
    private IQueryable<Person> query;

    public PersonService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
        query = _artemisDbContext.People.AsQueryable();
    }

    public async ValueTask<PersonListViewModel> GetList(PersonFilterViewModel filterViewModel)
    {
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

        return new PersonListViewModel
        {
            Count = count,
            ResultViewModels = persons
        };
    }

    public async ValueTask<PersonGetViewModel?> GetById(int id)
    {
        var person = await query.FirstOrDefaultAsync(i => i.Id == id);

        if (person is not null)
        {
            return new PersonGetViewModel
            {
                Id = person.Id,
                PartyName = person.PartyName,
                PartyType = person.PartyType,
                IsBanned = person.IsBanned,
                DeviceId = person.DeviceId,
                CreateDate = person.CreateDate
            };
        }
        
        return null;
    }

    public async ValueTask<ResultViewModel> Create(CreateOrUpdatePersonViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (string.IsNullOrWhiteSpace(viewModel.PartyName))
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "PartyName cannot be null or white space.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.NullOrWhiteSpace;

            return resultViewModel;
        }

        await _artemisDbContext.People.AddAsync(new Person
        {
            PartyName = viewModel.PartyName,
            PartyType = viewModel.PartyType,
            IsBanned = viewModel.IsBanned,
            DeviceId = viewModel.DeviceId
        });
        _artemisDbContext.SaveChanges();

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }

    public async ValueTask<ResultViewModel> Update(CreateOrUpdatePersonViewModel viewModel)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (viewModel.Id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var person = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);

        if (person is not null)
        {
            if (person.PartyName != viewModel.PartyName)
                person.PartyName = viewModel.PartyName;

            if (person.PartyType != viewModel.PartyType)
                person.PartyType = viewModel.PartyType;

            if (person.IsBanned != viewModel.IsBanned)
                person.IsBanned = viewModel.IsBanned;

            if (person.DeviceId != viewModel.DeviceId)
                person.DeviceId = viewModel.DeviceId;

            await _artemisDbContext.SaveChangesAsync();
        }   

        resultViewModel.IsSuccess = true;
        return resultViewModel; 
    }

    public async ValueTask<ResultViewModel> Delete(int id)
    {
        ResultViewModel resultViewModel = new ResultViewModel();

        if (id <= 0)
        {
            resultViewModel.IsSuccess = false;
            resultViewModel.ExceptionMessage = "Id must be greater than zero.";
            resultViewModel.ExceptionType = Entities.Enums.ExceptionType.GreaterThanZero;

            return resultViewModel;
        }

        var person = await _artemisDbContext.People.FirstOrDefaultAsync(i => i.Id == id);

        if (person is not null)
        {
            _artemisDbContext.People.Remove(person);
            await _artemisDbContext.SaveChangesAsync();
        }

        resultViewModel.IsSuccess = true;
        return resultViewModel;
    }
}