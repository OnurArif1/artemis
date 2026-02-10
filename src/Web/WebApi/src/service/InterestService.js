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

    async savePartyInterests(interestIds) {
        const response = await this.request({
            method: 'post',
            url: '/partyInterest/save',
            data: { interestIds }
        });
        return response?.data ?? response;
    }

    async getMyInterests() {
        const response = await this.request({
            method: 'get',
            url: '/partyInterest/my-interests'
        });
        return response?.data ?? response;
    }
}
