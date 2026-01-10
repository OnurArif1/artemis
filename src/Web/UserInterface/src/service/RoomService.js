export default class RoomService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/room/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/room/create',
            data: payload
        });
    }

    async addPartyToRoom(payload) {
        await this.request({
            method: 'post',
            url: '/room/addParty',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/room/update',
            data: payload
        });
    }

    async delete(roomId) {
        return this.request({ method: 'delete', url: `/room/delete/${roomId}` });
    }

    async getLookup(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/room/lookup',
            params: filter
        });
        return response?.data ?? response;
    }
}

