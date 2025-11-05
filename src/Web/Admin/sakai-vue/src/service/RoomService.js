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
<<<<<<< HEAD
            url: '/room/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/room/update',
            data: payload
=======
            url: '/room',
            data: roomData
>>>>>>> 5b9c5f5b (fix)
        });
    }
}
