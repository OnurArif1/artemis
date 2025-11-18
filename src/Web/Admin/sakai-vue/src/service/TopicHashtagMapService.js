export default class TopicHashtagMapService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/topicHashtagMap/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/topicHashtagMap/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/topicHashtagMap/update',
            data: payload
        });
    }

    async delete(mapId) {
        return this.request({ method: 'delete', url: `/topicHashtagMap/delete/${mapId}` });
    }
}
