import { HubConnectionBuilder } from '@microsoft/signalr';

class SignalRService {
    constructor() {
        this.connection = null;
        this.connectionId = null; // ConnectionId'yi saklamak için
        // Environment variable'dan SignalR Hub URL'ini al, yoksa varsayılan olarak localhost kullan
        this.hubUrl = import.meta.env.VITE_SIGNALR_HUB_URL || 'http://localhost:5094/hubs/chat';
    }

    startConnection() {
        if (this.connection && this.connection.state === 'Connected') {
            console.log('SignalR already connected');
            return Promise.resolve();
        }

        this.connection = new HubConnectionBuilder()
            .withUrl(this.hubUrl)
            .withAutomaticReconnect() // Otomatik yeniden bağlanma
            .build();

        // Bağlantı durumu değişikliklerini dinle
        this.connection.onclose((error) => {
            console.warn('SignalR connection closed', error);
        });

        this.connection.onreconnecting((error) => {
            console.log('SignalR reconnecting...', error);
        });

        this.connection.onreconnected((connectionId) => {
            console.log('SignalR reconnected:', connectionId);
            this.connectionId = connectionId;
        });

        // ConnectionId'yi backend'den al
        this.connection.on('ReceiveConnectionId', (connectionId) => {
            this.connectionId = connectionId;
            console.log('📡 ConnectionId alındı:', connectionId);
        });

        return this.connection
            .start()
            .then(() => {
                console.log('✅ SignalR connected to:', this.hubUrl);
                // ConnectionId'yi backend'den iste
                return this.connection.invoke('GetConnectionId');
            })
            .then((connectionId) => {
                if (connectionId) {
                    this.connectionId = connectionId;
                    console.log('📡 ConnectionId:', connectionId);
                }
            })
            .catch((err) => {
                console.error('❌ SignalR connection error:', err);
                console.error('Hub URL:', this.hubUrl);
                throw err;
            });
    }

    sendMessage(partyId, roomId, message) {
        if (!this.connection) {
            console.error('SignalR connection is not initialized. Call startConnection() first.');
            return;
        }

        if (this.connection.state !== 'Connected') {
            console.warn('SignalR is not connected. Current state:', this.connection.state);
            // Bağlantıyı yeniden başlatmayı dene
            this.startConnection()
                .then(() => {
                    this.connection.invoke('SendMessage', partyId, roomId, message).catch((err) => console.error('Send error:', err));
                })
                .catch((err) => {
                    console.error('Failed to reconnect:', err);
                });
            return;
        }

        this.connection.invoke('SendMessage', partyId, roomId, message).catch((err) => console.error('Send error:', err));
    }

    onReceiveMessage(callback) {
        if (!this.connection) {
            console.error('SignalR connection is not initialized. Call startConnection() first.');
            return;
        }

        this.connection.on('ReceiveMessage', (partyId, partyName, message) => {
            callback(partyId, partyName, message);
        });
    }

    onReceiveError(callback) {
        if (!this.connection) {
            console.error('SignalR connection is not initialized. Call startConnection() first.');
            return;
        }

        this.connection.on('ReceiveError', (errorMessage) => {
            callback(errorMessage);
        });
    }

    isConnected() {
        return this.connection && this.connection.state === 'Connected';
    }

    getConnectionId() {
        return this.connectionId;
    }
}

export default new SignalRService();
