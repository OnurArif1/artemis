import { HubConnectionBuilder } from '@microsoft/signalr';

class SignalRService {
    constructor() {
        this.connection = null;
        this.connectionId = null;
        this.hubUrl = import.meta.env.VITE_SIGNALR_HUB_URL || 'http://localhost:5094/hubs/chat';
    }

    startConnection() {
        if (this.connection && this.connection.state === 'Connected') {
            return Promise.resolve();
        }

        this.connection = new HubConnectionBuilder().withUrl(this.hubUrl).withAutomaticReconnect().build();

        this.connection.onclose((error) => {});

        this.connection.onreconnecting((error) => {});

        this.connection.onreconnected((connectionId) => {
            this.connectionId = connectionId;
        });

        this.connection.on('ReceiveConnectionId', (connectionId) => {
            this.connectionId = connectionId;
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
                    this.connection.invoke('SendMessage', partyId, roomId, message, mentionedPartyIds).catch(() => {});
                })
                .catch(() => {});
            return;
        }

        this.connection.invoke('SendMessage', partyId, roomId, message, mentionedPartyIds).catch(() => {});
    }

    joinRoom(roomId) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            return;
        }

        this.connection.invoke('JoinRoom', roomId).catch(() => {});
    }

    leaveRoom(roomId) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            return;
        }

        this.connection.invoke('LeaveRoom', roomId).catch(() => {});
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

    joinTopic(topicId) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            return;
        }

        this.connection.invoke('JoinTopic', topicId).catch(() => {});
    }

    leaveTopic(topicId) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            return;
        }

        this.connection.invoke('LeaveTopic', topicId).catch(() => {});
    }

    sendComment(partyId, topicId, message) {
        if (!this.connection) {
            return;
        }

        if (this.connection.state !== 'Connected') {
            this.startConnection()
                .then(() => {
                    this.connection.invoke('SendComment', partyId, topicId, message).catch(() => {});
                })
                .catch(() => {});
            return;
        }

        this.connection.invoke('SendComment', partyId, topicId, message).catch(() => {});
    }

    onReceiveComment(callback) {
        if (!this.connection) {
            return;
        }

        this.connection.on('ReceiveComment', (partyId, partyName, message, topicId) => {
            callback(partyId, partyName, message, topicId);
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
