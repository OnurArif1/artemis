export default class HashtagService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/hashtag/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/hashtag/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/hashtag/update',
            data: payload
        });
    }

    async delete(hashtagId) {
        return this.request({
            method: 'delete',
            url: `/hashtag/delete/${hashtagId}`
        });
    }

    async getLookup(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/hashtag/lookup',
            params: filter
        });
        return response?.data ?? response;
    }
}
