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
}
