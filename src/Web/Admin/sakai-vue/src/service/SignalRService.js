import { HubConnectionBuilder } from '@microsoft/signalr';

class SignalRService {
    constructor() {
        this.connection = null;
        // Environment variable'dan SignalR Hub URL'ini al, yoksa varsayılan olarak localhost kullan
        this.hubUrl = import.meta.env.VITE_SIGNALR_HUB_URL || 'http://localhost:5094/hubs/chat';
    }

    startConnection() {
        this.connection = new HubConnectionBuilder().withUrl(this.hubUrl).build();

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
