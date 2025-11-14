import { HubConnectionBuilder } from '@microsoft/signalr';

class SignalRService {
    constructor() {
        this.connection = null;
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
        });

        return this.connection
            .start()
            .then(() => {
                console.log('✅ SignalR connected to:', this.hubUrl);
            })
            .catch((err) => {
                console.error('❌ SignalR connection error:', err);
                console.error('Hub URL:', this.hubUrl);
                throw err;
            });
    }

    sendMessage(from, to, message) {
        if (!this.connection) {
            console.error('SignalR connection is not initialized. Call startConnection() first.');
            return;
        }

        if (this.connection.state !== 'Connected') {
            console.warn('SignalR is not connected. Current state:', this.connection.state);
            // Bağlantıyı yeniden başlatmayı dene
            this.startConnection()
                .then(() => {
                    this.connection.invoke('SendMessage', from, to, message).catch((err) => 
                        console.error('Send error:', err)
                    );
                })
                .catch((err) => {
                    console.error('Failed to reconnect:', err);
                });
            return;
        }

        this.connection.invoke('SendMessage', from, to, message).catch((err) => 
            console.error('Send error:', err)
        );
    }

    onReceiveMessage(callback) {
        if (!this.connection) {
            console.error('SignalR connection is not initialized. Call startConnection() first.');
            return;
        }

        this.connection.on('ReceiveMessage', (from, message) => {
            callback(from, message);
        });
    }

    isConnected() {
        return this.connection && this.connection.state === 'Connected';
    }
}

export default new SignalRService();
