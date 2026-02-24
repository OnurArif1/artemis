export default class AppSubscriptionTypePricesService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/appSubscriptionTypePrices/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/appSubscriptionTypePrices/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/appSubscriptionTypePrices/update',
            data: payload
        });
    }

    async delete(id) {
        return this.request({ method: 'delete', url: `/appSubscriptionTypePrices/delete/${id}` });
    }
}
