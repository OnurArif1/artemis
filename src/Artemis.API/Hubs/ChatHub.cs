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
        await Clients.Caller.SendAsync("ReceiveConnectionId", Context.ConnectionId);
        await base.OnConnectedAsync();
    }

    public async Task JoinRoom(int roomId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Room_{roomId}");
    }

    public async Task LeaveRoom(int roomId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Room_{roomId}");
    }

    public async Task SendMessage(int partyId, int roomId, string message, List<int>? mentionedPartyIds = null)
    {
        try
        {
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

            string partyName = $"User {partyId}";
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
                // do nothing
            }

            await Clients.Group($"Room_{roomId}").SendAsync("ReceiveMessage", partyId, partyName, message, roomId);
        }
        catch (Exception ex)
        {
            await Clients.Caller.SendAsync("ReceiveError", $"Message not sent: {ex.Message}");
        }
    }

    public string GetConnectionId()
    {
        return Context.ConnectionId;
    }
}