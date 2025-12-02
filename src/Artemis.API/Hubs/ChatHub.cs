using System;
using System.Linq;
using Artemis.API.Services;
using Artemis.API.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace Artemis.API.Hubs;

public class ChatHub : Hub
{
    private readonly IMessageService _messageService;
    private readonly IPartyService _partyService;

    public ChatHub(IMessageService messageService, IPartyService partyService)
    {
        _messageService = messageService;
        _partyService = partyService;
    }

    public override async Task OnConnectedAsync()
    {
        // Yeni bağlantı geldiğinde ConnectionId'yi client'a gönder
        await Clients.Caller.SendAsync("ReceiveConnectionId", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    // Room'a bağlanmak için method
    public async Task JoinRoom(int roomId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Room_{roomId}");
    }

    // Room'dan ayrılmak için method
    public async Task LeaveRoom(int roomId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Room_{roomId}");
    }

    public async Task SendMessage(int partyId, int roomId, string message, List<int>? mentionedPartyIds = null)
    {
        try
        {
            // Mesajı veritabanına kaydet
            var viewModel = new CreateOrUpdateMessageViewModel
            {
                PartyId = partyId,
                RoomId = roomId,
                Content = message,
                Upvote = 0,
                Downvote = 0,
                MentionedPartyIds = mentionedPartyIds
            };
            
            await _messageService.Create(viewModel);

            // Party bilgisini al (kullanıcı adı için)
            string partyName = $"Kullanıcı {partyId}";
            try
            {
                var partyLookup = await _partyService.GetPartyLookup(new GetLookupPartyViewModel { PartyId = partyId });
                if (partyLookup?.ViewModels != null && partyLookup.ViewModels.Any())
                {
                    var party = partyLookup.ViewModels.FirstOrDefault();
                    if (party != null && !string.IsNullOrEmpty(party.PartyName))
                    {
                        partyName = party.PartyName;
                    }
                }
            }
            catch
            {
                // Hata durumunda varsayılan ismi kullan
            }

            // Sadece bu room'daki kullanıcılara mesaj gönder (roomId ile birlikte)
            await Clients.Group($"Room_{roomId}").SendAsync("ReceiveMessage", partyId, partyName, message, roomId);
        }
        catch (Exception ex)
        {
            // Hata durumunda sadece gönderen kullanıcıya hata mesajı gönder
            await Clients.Caller.SendAsync("ReceiveError", $"Mesaj gönderilemedi: {ex.Message}");
        }
    }

    // ConnectionId'yi almak için bir method (isteğe bağlı)
    public string GetConnectionId()
    {
        return Context.ConnectionId;
    }
}