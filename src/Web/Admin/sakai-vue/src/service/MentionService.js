export default class MentionService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/mention/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/mention/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/mention/update',
            data: payload
        });
    }

    async delete(mentionId) {
        return this.request({ method: 'delete', url: `/mention/delete/${mentionId}` });
    }
}
