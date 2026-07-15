// Same-origin via Vite proxy → avoids CORS issues with localhost vs 127.0.0.1
const API_BASE_URL = '/api/v1';
const ACCESS_KEY = 'ff_access_token';
const REFRESH_KEY = 'ff_refresh_token';

function getAccessToken() {
    return localStorage.getItem(ACCESS_KEY);
}

function getRefreshToken() {
    return localStorage.getItem(REFRESH_KEY);
}

function saveTokens({ access_token, refresh_token }) {
    if (access_token) localStorage.setItem(ACCESS_KEY, access_token);
    if (refresh_token) localStorage.setItem(REFRESH_KEY, refresh_token);
}

function clearTokens() {
    localStorage.removeItem(ACCESS_KEY);
    localStorage.removeItem(REFRESH_KEY);
}

function parseDetail(detail) {
    if (!detail) return 'Error en la solicitud.';
    if (typeof detail === 'string') return detail;
    if (Array.isArray(detail)) {
        return detail
            .map((e) => (typeof e === 'string' ? e : e.msg || JSON.stringify(e)))
            .join(' ');
    }
    return String(detail);
}

async function parseError(res) {
    try {
        const data = await res.json();
        return parseDetail(data.detail) || `Error HTTP ${res.status}`;
    } catch {
        return `Error HTTP ${res.status}`;
    }
}

function toQuery(params = {}) {
    return new URLSearchParams(
        Object.fromEntries(
            Object.entries(params)
                .filter(([, v]) => v !== undefined && v !== null && v !== '')
                .map(([k, v]) => [k, String(v)])
        )
    );
}

let refreshPromise = null;

async function refreshAccessToken() {
    const refresh_token = getRefreshToken();
    if (!refresh_token) throw new Error('Sesión expirada.');

    if (!refreshPromise) {
        refreshPromise = (async () => {
            const res = await fetch(`${API_BASE_URL}/auth/refresh`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ refresh_token }),
            });
            if (!res.ok) {
                clearTokens();
                throw new Error(await parseError(res));
            }
            const data = await res.json();
            saveTokens(data);
            return data.access_token;
        })().finally(() => {
            refreshPromise = null;
        });
    }

    return refreshPromise;
}

async function request(path, { method = 'GET', body, auth = true, headers = {}, retry = true, raw = false } = {}) {
    const opts = {
        method,
        headers: { ...headers },
    };

    if (body !== undefined) {
        if (body instanceof URLSearchParams) {
            opts.headers['Content-Type'] = 'application/x-www-form-urlencoded';
            opts.body = body;
        } else {
            opts.headers['Content-Type'] = 'application/json';
            opts.body = JSON.stringify(body);
        }
    }

    if (auth) {
        const token = getAccessToken();
        if (token) opts.headers.Authorization = `Bearer ${token}`;
    }

    const res = await fetch(`${API_BASE_URL}${path}`, opts);

    if (res.status === 401 && auth && retry && getRefreshToken()) {
        try {
            await refreshAccessToken();
            return request(path, { method, body, auth, headers, retry: false, raw });
        } catch {
            clearTokens();
            throw new Error('Sesión expirada. Inicia sesión de nuevo.');
        }
    }

    if (res.status === 204) return null;

    if (!res.ok) throw new Error(await parseError(res));

    if (raw) return res;

    const text = await res.text();
    if (!text) return null;
    return JSON.parse(text);
}

async function fetchAllPages(path, params = {}) {
    const limit = 100;
    let offset = 0;
    let total = Infinity;
    const items = [];

    while (offset < total) {
        const qs = toQuery({ limit, offset, ...params });
        const page = await request(`${path}?${qs}`);
        items.push(...(page.items || []));
        total = page.total ?? items.length;
        offset += limit;
        if (!(page.items || []).length) break;
    }

    return items;
}

export const api = {
    isAuthenticated() {
        return Boolean(getAccessToken());
    },

    clearSession() {
        clearTokens();
    },

    async checkConnection() {
        try {
            const res = await fetch(`${API_BASE_URL}/health`, {
                method: 'GET',
                signal: AbortSignal.timeout(2000),
            });
            return res.ok;
        } catch {
            return false;
        }
    },

    // --- Auth ---
    async register(userData) {
        return request('/auth/register', { method: 'POST', body: userData, auth: false });
    },

    async login(username, password) {
        const form = new URLSearchParams();
        form.set('username', username);
        form.set('password', password);
        const data = await request('/auth/login', { method: 'POST', body: form, auth: false });
        if (data.mfa_required) return data;
        if (!data.access_token) throw new Error('Login incompleto: no se recibió token.');
        saveTokens(data);
        return data;
    },

    async mfaVerify(mfa_token, code) {
        const data = await request('/auth/mfa/verify', {
            method: 'POST',
            body: { mfa_token, code },
            auth: false,
        });
        if (!data.access_token) throw new Error('MFA incompleto: no se recibió token.');
        saveTokens(data);
        return data;
    },

    async mfaSetup() {
        return request('/auth/mfa/setup', { method: 'POST' });
    },

    async mfaConfirm(code) {
        return request('/auth/mfa/confirm', { method: 'POST', body: { code } });
    },

    async logout() {
        const refresh_token = getRefreshToken();
        try {
            await request('/auth/logout', {
                method: 'POST',
                body: { refresh_token: refresh_token || null },
            });
        } catch {
            // ignore
        } finally {
            clearTokens();
        }
    },

    async me() {
        return request('/auth/me');
    },

    // --- Users ---
    async getUser(id) {
        return request(`/users/${id}`);
    },

    async updateUser(id, data) {
        return request(`/users/${id}`, { method: 'PUT', body: data });
    },

    async deactivateUser(id) {
        await request(`/users/${id}`, { method: 'DELETE' });
        return true;
    },

    // --- Accounts ---
    async getAccounts(includeInactive = false) {
        return fetchAllPages('/accounts', { include_inactive: includeInactive || undefined });
    },

    async getAccount(id) {
        return request(`/accounts/${id}`);
    },

    async createAccount(data) {
        return request('/accounts', { method: 'POST', body: data });
    },

    async updateAccount(id, data) {
        return request(`/accounts/${id}`, { method: 'PUT', body: data });
    },

    async deactivateAccount(id) {
        await request(`/accounts/${id}`, { method: 'DELETE' });
        return true;
    },

    async reactivateAccount(id) {
        return request(`/accounts/${id}/reactivate`, { method: 'POST' });
    },

    // --- Counterparties ---
    async getCounterparties(includeInactive = false) {
        return fetchAllPages('/counterparties', { include_inactive: includeInactive || undefined });
    },

    async getCounterparty(id) {
        return request(`/counterparties/${id}`);
    },

    async createCounterparty(data) {
        return request('/counterparties', { method: 'POST', body: data });
    },

    async updateCounterparty(id, data) {
        return request(`/counterparties/${id}`, { method: 'PUT', body: data });
    },

    async deactivateCounterparty(id) {
        await request(`/counterparties/${id}`, { method: 'DELETE' });
        return true;
    },

    async reactivateCounterparty(id) {
        return request(`/counterparties/${id}/reactivate`, { method: 'POST' });
    },

    // --- Categories / Subcategories ---
    async getCategories(includeInactive = false) {
        return fetchAllPages('/categories', { include_inactive: includeInactive || undefined });
    },

    async createCategory(data) {
        return request('/categories', { method: 'POST', body: data });
    },

    async updateCategory(id, data) {
        return request(`/categories/${id}`, { method: 'PUT', body: data });
    },

    async deactivateCategory(id) {
        await request(`/categories/${id}`, { method: 'DELETE' });
        return true;
    },

    async getSubcategories(categoryId = null, includeInactive = false) {
        return fetchAllPages('/subcategories', {
            ...(categoryId ? { category_id: categoryId } : {}),
            ...(includeInactive ? { include_inactive: true } : {}),
        });
    },

    async createSubcategory(data) {
        return request('/subcategories', { method: 'POST', body: data });
    },

    async updateSubcategory(id, data) {
        return request(`/subcategories/${id}`, { method: 'PUT', body: data });
    },

    async deactivateSubcategory(id) {
        await request(`/subcategories/${id}`, { method: 'DELETE' });
        return true;
    },

    // --- Transactions ---
    async getTransactions(filters = {}) {
        return fetchAllPages('/transactions', filters);
    },

    async getTransaction(id) {
        return request(`/transactions/${id}`);
    },

    async createTransaction(data) {
        return request('/transactions', { method: 'POST', body: data });
    },

    async updateTransaction(id, data) {
        return request(`/transactions/${id}`, { method: 'PUT', body: data });
    },

    async deleteTransaction(id) {
        await request(`/transactions/${id}`, { method: 'DELETE' });
        return true;
    },

    async createTransfer(data) {
        return request('/transactions/transfers', { method: 'POST', body: data });
    },

    async exportTransactions(filters = {}, format = 'csv') {
        const qs = toQuery({ ...filters, format });
        const res = await request(`/transactions/export?${qs}`, { raw: true });
        const blob = await res.blob();
        const disposition = res.headers.get('Content-Disposition') || '';
        const match = disposition.match(/filename="?([^"]+)"?/i);
        const filename = match?.[1] || `transactions.${format}`;
        return { blob, filename };
    },

    // --- Budgets ---
    async getBudgets(includeInactive = false) {
        return fetchAllPages('/budgets', { include_inactive: includeInactive || undefined });
    },

    async getBudgetStatus() {
        return request('/budgets/status');
    },

    async getBudget(id) {
        return request(`/budgets/${id}`);
    },

    async createBudget(data) {
        return request('/budgets', { method: 'POST', body: data });
    },

    async updateBudget(id, data) {
        return request(`/budgets/${id}`, { method: 'PUT', body: data });
    },

    async deactivateBudget(id) {
        await request(`/budgets/${id}`, { method: 'DELETE' });
        return true;
    },

    async reactivateBudget(id) {
        return request(`/budgets/${id}/reactivate`, { method: 'POST' });
    },

    // --- Reports ---
    async getReportSummary(params = {}) {
        const qs = toQuery(params);
        const suffix = qs.toString() ? `?${qs}` : '';
        return request(`/reports/summary${suffix}`);
    },
};
