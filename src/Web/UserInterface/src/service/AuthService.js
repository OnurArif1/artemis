import axios from 'axios';

const IDENTITY_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:5091';

export default class AuthService {
    async login(email, password) {
        const formData = new URLSearchParams();
        formData.append('grant_type', 'password');
        formData.append('client_id', 'artemis.client');
        formData.append('client_secret', 'artemis_secret');
        formData.append('username', email);
        formData.append('password', password);
        formData.append('scope', 'openid profile email artemis.api roles');

        const response = await axios.post(
            `${IDENTITY_BASE_URL}/identity/connect/token`,
            formData,
            {
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                }
            }
        );

        return {
            access_token: response.data.access_token,
            expires_in: response.data.expires_in,
            refresh_token: response.data.refresh_token,
            token_type: response.data.token_type
        };
    }

    async register(userData) {
        const response = await axios.post(
            `${IDENTITY_BASE_URL}/identity/account/register`,
            userData,
            {
                headers: {
                    'Content-Type': 'application/json'
                }
            }
        );
        return response.data;
    }

    async getUserInfo(token) {
        const response = await axios.get(
            `${IDENTITY_BASE_URL}/identity/connect/userinfo`,
            {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            }
        );
        return response.data;
    }
}

