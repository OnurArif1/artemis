export default class MessageService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/message/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/message/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/message/update',
            data: payload
        });
    }

    async delete(messageId) {
        return this.request({ method: 'delete', url: `/message/delete/${messageId}` });
    }
}

