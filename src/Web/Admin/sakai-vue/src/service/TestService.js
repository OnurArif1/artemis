import request from '@/service/request';

export function getProtected() {
    return request({
        method: 'get',
        url: '/test/protected'
    }).then((res) => res.data);
}


