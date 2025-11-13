export default class RoomHashtagMapService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/roomHashtagMap/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/roomHashtagMap/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/roomHashtagMap/update',
            data: payload
        });
    }

    async delete(mapId) {
        return this.request({ method: 'delete', url: `/roomHashtagMap/delete/${mapId}` });
    }
}
