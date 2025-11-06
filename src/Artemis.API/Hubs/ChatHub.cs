using Microsoft.AspNetCore.SignalR;

namespace Artemis.API.Hubs;

public class ChatHub : Hub
{
    public async Task SendMessage(string from, string to, string message)
    {
        await Clients.All.SendAsync("ReceiveMessage", from, message);
    }
}