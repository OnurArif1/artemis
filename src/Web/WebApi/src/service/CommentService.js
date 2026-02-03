export default class CommentService {
    constructor(request) {
        this.request = request;
    }

    async create(payload) {
        const response = await this.request({
            method: 'post',
            url: '/comment/create',
            data: payload
        });
        return response?.data ?? response;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/comment/list',
            params: filter
        });
        return response?.data ?? response;
    }
}
