export default class PartyPurposeService {
    constructor(request) {
        this.request = request;
    }

    async savePartyPurposes(email, purposeTypes) {
        const response = await this.request({
            method: 'post',
            url: '/partyPurpose/save',
            data: { email, purposeTypes }
        });
        return response?.data ?? response;
    }
}
