export default class InterestService {
    constructor(request) {
        this.request = request;
    }

    async getList() {
        const response = await this.request({
            method: 'get',
            url: '/interest/list'
        });
        return response?.data ?? response;
    }

    async savePartyInterests(email, interestIds) {
        const response = await this.request({
            method: 'post',
            url: '/partyInterest/save',
            data: { email, interestIds }
        });
        return response?.data ?? response;
    }

    async getMyInterests(email) {
        const response = await this.request({
            method: 'get',
            url: '/partyInterest/my-interests',
            ...(email ? { params: { email } } : {})
        });
        return response?.data ?? response;
    }
}
