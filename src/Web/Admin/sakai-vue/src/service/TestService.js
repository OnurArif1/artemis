import request from '@/service/request';

export function getProtected() {
    console.log('arif')

    return request({
        method: 'get',
        url: '/test/protected'
    }).then((res) => res.data);
}

export function getPublic() {
    console.log('onur')
    return request({
        method: 'get',
        url: '/test/public'
    }).then((res) => res.data);
}


