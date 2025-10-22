export default class PartyService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/party/list',
            params: filter
        });
        return response?.data ?? response;
    }
}