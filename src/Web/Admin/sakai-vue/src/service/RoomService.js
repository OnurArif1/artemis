export default class RoomService {
    constructor(request) {
        this.request = request;
    }

    async getList(filter = {}) {
        console.log('filter:', filter)
        const response = await this.request({
            method: 'get',
            url: '/room/list',
            params: filter
        });
        return response?.data ?? response;
    }

    async create(payload) {
        // Backend'in beklediği formata uygun hale getir
        const roomData = {
            topicId: payload.topicId || null,
            partyId: payload.partyId,
            categoryId: payload.categoryId || null,
            title: payload.title,
            locationX: payload.locationX || 0,
            locationY: payload.locationY || 0,
            roomType: payload.roomType || 1, // Default Public
            lifeCycle: payload.lifeCycle || 0,
            channelId: payload.channelId || 0,
            referenceId: payload.referenceId || '',
            upvote: payload.upvote || 0,
            downvote: payload.downvote || 0
        };

        await this.request({
            method: 'post',
            url: '/room/create',
            data: roomData
        });
    }
}
