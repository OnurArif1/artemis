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
}