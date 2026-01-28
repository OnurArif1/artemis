import { HubConnectionBuilder } from '@microsoft/signalr';

class SignalRService {
    constructor() {
        this.connection = null;
        this.connectionId = null;
        this.hubUrl = import.meta.env.VITE_SIGNALR_HUB_URL || 'http://localhost:5094/hubs/chat';
    }

    startConnection() {
        if (this.connection && this.connection.state === 'Connected') {
            console.log('SignalR already connected');
            return Promise.resolve();
        }

        this.connection = new HubConnectionBuilder()
            .withUrl(this.hubUrl)
            .withAutomaticReconnect()
            .build();

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

        this.connection.on('ReceiveConnectionId', (connectionId) => {
            this.connectionId = connectionId;
            console.log('📡 ConnectionId alındı:', connectionId);
        });

        return this.connection
            .start()
            .then(() => {
                return this.connection.invoke('GetConnectionId');
            })
            .then((connectionId) => {
                if (connectionId) {
                    this.connectionId = connectionId;
                }
            })
            .catch((err) => {
                throw err;
            });
    }

    sendMessage(partyId, roomId, message, mentionedPartyIds = null) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            this.startConnection()
                .then(() => {
                    this.connection.invoke('SendMessage', partyId, roomId, message, mentionedPartyIds).catch((err) => console.error('Send error:', err));
                })
                .catch((err) => {
                    console.error('Failed to reconnect:', err);
                });
            return;
        }

        this.connection.invoke('SendMessage', partyId, roomId, message, mentionedPartyIds).catch((err) => console.error('Send error:', err));
    }

    joinRoom(roomId) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            return;
        }

        this.connection.invoke('JoinRoom', roomId).catch((err) => {
            console.error('JoinRoom error:', err);
        });
    }

    leaveRoom(roomId) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            return;
        }

        this.connection.invoke('LeaveRoom', roomId).catch((err) => {
            console.error('LeaveRoom error:', err);
        });
    }

    onReceiveMessage(callback) {
        if (!this.connection) {
            return;
        }

        this.connection.on('ReceiveMessage', (partyId, partyName, message, roomId) => {
            callback(partyId, partyName, message, roomId);
        });
    }

    onReceiveError(callback) {
        if (!this.connection) {
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
