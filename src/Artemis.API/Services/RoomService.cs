using Artemis.API.Entities;
using Artemis.API.Entities.Enums;
using Artemis.API.Infrastructure;
using Artemis.API.Services.Interfaces;
using Artemis.API.Utilities;
using Artemis.API.ViewModels;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
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

        if (!viewModel.LifeCycle.HasValue)
        {
            throw new ArgumentException("LifeCycle is required.");
        }

        await ValidateCreatorCanCreateRoomAsync(viewModel);

        var room = new Room()
        {
            TopicId = viewModel.TopicId,
            PartyId = viewModel.PartyId,
            CategoryId = viewModel.CategoryId,
            Title = viewModel.Title,
            LocationX = viewModel.LocationX ?? 0,
            LocationY = viewModel.LocationY ?? 0,
            RoomType = viewModel.RoomType,
            LifeCycle = viewModel.LifeCycle.Value,
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

    private async Task ValidateCreatorCanCreateRoomAsync(CreateOrUpdateRoomViewModel viewModel)
    {
        Party? party = null;
        if (viewModel.PartyId.HasValue && viewModel.PartyId.Value > 0)
        {
            party = await _artemisDbContext.Parties.AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == viewModel.PartyId.Value);
            if (party is null)
            {
                throw new InvalidOperationException("Belirtilen kullanıcı (party) bulunamadı.");
            }
        }
        else if (!string.IsNullOrWhiteSpace(viewModel.UserEmail))
        {
            var em = viewModel.UserEmail.Trim().ToLower();
            party = await _artemisDbContext.Parties.AsNoTracking()
                .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == em);
            if (party is null)
            {
                throw new InvalidOperationException("Hesabınıza bağlı kullanıcı kaydı bulunamadı.");
            }
        }
        else
        {
            return;
        }

        var tier = party.SubscriptionType ?? SubscriptionType.None;
        if (tier != SubscriptionType.Gold && tier != SubscriptionType.Platinum)
        {
            throw new InvalidOperationException(
                "Oda oluşturma yalnızca Gold ve Platinum üyeler içindir. Paketinizi yükseltebilirsiniz.");
        }
    }

    public async ValueTask AddParty(AddPartyToRoomViewModel viewModel)
    {
        var query = _artemisDbContext.Rooms.AsQueryable();
        var room = await query.FirstOrDefaultAsync(i => i.Id == viewModel.RoomId);
        if (room is null)
        {
            throw new InvalidOperationException($"Room with ID {viewModel.RoomId} not found.");
        }

        if (RoomLifecycleHelper.IsExpired(room))
        {
            throw new InvalidOperationException("Bu odaya artık katılım mümkün değil.");
        }

        var partiesToAdd = new List<Party>();

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
        if (IsStartChatPickerListRequest(filterViewModel))
        {
            return await GetStartChatPickerListAsync(filterViewModel);
        }

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

        Party? userParty = null;
        if (!string.IsNullOrWhiteSpace(filterViewModel.UserEmail))
        {
            userParty = await _artemisDbContext.Parties
                .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == filterViewModel.UserEmail.ToLower());
        }

        var roomViewModels = rooms
            .Select(r => MapRoomToResult(r, userParty, filterViewModel.UserLatitude, filterViewModel.UserLongitude))
            .ToList();

        return new RoomListViewModel
        {
            Count = count,
            ResultViewModels = roomViewModels
        };
    }

    /// <summary>
    /// Sohbet başlat (+): (1) menzil içi odalar mesafeye göre, (2) eksik kısım menzil dışı en yakınlar,
    /// (3) hâlâ eksikse Upvote azalan. Konum yoksa doğrudan Upvote.
    /// </summary>
    private async ValueTask<RoomListViewModel> GetStartChatPickerListAsync(RoomFilterViewModel filterViewModel)
    {
        var limit = filterViewModel.PageSize > 0 ? filterViewModel.PageSize : 20;

        var baseQuery = _artemisDbContext.Rooms.AsQueryable();

        if (!string.IsNullOrWhiteSpace(filterViewModel.Title))
        {
            baseQuery = baseQuery.Where(x => x.Title.Contains(filterViewModel.Title));
        }

        if (filterViewModel.TopicId.HasValue && filterViewModel.TopicId.Value > 0)
        {
            baseQuery = baseQuery.Where(x => x.TopicId == filterViewModel.TopicId.Value);
        }

        var rooms = await baseQuery
            .Include(r => r.Parties)
            .Include(r => r.Category)
            .Include(r => r.Topic)
            .AsSplitQuery()
            .ToListAsync();

        Party? userParty = null;
        if (!string.IsNullOrWhiteSpace(filterViewModel.UserEmail))
        {
            userParty = await _artemisDbContext.Parties
                .FirstOrDefaultAsync(p => p.Email != null && p.Email.ToLower() == filterViewModel.UserEmail.ToLower());
        }

        // Keşif listesi: süresi dolmuş / üyelik kısıtlı odalar da dahil (sıralamada kullanılır); ayrıntı alanları VM'de kalır.
        var allVms = rooms
            .Select(r => MapRoomToResult(r, userParty, filterViewModel.UserLatitude, filterViewModel.UserLongitude))
            .ToList();

        var hasLatLng = filterViewModel.UserLatitude.HasValue && filterViewModel.UserLongitude.HasValue;

        var combined = new List<RoomResultViewModel>(limit);
        var usedIds = new HashSet<int>();

        if (hasLatLng)
        {
            // 1) Menzil içi (distance <= RoomRange), yakından uzağa
            var inRange = allVms
                .Where(vm =>
                    vm.RoomRange.HasValue &&
                    vm.Distance.HasValue &&
                    vm.Distance <= vm.RoomRange.Value)
                .OrderBy(vm => vm.Distance!.Value)
                .ToList();

            foreach (var vm in inRange)
            {
                if (combined.Count >= limit) break;
                combined.Add(vm);
                usedIds.Add(vm.Id);
            }

            // 2) Eksik kısım: menzil dışı ama mesafesi olanlar, yine yakından uzağa
            if (combined.Count < limit)
            {
                var need = limit - combined.Count;
                var outsideByDistance = allVms
                    .Where(vm => !usedIds.Contains(vm.Id) && vm.Distance.HasValue)
                    .OrderBy(vm => vm.Distance!.Value)
                    .Take(need)
                    .ToList();

                foreach (var vm in outsideByDistance)
                {
                    combined.Add(vm);
                    usedIds.Add(vm.Id);
                }
            }
        }

        // 3) Konum yoksa veya hâlâ eksikse: Upvote ile tamamla
        if (combined.Count < limit)
        {
            var need = limit - combined.Count;
            var byUpvote = allVms
                .Where(vm => !usedIds.Contains(vm.Id))
                .OrderByDescending(vm => vm.Upvote)
                .ThenByDescending(vm => vm.CreateDate)
                .Take(need)
                .ToList();
            combined.AddRange(byUpvote);
        }

        return new RoomListViewModel
        {
            Count = combined.Count,
            ResultViewModels = combined
        };
    }

    private static bool IsStartChatPickerListRequest(RoomFilterViewModel f) =>
        f.StartChatPickerMode ||
        string.Equals(f.ListMode, "startChat", StringComparison.OrdinalIgnoreCase);

    private static RoomResultViewModel MapRoomToResult(
        Room r,
        Party? userParty,
        double? userLatitude,
        double? userLongitude)
    {
        double? distance = null;
        var canAccess = true;
        var subscriptionAccessDenied = false;

        if (userLatitude.HasValue && userLongitude.HasValue)
        {
            distance = CalculateDistance(
                userLatitude.Value,
                userLongitude.Value,
                r.LocationY,
                r.LocationX
            );

            if (r.RoomRange.HasValue)
            {
                canAccess = distance <= r.RoomRange.Value;
            }
        }

        if (r.SubscriptionType.HasValue && userParty != null)
        {
            var roomSubscriptionType = r.SubscriptionType.Value;
            var userSubscriptionType = userParty.SubscriptionType ?? SubscriptionType.None;

            if ((int)userSubscriptionType < (int)roomSubscriptionType)
            {
                subscriptionAccessDenied = true;
                canAccess = false;
            }
        }

        return new RoomResultViewModel
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
            CategoryTitle = r.Category?.Title,
            SubscriptionType = r.SubscriptionType,
            RoomRange = r.RoomRange,
            CanAccess = canAccess,
            Distance = distance,
            SubscriptionAccessDenied = subscriptionAccessDenied,
            LifecycleExpired = RoomLifecycleHelper.IsExpired(r)
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

        if (!viewModel.LifeCycle.HasValue)
        {
            throw new ArgumentException("LifeCycle is required.");
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
            room.LifeCycle = viewModel.LifeCycle.Value;
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

    public async ValueTask UpdateUpvote(int roomId, int upvote)
    {
        if (roomId <= 0)
        {
            throw new ArgumentException("RoomId is required and must be greater than zero.");
        }

        var room = await _artemisDbContext.Rooms.FirstOrDefaultAsync(r => r.Id == roomId);
        if (room is null)
        {
            throw new InvalidOperationException($"Room with ID {roomId} was not found.");
        }

        room.Upvote = upvote;
        await _artemisDbContext.SaveChangesAsync();
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

    private static double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371; // Dünya'nın yarıçapı (km)
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private static double ToRadians(double degrees)
    {
        return degrees * Math.PI / 180.0;
    }
}