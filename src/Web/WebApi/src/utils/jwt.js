export function decodeJWT(token) {
    try {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(
            atob(base64)
                .split('')
                .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
                .join('')
        );
        return JSON.parse(jsonPayload);
    } catch (error) {
        console.error('JWT decode error:', error);
        return null;
    }
}

export function getEmailFromToken(token) {
    const decoded = decodeJWT(token);
    return decoded?.email || decoded?.sub || null;
}

export function getSubFromToken(token) {
    const decoded = decodeJWT(token);
    return decoded?.sub || null;
}
