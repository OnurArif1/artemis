export default class TopicService {
    constructor(request) {
        this.request = request;
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
