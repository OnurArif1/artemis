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

    async getLookup(filter = {}) {
        const response = await this.request({
            method: 'get',
            url: '/party/lookup',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        await this.request({
            method: 'post',
            url: '/party/create',
            data: payload
        });
    }

    async update(payload) {
        await this.request({
            method: 'post',
            url: '/party/update',
            data: payload
        });
    }

    async delete(partyId) {
        return this.request({ method: 'delete', url: `/party/delete/${partyId}` });
    }

    async updateProfile(email, partyName, description) {
        await this.request({
            method: 'post',
            url: '/party/update-profile',
            data: {
                email,
                partyName,
                description
            }
        });
    }
}
