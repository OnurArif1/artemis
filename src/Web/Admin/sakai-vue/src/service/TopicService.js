export default class TopicService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/topic/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async getById(id) {
        const response = await this.request({
            method: 'get',
            url: `/topic/${id}`
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/topic/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/topic/update',
            data: payload
        });
    }

    async delete(topicId) {
        return this.request({ method: 'delete', url: `/topic/delete/${topicId}` });
    }

    async getLookup(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/topic/lookup',
            params: filter
        });
        return response?.data ?? response;
    }
}
