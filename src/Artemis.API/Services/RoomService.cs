using Artemis.API.Entities;
using Artemis.API.Entities.Enums;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Artemis.API.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace Artemis.API.Services;

public class RoomService : IRoomService
{
    private readonly ArtemisDbContext _artemisDbContext;

    public RoomService(ArtemisDbContext artemisDbContext)
    {
        _artemisDbContext = artemisDbContext;
    }

    public async ValueTask Create(CreateOrUpdateRoomViewModel viewModel)
    {
        if (!viewModel.TopicId.HasValue || viewModel.TopicId.Value <= 0)
        {
            throw new ArgumentException("TopicId is required and must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(viewModel.Title))
        {
            throw new ArgumentException("Title is required.");
        }

        if (viewModel.RoomType == RoomType.None)
        {
            throw new ArgumentException("RoomType is required and must be Public or Private.");
        }

        var room = new Room()
        {
            TopicId = viewModel.TopicId,
            PartyId = viewModel.PartyId,
            CategoryId = viewModel.CategoryId,
            Title = viewModel.Title,
            LocationX = viewModel.LocationX ?? 0,
            LocationY = viewModel.LocationY ?? 0,
            RoomType = viewModel.RoomType,
            LifeCycle = viewModel.LifeCycle ?? 0,
            ChannelId = viewModel.ChannelId ?? string.Empty,
            ReferenceId = viewModel.ReferenceId ?? string.Empty,
            Upvote = viewModel.Upvote ?? 0,
            Downvote = viewModel.Downvote ?? 0,
            SubscriptionType = viewModel.SubscriptionType,
            RoomRange = viewModel.RoomRange
        };

        if (viewModel.PartyId.HasValue && viewModel.PartyId.Value > 0)
        {
            var party = await _artemisDbContext.Parties.FindAsync(viewModel.PartyId.Value);  
            if (party != null)
            {
                ((List<Party>)room.Parties).Add(party);
            }
        }
              
        await _artemisDbContext.Rooms.AddAsync(room);
        _artemisDbContext.SaveChanges();
    }

    public async ValueTask AddParty(AddPartyToRoomViewModel viewModel)
    {
        var query = _artemisDbContext.Rooms.AsQueryable();
        var room = await query.FirstOrDefaultAsync(i => i.Id == viewModel.RoomId);
        if (room is null)
        {
            throw new InvalidOperationException($"Room with ID {viewModel.RoomId} not found.");
        }

        var partiesToAdd = new List<Party>();

        // Çoklu davet desteği - PartyIds varsa onu kullan
        if (viewModel.PartyIds != null && viewModel.PartyIds.Any())
        {
            var existingPartyIds = room.Parties.Select(p => p.Id).ToHashSet();
            var newPartyIds = viewModel.PartyIds.Where(id => !existingPartyIds.Contains(id)).ToList();

            if (newPartyIds.Any())
            {
                var parties = await _artemisDbContext.Parties
                    .Where(p => newPartyIds.Contains(p.Id))
                    .ToListAsync();

                partiesToAdd.AddRange(parties);
            }
        }
        // Backward compatibility - tek party ID varsa onu kullan
        else if (viewModel.PartyId > 0)
        {
            var existingPartyIds = room.Parties.Select(p => p.Id).ToHashSet();
            if (!existingPartyIds.Contains(viewModel.PartyId))
            {
                var party = await _artemisDbContext.Parties.FindAsync(viewModel.PartyId);
                if (party is not null)
                {
                    partiesToAdd.Add(party);
                }
            }
        }

        if (partiesToAdd.Any())
        {
            foreach (var party in partiesToAdd)
            {
                ((List<Party>)room.Parties).Add(party);
            }
            await _artemisDbContext.SaveChangesAsync();
        }
    }

    public async ValueTask<RoomListViewModel> GetList(RoomFilterViewModel filterViewModel)
    {
        var baseQuery = _artemisDbContext.Rooms.AsQueryable();

        if (!string.IsNullOrWhiteSpace(filterViewModel.Title))
        {
            baseQuery = baseQuery.Where(x => x.Title.Contains(filterViewModel.Title));
        }

        if (filterViewModel.TopicId.HasValue && filterViewModel.TopicId.Value > 0)
        {
            baseQuery = baseQuery.Where(x => x.TopicId == filterViewModel.TopicId.Value);
        }

        var count = await baseQuery.CountAsync();

        var query = baseQuery.Include(r => r.Parties).Include(r => r.Category).Include(r => r.Topic);

        var rooms = await query
            .OrderByDescending(r => r.CreateDate)
            .Skip((filterViewModel.PageIndex - 1) * filterViewModel.PageSize)
            .Take(filterViewModel.PageSize)
            .AsSplitQuery() 
            .ToListAsync();  

        var roomViewModels = rooms.Select(r => new RoomResultViewModel
        {
            Id = r.Id,
            TopicId = r.TopicId,
            TopicTitle = r.Topic?.Title,
            Title = r.Title,
            LocationX = r.LocationX,
            LocationY = r.LocationY,
            RoomType = r.RoomType,
            LifeCycle = r.LifeCycle,
            ChannelId = r.ChannelId,
            Upvote = r.Upvote,
            Downvote = r.Downvote,
            CreateDate = r.CreateDate,
            PartyId = r.PartyId,
            PartyName = r.Parties.FirstOrDefault(i => i.Id == r.PartyId)?.PartyName,
            Parties = r.Parties.Select(p => new PartyInfo
            {
                Id = p.Id,
                PartyName = p.PartyName
            }).ToList(),
            CategoryTitle = r.Category?.Title
        }).ToList();

        return new RoomListViewModel
        {
            Count = count,
            ResultViewModels = roomViewModels
        };
    }

    public async ValueTask Update(CreateOrUpdateRoomViewModel viewModel)
    {
        if (!viewModel.TopicId.HasValue || viewModel.TopicId.Value <= 0)
        {
            throw new ArgumentException("TopicId is required and must be greater than zero.");
        }

        if (string.IsNullOrWhiteSpace(viewModel.Title))
        {
            throw new ArgumentException("Title is required.");
        }

        if (viewModel.RoomType == RoomType.None)
        {
            throw new ArgumentException("RoomType is required and must be Public or Private.");
        }

        var query = _artemisDbContext.Rooms.AsQueryable();
        var room = await query.FirstOrDefaultAsync(i => i.Id == viewModel.Id);
        if (room is not null)
        {
            room.TopicId = viewModel.TopicId;
            room.PartyId = viewModel.PartyId;
            room.CategoryId = viewModel.CategoryId;
            room.Title = viewModel.Title;
            room.LocationX = viewModel.LocationX ?? room.LocationX;
            room.LocationY = viewModel.LocationY ?? room.LocationY;
            room.RoomType = viewModel.RoomType;
            room.LifeCycle = viewModel.LifeCycle ?? room.LifeCycle;
            room.ChannelId = viewModel.ChannelId ?? room.ChannelId;
            room.ReferenceId = viewModel.ReferenceId ?? room.ReferenceId;
            room.Upvote = viewModel.Upvote ?? room.Upvote;
            room.Downvote = viewModel.Downvote ?? room.Downvote;
            room.SubscriptionType = viewModel.SubscriptionType ?? room.SubscriptionType;
            room.RoomRange = viewModel.RoomRange ?? room.RoomRange;

            if (viewModel.PartyId.HasValue && viewModel.PartyId.Value > 0)
            {
                var party = await _artemisDbContext.Parties.FindAsync(viewModel.PartyId.Value);  
                if (party != null && !room.Parties.Any(p => p.Id == party.Id))
                {
                    ((List<Party>)room.Parties).Add(party);
                }
            }

            await _artemisDbContext.SaveChangesAsync();
        }
    }
    public async ValueTask Delete(int id)
    {
        var room = await _artemisDbContext.Rooms.FirstOrDefaultAsync(i => i.Id == id);
        if (room is not null)
        {
            _artemisDbContext.Rooms.Remove(room);
            await _artemisDbContext.SaveChangesAsync();
        }
    }
}