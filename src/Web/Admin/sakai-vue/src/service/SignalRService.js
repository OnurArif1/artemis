import { HubConnectionBuilder } from '@microsoft/signalr';

class SignalRService {
    constructor() {
        this.connection = null;
    }

    startConnection() {
        this.connection = new HubConnectionBuilder().withUrl('http://10.58.2.78:5094/hubs/chat').build();

        this.connection
            .start()
            .then(() => console.log('SignalR connected'))
            .catch((err) => console.error('SignalR connection error:', err));
    }

    sendMessage(from, to, message) {
        this.connection.invoke('SendMessage', from, to, message).catch((err) => console.error('Send error:', err));
    }

    onReceiveMessage(callback) {
        this.connection.on('ReceiveMessage', (from, message) => {
            callback(from, message);
        });
    }
}

export default new SignalRService();
