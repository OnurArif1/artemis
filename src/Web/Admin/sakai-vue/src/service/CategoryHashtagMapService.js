export default class CategoryHashtagMapService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/categoryHashtagMap/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/categoryHashtagMap/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/categoryHashtagMap/update',
            data: payload
        });
    }

    async delete(mapId) {
        return this.request({ method: 'delete', url: `/categoryHashtagMap/delete/${mapId}` });
    }
}
