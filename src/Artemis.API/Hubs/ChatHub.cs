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
    private readonly ICommentService _commentService;

    public ChatHub(IMessageService messageService, IPartyService partyService, ICommentService commentService)
    {
        _messageService = messageService;
        _partyService = partyService;
        _commentService = commentService;
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

    public async Task JoinTopic(int topicId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Topic_{topicId}");
    }

    public async Task LeaveTopic(int topicId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Topic_{topicId}");
    }

    public async Task SendComment(int partyId, int topicId, string message)
    {
        try
        {
            var viewModel = new CreateOrUpdateCommentViewModel
            {
                TopicId = topicId,
                PartyId = partyId,
                Content = message,
                Upvote = 0,
                Downvote = 0
            };
            
            await _commentService.Create(viewModel);

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

            await Clients.Group($"Topic_{topicId}").SendAsync("ReceiveComment", partyId, partyName, message, topicId);
        }
        catch (Exception ex)
        {
            await Clients.Caller.SendAsync("ReceiveError", $"Comment not sent: {ex.Message}");
        }
    }

    public string GetConnectionId()
    {
        return Context.ConnectionId;
    }
}