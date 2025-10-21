import request from '@/service/request';

export function getProtected() {
    return request({
        method: 'get',
        url: '/test/protected'
    }).then((res) => res.data);
}

export function getPublic() {
    return request({
        method: 'get',
        url: '/test/public'
    }).then((res) => res.data);
}
