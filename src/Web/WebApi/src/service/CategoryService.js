export default class CategoryService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/category/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/category/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/category/update',
            data: payload
        });
    }

    async delete(categoryId) {
        return this.request({ method: 'delete', url: `/category/delete/${categoryId}` });
    }

    async getLookup(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/category/lookup',
            params: filter
        });
        return response?.data ?? response;
    }
}
