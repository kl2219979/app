import './style.css';
import { api } from './services/api.js';
import { Router } from './router/router.js';

const CATEGORY_STYLES = {
    'Alimentación': { icon: 'utensils', color: '#10b981', bg: 'bg-emerald-500/10', text: 'text-emerald-400' },
    'Transporte': { icon: 'car', color: '#3b82f6', bg: 'bg-blue-500/10', text: 'text-blue-400' },
    'Vivienda': { icon: 'home', color: '#f59e0b', bg: 'bg-amber-500/10', text: 'text-amber-400' },
    'Salud': { icon: 'heart-pulse', color: '#ec4899', bg: 'bg-pink-500/10', text: 'text-pink-400' },
    'Ocio': { icon: 'party-popper', color: '#8b5cf6', bg: 'bg-violet-500/10', text: 'text-violet-400' },
    'Entretenimiento': { icon: 'party-popper', color: '#8b5cf6', bg: 'bg-violet-500/10', text: 'text-violet-400' },
    'Educación': { icon: 'graduation-cap', color: '#06b6d4', bg: 'bg-cyan-500/10', text: 'text-cyan-400' },
    'Servicios': { icon: 'plug', color: '#f59e0b', bg: 'bg-amber-500/10', text: 'text-amber-400' },
    'Ingresos': { icon: 'banknote', color: '#10b981', bg: 'bg-emerald-500/10', text: 'text-emerald-400' },
    'Transferencias': { icon: 'arrow-left-right', color: '#64748b', bg: 'bg-slate-500/10', text: 'text-slate-400' },
    'Otros': { icon: 'help-circle', color: '#64748b', bg: 'bg-slate-500/10', text: 'text-slate-400' },
};

const INCOME_CATEGORY_NAMES = new Set(['Ingresos']);

const state = {
    user: null,
    transactions: [],
    budgets: [],
    budgetStatus: [],
    categories: [],
    subcategories: [],
    accounts: [],
    counterparties: [],
    report: null,
    txFilters: {},
    reportFilters: {},
    ui: {
        accountsIncludeInactive: false,
        cpIncludeInactive: false,
        budgetsIncludeInactive: false,
    },
    pendingMfaToken: null,
};

const utils = {
    CATEGORY_STYLES,
    INCOME_CATEGORY_NAMES,
    categoryName(id) {
        return state.categories.find((c) => c.id === id)?.nombre || `Cat #${id}`;
    },
    subcategoryName(id) {
        return state.subcategories.find((s) => s.id === id)?.nombre || '';
    },
    counterpartyName(id) {
        return state.counterparties.find((c) => c.id === id)?.nombre || '';
    },
    categoryStyle(nombre) {
        return CATEGORY_STYLES[nombre] || { icon: 'help-circle', color: '#64748b', bg: 'bg-slate-500/10', text: 'text-slate-400' };
    },
    expenseCategories() {
        return state.categories.filter((c) => !INCOME_CATEGORY_NAMES.has(c.nombre) && c.nombre !== 'Transferencias' && c.activo !== false);
    },
    incomeCategories() {
        const incomes = state.categories.filter((c) => INCOME_CATEGORY_NAMES.has(c.nombre) && c.activo !== false);
        return incomes.length ? incomes : state.categories.filter((c) => c.activo !== false);
    },
    categoriesForTipo(tipo) {
        return tipo === 'ingreso' ? this.incomeCategories() : this.expenseCategories();
    },
    subcategoriesFor(categoryId) {
        return state.subcategories.filter((s) => s.category_id === categoryId && s.activo !== false);
    },
    toNumber(val) {
        const n = Number(val);
        return Number.isFinite(n) ? n : 0;
    },
    formatCurrency(val, currency = 'COP') {
        try {
            return new Intl.NumberFormat('es-CO', { style: 'currency', currency, maximumFractionDigits: 2 }).format(this.toNumber(val));
        } catch {
            return `$${this.toNumber(val).toFixed(2)}`;
        }
    },
    formatDate(dateString) {
        if (!dateString) return '';
        const raw = String(dateString).slice(0, 10);
        const parts = raw.split('-');
        if (parts.length !== 3) return dateString;
        const date = new Date(+parts[0], +parts[1] - 1, +parts[2]);
        return date.toLocaleDateString('es-ES', { day: '2-digit', month: 'short', year: 'numeric' });
    },
    escapeHtml(str) {
        if (typeof str !== 'string') return str;
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;');
    },
    initials(user) {
        if (!user) return '?';
        const a = (user.nombres || '')[0] || '';
        const b = (user.apellidos || '')[0] || '';
        return (a + b).toUpperCase() || (user.usuario || '?').slice(0, 2).toUpperCase();
    },
};

function showApp(authenticated) {
    document.getElementById('auth-screen')?.classList.toggle('hidden', authenticated);
    document.getElementById('app-shell')?.classList.toggle('hidden', !authenticated);
    document.getElementById('mfa-screen')?.classList.add('hidden');
}

function showMfaScreen(show) {
    document.getElementById('auth-screen')?.classList.toggle('hidden', show);
    document.getElementById('mfa-screen')?.classList.toggle('hidden', !show);
    document.getElementById('app-shell')?.classList.add('hidden');
}

function toggleMobileMenu(show) {
    const sidebar = document.getElementById('app-sidebar');
    const overlay = document.getElementById('mobile-overlay');
    if (show) {
        sidebar?.classList.remove('-translate-x-full');
        overlay?.classList.remove('hidden');
    } else {
        sidebar?.classList.add('-translate-x-full');
        overlay?.classList.add('hidden');
    }
}

function showAuthScreen(tab = 'login') {
    document.getElementById('auth-screen')?.classList.remove('hidden');
    document.getElementById('app-shell')?.classList.add('hidden');
    switchAuthTab(tab);
}

function closeAuthScreen() {
    document.getElementById('auth-screen')?.classList.add('hidden');
    document.getElementById('app-shell')?.classList.remove('hidden');
}

function updateUserDisplay() {
    if (!state.user) return;
    const initialsEl = document.getElementById('user-initials');
    const nameEl = document.getElementById('user-display-name');
    const roleEl = document.getElementById('user-display-role');
    if (initialsEl) initialsEl.textContent = utils.initials(state.user);
    if (nameEl) nameEl.textContent = `${state.user.nombres || ''} ${state.user.apellidos || ''}`.trim() || state.user.usuario;
    if (roleEl) roleEl.textContent = `${state.user.usuario}${state.user.rol === 'admin' ? ' · admin' : ''}`;
}

function serverTxFilters(raw = {}) {
    const out = {};
    ['tipo', 'medio_pago', 'date_from', 'date_to'].forEach((k) => {
        if (raw[k]) out[k] = raw[k];
    });
    ['account_id', 'category_id', 'contraparte_id', 'sub_category_id'].forEach((k) => {
        if (raw[k]) out[k] = Number(raw[k]);
    });
    return out;
}

async function loadAllData() {
    try {
        const txParams = serverTxFilters(state.txFilters);
        const reportParams = {};
        if (state.reportFilters.account_id) reportParams.account_id = Number(state.reportFilters.account_id);
        if (state.reportFilters.date_from) reportParams.date_from = state.reportFilters.date_from;
        if (state.reportFilters.date_to) reportParams.date_to = state.reportFilters.date_to;

        const [
            transactions, budgets, budgetStatus, categories, subcategories,
            accounts, counterparties, report, user,
        ] = await Promise.all([
            api.getTransactions(txParams),
            api.getBudgets(state.ui.budgetsIncludeInactive),
            api.getBudgetStatus(),
            api.getCategories(true),
            api.getSubcategories(null, true),
            api.getAccounts(state.ui.accountsIncludeInactive),
            api.getCounterparties(state.ui.cpIncludeInactive),
            api.getReportSummary(reportParams),
            api.me(),
        ]);

        state.transactions = transactions;
        state.budgets = budgets;
        state.budgetStatus = budgetStatus;
        state.categories = categories;
        state.subcategories = subcategories;
        state.accounts = accounts;
        state.counterparties = counterparties;
        state.report = report;
        state.user = user;

        updateUserDisplay();
        updateConnectionDisplay(true);
        Router.refreshActiveView();
    } catch (err) {
        console.error(err);
        updateConnectionDisplay(false);
        if (String(err.message).includes('Sesión expirada') || String(err.message).includes('credenciales')) {
            await handleLogout(false);
            showToast('Sesión expirada. Inicia sesión de nuevo.', 'error');
            return;
        }
        showToast(err.message || 'Error de conexión', 'error');
    }
}

async function runConnectionCheck() {
    updateConnectionDisplay(await api.checkConnection());
}

function updateConnectionDisplay(connected) {
    const statusText = document.getElementById('api-status');
    if (!statusText) return;
    if (connected) {
        statusText.innerHTML = `<span class="w-2.5 h-2.5 bg-emerald-500 rounded-full pulse-active"></span> Conectado`;
        statusText.className = 'flex items-center gap-1.5 text-emerald-400 font-semibold';
    } else {
        statusText.innerHTML = `<span class="w-2.5 h-2.5 bg-rose-500 rounded-full"></span> Desconectado`;
        statusText.className = 'flex items-center gap-1.5 text-rose-500 font-semibold';
    }
}

function openModal(modalId, contentId) {
    const modal = document.getElementById(modalId);
    const content = document.getElementById(contentId);
    if (!modal || !content) return;
    modal.classList.remove('pointer-events-none', 'opacity-0');
    content.classList.remove('scale-95');
    content.classList.add('scale-100');
    lucide.createIcons();
}

function closeModal(modalId, contentId) {
    const modal = document.getElementById(modalId);
    const content = document.getElementById(contentId);
    if (!modal || !content) return;
    modal.classList.add('opacity-0', 'pointer-events-none');
    content.classList.remove('scale-100');
    content.classList.add('scale-95');
}

function showToast(message, type = 'success') {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const toast = document.createElement('div');
    toast.className = 'toast';
    const icon = type === 'error' ? 'x-circle' : type === 'info' ? 'info' : 'check-circle';
    const iconClass = type === 'error' ? 'text-rose-400' : type === 'info' ? 'text-indigo-400' : 'text-emerald-400';
    toast.innerHTML = `<div class="${iconClass}"><i data-lucide="${icon}" class="w-5 h-5"></i></div><span class="text-sm font-semibold">${utils.escapeHtml(String(message))}</span>`;
    container.appendChild(toast);
    lucide.createIcons();
    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, 3500);
}

// --- Auth ---
function switchAuthTab(tab) {
    const loginForm = document.getElementById('login-form');
    const registerForm = document.getElementById('register-form');
    const tabs = document.querySelectorAll('#auth-screen .flex button');
    const pill = document.getElementById('auth-tab-pill');

    if (tab === 'login') {
        loginForm?.classList.remove('hidden');
        registerForm?.classList.add('hidden');
        if (pill) pill.style.transform = 'translateX(0)';
        if (tabs.length >= 2) {
            tabs[0].className = 'relative z-10 flex-1 py-2 text-sm font-semibold text-indigo-300 transition-colors duration-300';
            tabs[1].className = 'relative z-10 flex-1 py-2 text-sm font-semibold text-slate-400 hover:text-slate-200 transition-colors duration-300';
        }
    } else {
        loginForm?.classList.add('hidden');
        registerForm?.classList.remove('hidden');
        if (pill) pill.style.transform = 'translateX(100%)';
        if (tabs.length >= 2) {
            tabs[0].className = 'relative z-10 flex-1 py-2 text-sm font-semibold text-slate-400 hover:text-slate-200 transition-colors duration-300';
            tabs[1].className = 'relative z-10 flex-1 py-2 text-sm font-semibold text-indigo-300 transition-colors duration-300';
        }
    }
}

function returnToLanding() {
    if (state.user) {
        Router.navigateTo('dashboard');
    } else {
        closeAuthScreen();
        Router.navigateTo('landing');
    }
}

async function handleLogin(event) {
    event.preventDefault();
    const username = document.getElementById('login-username').value.trim();
    const password = document.getElementById('login-password').value;
    try {
        const result = await api.login(username, password);
        if (result.mfa_required) {
            state.pendingMfaToken = result.mfa_token;
            document.getElementById('mfa-code').value = '';
            showMfaScreen(true);
            showToast('Ingresa el código MFA', 'info');
            return;
        }
        showApp(true);
        showToast('Sesión iniciada');
        Router.init(state, utils);
        await loadAllData();
    } catch (err) {
        showToast(err.message || 'No se pudo iniciar sesión', 'error');
    }
}

async function handleMfaVerify(event) {
    event.preventDefault();
    const code = document.getElementById('mfa-code').value.trim();
    try {
        await api.mfaVerify(state.pendingMfaToken, code);
        state.pendingMfaToken = null;
        showApp(true);
        showToast('Sesión iniciada');
        Router.init(state, utils);
        await loadAllData();
    } catch (err) {
        showToast(err.message || 'Código MFA inválido', 'error');
    }
}

function cancelMfa() {
    state.pendingMfaToken = null;
    showMfaScreen(false);
    showApp(false);
}

async function handleRegister(event) {
    event.preventDefault();
    const payload = {
        nombres: document.getElementById('reg-nombres').value.trim(),
        apellidos: document.getElementById('reg-apellidos').value.trim(),
        fecha_nacimiento: document.getElementById('reg-fecha-nacimiento').value,
        genero: document.getElementById('reg-genero').value,
        correo: document.getElementById('reg-correo').value.trim(),
        usuario: document.getElementById('reg-usuario').value.trim(),
        contrasena: document.getElementById('reg-contrasena').value,
    };
    try {
        await api.register(payload);
        showToast('Cuenta creada. Inicia sesión.');
        document.getElementById('login-username').value = payload.usuario;
        switchAuthTab('login');
    } catch (err) {
        showToast(err.message || 'No se pudo registrar', 'error');
    }
}

async function handleLogout(showMessage = true) {
    try { await api.logout(); } catch { api.clearSession(); }
    state.user = null;
    state.pendingMfaToken = null;
    Router.navigateTo('landing');
    showAuthScreen('login');
    if (showMessage) showToast('Sesión cerrada', 'info');
}

// --- Filters / reload helpers ---
async function applyTransactionFilters(filters) {
    state.txFilters = { ...filters };
    delete state.txFilters.search;
    await loadAllData();
}

async function applyReportFilters(filters) {
    state.reportFilters = { ...filters };
    try {
        const params = {};
        if (filters.account_id) params.account_id = Number(filters.account_id);
        if (filters.date_from) params.date_from = filters.date_from;
        if (filters.date_to) params.date_to = filters.date_to;
        state.report = await api.getReportSummary(params);
        Router.refreshActiveView();
        showToast('Reporte actualizado');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function reloadAccounts(includeInactive) {
    state.ui.accountsIncludeInactive = includeInactive;
    state.accounts = await api.getAccounts(includeInactive);
    Router.refreshActiveView();
}

async function reloadCounterparties(includeInactive) {
    state.ui.cpIncludeInactive = includeInactive;
    state.counterparties = await api.getCounterparties(includeInactive);
    Router.refreshActiveView();
}

async function reloadBudgets(includeInactive) {
    state.ui.budgetsIncludeInactive = includeInactive;
    state.budgets = await api.getBudgets(includeInactive);
    state.budgetStatus = await api.getBudgetStatus();
    Router.refreshActiveView();
}

async function exportTransactionsFlow(format) {
    try {
        const { blob, filename } = await api.exportTransactions(serverTxFilters(state.txFilters), format);
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
        showToast(`Exportado ${format.toUpperCase()}`);
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Transaction modal ---
function populateAccountSelect(selectedId = null) {
    const select = document.getElementById('trans-account');
    if (!select) return;
    select.innerHTML = '';
    // Cash wallets belong to medio_pago=efectivo; exclude them from "cuenta" picker
    const active = state.accounts.filter(
        (a) => a.activo !== false && String(a.tipo).toLowerCase() !== 'efectivo'
    );
    if (!active.length) {
        select.innerHTML = '<option value="">Sin cuentas bancarias</option>';
        return;
    }
    active.forEach((a) => {
        const opt = document.createElement('option');
        opt.value = a.id;
        opt.textContent = `${a.banco} (${a.tipo}) · ${a.moneda}`;
        select.appendChild(opt);
    });
    if (selectedId) select.value = String(selectedId);
}

function populateCategorySelect(tipo, selectedId = null) {
    const select = document.getElementById('trans-category');
    if (!select) return;
    select.innerHTML = '';
    utils.categoriesForTipo(tipo).forEach((c) => {
        const opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.nombre;
        select.appendChild(opt);
    });
    if (selectedId) select.value = String(selectedId);
    populateSubcategorySelect(Number(select.value));
}

function populateSubcategorySelect(categoryId, selectedId = null) {
    const select = document.getElementById('trans-subcategory');
    if (!select) return;
    select.innerHTML = '';
    utils.subcategoriesFor(categoryId).forEach((s) => {
        const opt = document.createElement('option');
        opt.value = s.id;
        opt.textContent = s.nombre;
        select.appendChild(opt);
    });
    if (selectedId) select.value = String(selectedId);
}

function populateContraparteSelect(selectedId = null) {
    const select = document.getElementById('trans-contraparte');
    if (!select) return;
    select.innerHTML = '<option value="">Sin contraparte</option>';
    state.counterparties.filter((c) => c.activo !== false).forEach((c) => {
        const opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.nombre;
        select.appendChild(opt);
    });
    if (selectedId) select.value = String(selectedId);
}

function setMedioPago(medio) {
    document.getElementById('trans-medio-pago').value = medio;
    const active = 'py-2 text-sm font-semibold rounded-lg bg-indigo-500/10 text-indigo-300 border border-indigo-500/20';
    const idle = 'py-2 text-sm font-semibold rounded-lg text-slate-400 hover:text-slate-200';
    document.getElementById('btn-medio-cuenta').className = medio === 'cuenta' ? active : idle;
    document.getElementById('btn-medio-efectivo').className = medio === 'efectivo' ? active : idle;
    document.getElementById('wrap-account')?.classList.toggle('hidden', medio !== 'cuenta');
    document.getElementById('wrap-moneda')?.classList.toggle('hidden', medio !== 'efectivo');
}

function setFormType(tipo) {
    document.getElementById('trans-type').value = tipo;
    const btnE = document.getElementById('btn-type-expense');
    const btnI = document.getElementById('btn-type-income');
    if (tipo === 'gasto') {
        btnE.className = 'py-2 text-sm font-semibold rounded-lg bg-rose-500/10 text-rose-400 border border-rose-500/20';
        btnI.className = 'py-2 text-sm font-semibold rounded-lg text-slate-400 hover:text-slate-200';
    } else {
        btnI.className = 'py-2 text-sm font-semibold rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20';
        btnE.className = 'py-2 text-sm font-semibold rounded-lg text-slate-400 hover:text-slate-200';
    }
    populateCategorySelect(tipo);
}

function openTransactionModal(id = null) {
    const form = document.getElementById('transaction-form');
    const title = document.getElementById('modal-transaction-title');
    if (!form) return;
    form.reset();
    document.getElementById('trans-id').value = '';
    document.getElementById('trans-date').value = new Date().toISOString().split('T')[0];
    document.getElementById('trans-moneda').value = 'COP';
    populateAccountSelect();
    populateContraparteSelect();
    setMedioPago('cuenta');

    if (id) {
        title.textContent = 'Editar Transacción';
        const t = state.transactions.find((item) => String(item.id) === String(id));
        if (t) {
            if (String(t.tipo).startsWith('transferencia')) {
                showToast('Las transferencias no se editan aquí; usa desactivar.', 'info');
                return;
            }
            document.getElementById('trans-id').value = t.id;
            document.getElementById('trans-amount').value = utils.toNumber(t.monto);
            document.getElementById('trans-date').value = String(t.fecha).slice(0, 10);
            document.getElementById('trans-description').value = t.descripcion || '';
            setFormType(t.tipo === 'ingreso' ? 'ingreso' : 'gasto');
            populateCategorySelect(t.tipo === 'ingreso' ? 'ingreso' : 'gasto', t.category_id);
            populateSubcategorySelect(t.category_id, t.sub_category_id);
            populateContraparteSelect(t.contraparte_id);
            setMedioPago(t.medio_pago || 'cuenta');
            if (t.medio_pago === 'efectivo') {
                const wallet = state.accounts.find((a) => a.id === t.account_id);
                document.getElementById('trans-moneda').value = wallet?.moneda || 'COP';
            } else {
                populateAccountSelect(t.account_id);
            }
        }
    } else {
        title.textContent = 'Registrar Transacción';
        setFormType('gasto');
    }
    openModal('modal-transaction', 'modal-transaction-content');
}

function closeTransactionModal() {
    closeModal('modal-transaction', 'modal-transaction-content');
}

async function saveTransaction(event) {
    event.preventDefault();
    const id = document.getElementById('trans-id').value;
    const tipo = document.getElementById('trans-type').value;
    const monto = parseFloat(document.getElementById('trans-amount').value);
    const category_id = parseInt(document.getElementById('trans-category').value, 10);
    const sub_category_id = parseInt(document.getElementById('trans-subcategory').value, 10);
    const fecha = document.getElementById('trans-date').value;
    const descripcion = document.getElementById('trans-description').value.trim();
    const medio_pago = document.getElementById('trans-medio-pago').value;
    const contraparteVal = document.getElementById('trans-contraparte').value;

    if (!Number.isFinite(category_id) || category_id <= 0) {
        return showToast('Selecciona una categoría válida.', 'error');
    }
    if (!Number.isFinite(sub_category_id) || sub_category_id <= 0) {
        return showToast('Selecciona una subcategoría válida (el catálogo puede estar vacío).', 'error');
    }
    if (!Number.isFinite(monto) || monto <= 0) {
        return showToast('El monto debe ser mayor a 0.', 'error');
    }

    const payload = { tipo, monto, category_id, sub_category_id, fecha, descripcion, medio_pago };
    if (contraparteVal) payload.contraparte_id = Number(contraparteVal);
    else payload.contraparte_id = null;

    if (medio_pago === 'cuenta') {
        const account_id = parseInt(document.getElementById('trans-account').value, 10);
        if (!account_id) return showToast('Selecciona una cuenta bancaria.', 'error');
        payload.account_id = account_id;
    } else {
        payload.moneda = document.getElementById('trans-moneda').value.trim() || 'COP';
        payload.account_id = null;
    }

    try {
        if (id) await api.updateTransaction(id, payload);
        else await api.createTransaction(payload);
        closeTransactionModal();
        showToast(id ? 'Transacción actualizada' : 'Transacción creada');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function deleteTransactionFlow(id) {
    if (!confirm('¿Desactivar esta transacción?')) return;
    try {
        await api.deleteTransaction(id);
        showToast('Transacción desactivada', 'info');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Budgets ---
function openBudgetModal(categoryId = null) {
    const select = document.getElementById('budget-category');
    if (!select) return;
    document.getElementById('budget-form').reset();
    document.getElementById('budget-id').value = '';
    select.innerHTML = '';
    utils.expenseCategories().forEach((c) => {
        const opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.nombre;
        select.appendChild(opt);
    });
    if (categoryId) {
        select.value = String(categoryId);
        const existing = state.budgets.find((b) => b.category_id === Number(categoryId) && b.activo !== false);
        if (existing) {
            document.getElementById('budget-id').value = existing.id;
            document.getElementById('budget-limit').value = utils.toNumber(existing.limite);
            document.getElementById('budget-moneda').value = existing.moneda || 'COP';
        }
    }
    openModal('modal-budget', 'modal-budget-content');
}

function closeBudgetModal() {
    closeModal('modal-budget', 'modal-budget-content');
}

async function saveBudget(event) {
    event.preventDefault();
    const budgetId = document.getElementById('budget-id').value;
    const category_id = parseInt(document.getElementById('budget-category').value, 10);
    const limite = parseFloat(document.getElementById('budget-limit').value);
    const moneda = document.getElementById('budget-moneda').value.trim() || 'COP';
    try {
        const existing = budgetId
            ? state.budgets.find((b) => String(b.id) === String(budgetId))
            : state.budgets.find((b) => b.category_id === category_id && b.activo !== false);
        if (existing) await api.updateBudget(existing.id, { limite, moneda });
        else await api.createBudget({ category_id, limite, moneda, periodo: 'mensual' });
        closeBudgetModal();
        showToast('Presupuesto guardado');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function deactivateBudgetFlow(id) {
    if (!confirm('¿Desactivar este presupuesto?')) return;
    try {
        await api.deactivateBudget(id);
        showToast('Presupuesto desactivado', 'info');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function reactivateBudgetFlow(id) {
    try {
        await api.reactivateBudget(id);
        showToast('Presupuesto reactivado');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Accounts ---
function openAccountModal(id = null) {
    const form = document.getElementById('account-form');
    form.reset();
    document.getElementById('account-id').value = '';
    document.getElementById('account-moneda').value = 'COP';
    document.getElementById('account-saldo').value = '0';
    document.getElementById('wrap-account-saldo')?.classList.remove('hidden');
    document.getElementById('modal-account-title').textContent = 'Nueva Cuenta';
    if (id) {
        const a = state.accounts.find((x) => x.id === Number(id));
        if (a) {
            document.getElementById('modal-account-title').textContent = 'Editar Cuenta';
            document.getElementById('account-id').value = a.id;
            document.getElementById('account-banco').value = a.banco;
            document.getElementById('account-tipo').value = a.tipo;
            document.getElementById('account-moneda').value = a.moneda;
            document.getElementById('wrap-account-saldo')?.classList.add('hidden');
        }
    }
    openModal('modal-account', 'modal-account-content');
}

function closeAccountModal() {
    closeModal('modal-account', 'modal-account-content');
}

async function saveAccount(event) {
    event.preventDefault();
    const id = document.getElementById('account-id').value;
    const tipo = document.getElementById('account-tipo').value.trim();
    if (tipo.toLowerCase() === 'efectivo') {
        return showToast('El tipo "efectivo" es un wallet interno; usa ahorros/corriente/digital u otro tipo bancario.', 'error');
    }
    try {
        if (id) {
            await api.updateAccount(id, {
                banco: document.getElementById('account-banco').value.trim(),
                tipo,
                moneda: document.getElementById('account-moneda').value.trim() || 'COP',
            });
        } else {
            await api.createAccount({
                banco: document.getElementById('account-banco').value.trim(),
                tipo,
                moneda: document.getElementById('account-moneda').value.trim() || 'COP',
                saldo_inicial: parseFloat(document.getElementById('account-saldo').value) || 0,
            });
        }
        closeAccountModal();
        showToast('Cuenta guardada');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function deactivateAccountFlow(id) {
    if (!confirm('¿Desactivar esta cuenta?')) return;
    try {
        await api.deactivateAccount(id);
        showToast('Cuenta desactivada', 'info');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function reactivateAccountFlow(id) {
    try {
        await api.reactivateAccount(id);
        showToast('Cuenta reactivada');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Counterparties ---
function openCounterpartyModal(id = null) {
    document.getElementById('counterparty-form').reset();
    document.getElementById('cp-id').value = '';
    document.getElementById('modal-cp-title').textContent = 'Nueva contraparte';
    if (id) {
        const c = state.counterparties.find((x) => x.id === Number(id));
        if (c) {
            document.getElementById('modal-cp-title').textContent = 'Editar contraparte';
            document.getElementById('cp-id').value = c.id;
            document.getElementById('cp-nombre').value = c.nombre || '';
            document.getElementById('cp-banco').value = c.banco || '';
            document.getElementById('cp-cuenta').value = c.numero_cuenta || '';
            document.getElementById('cp-notas').value = c.notas || '';
        }
    }
    openModal('modal-counterparty', 'modal-counterparty-content');
}

function closeCounterpartyModal() {
    closeModal('modal-counterparty', 'modal-counterparty-content');
}

async function saveCounterparty(event) {
    event.preventDefault();
    const id = document.getElementById('cp-id').value;
    const payload = {
        nombre: document.getElementById('cp-nombre').value.trim(),
        banco: document.getElementById('cp-banco').value.trim() || null,
        numero_cuenta: document.getElementById('cp-cuenta').value.trim() || null,
        notas: document.getElementById('cp-notas').value.trim() || null,
    };
    try {
        if (id) await api.updateCounterparty(id, payload);
        else await api.createCounterparty(payload);
        closeCounterpartyModal();
        showToast('Contraparte guardada');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function deactivateCounterpartyFlow(id) {
    if (!confirm('¿Desactivar contraparte?')) return;
    try {
        await api.deactivateCounterparty(id);
        showToast('Contraparte desactivada', 'info');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function reactivateCounterpartyFlow(id) {
    try {
        await api.reactivateCounterparty(id);
        showToast('Contraparte reactivada');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Transfers ---
async function saveTransfer(event) {
    event.preventDefault();
    const payload = {
        from_account_id: Number(document.getElementById('transfer-from').value),
        to_account_id: Number(document.getElementById('transfer-to').value),
        monto: parseFloat(document.getElementById('transfer-amount').value),
        fecha: document.getElementById('transfer-date').value,
        category_id: Number(document.getElementById('transfer-category').value),
        sub_category_id: Number(document.getElementById('transfer-subcategory').value),
        descripcion: document.getElementById('transfer-description').value.trim() || 'Transferencia entre cuentas',
    };
    if (!payload.from_account_id || !payload.to_account_id) {
        return showToast('Selecciona cuenta origen y destino.', 'error');
    }
    if (payload.from_account_id === payload.to_account_id) {
        return showToast('Las cuentas deben ser distintas.', 'error');
    }
    if (!payload.category_id || !payload.sub_category_id) {
        return showToast('Selecciona categoría y subcategoría de transferencia.', 'error');
    }
    if (!Number.isFinite(payload.monto) || payload.monto <= 0) {
        return showToast('El monto debe ser mayor a 0.', 'error');
    }
    try {
        await api.createTransfer(payload);
        showToast('Transferencia registrada');
        document.getElementById('transfer-form')?.reset();
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Catalog ---
function openCategoryModal(id = null) {
    document.getElementById('category-form').reset();
    document.getElementById('cat-id').value = '';
    document.getElementById('modal-cat-title').textContent = 'Nueva categoría';
    if (id) {
        const c = state.categories.find((x) => x.id === Number(id));
        if (c) {
            document.getElementById('modal-cat-title').textContent = 'Editar categoría';
            document.getElementById('cat-id').value = c.id;
            document.getElementById('cat-nombre').value = c.nombre;
            document.getElementById('cat-descripcion').value = c.descripcion || '';
        }
    }
    openModal('modal-category', 'modal-category-content');
}

function closeCategoryModal() {
    closeModal('modal-category', 'modal-category-content');
}

async function saveCategory(event) {
    event.preventDefault();
    const id = document.getElementById('cat-id').value;
    const payload = {
        nombre: document.getElementById('cat-nombre').value.trim(),
        descripcion: document.getElementById('cat-descripcion').value.trim() || '',
    };
    try {
        if (id) await api.updateCategory(id, payload);
        else await api.createCategory(payload);
        closeCategoryModal();
        showToast('Categoría guardada');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function deactivateCategoryFlow(id) {
    if (!confirm('¿Desactivar categoría y sus subcategorías?')) return;
    try {
        await api.deactivateCategory(id);
        showToast('Categoría desactivada', 'info');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

function openSubcategoryModal(id = null) {
    document.getElementById('subcategory-form').reset();
    document.getElementById('sub-id').value = '';
    document.getElementById('modal-sub-title').textContent = 'Nueva subcategoría';
    const sel = document.getElementById('sub-category-id');
    sel.innerHTML = '';
    state.categories.filter((c) => c.activo !== false).forEach((c) => {
        const opt = document.createElement('option');
        opt.value = c.id;
        opt.textContent = c.nombre;
        sel.appendChild(opt);
    });
    if (id) {
        const s = state.subcategories.find((x) => x.id === Number(id));
        if (s) {
            document.getElementById('modal-sub-title').textContent = 'Editar subcategoría';
            document.getElementById('sub-id').value = s.id;
            sel.value = String(s.category_id);
            document.getElementById('sub-nombre').value = s.nombre;
            document.getElementById('sub-descripcion').value = s.descripcion || '';
        }
    }
    openModal('modal-subcategory', 'modal-subcategory-content');
}

function closeSubcategoryModal() {
    closeModal('modal-subcategory', 'modal-subcategory-content');
}

async function saveSubcategory(event) {
    event.preventDefault();
    const id = document.getElementById('sub-id').value;
    const payload = {
        category_id: Number(document.getElementById('sub-category-id').value),
        nombre: document.getElementById('sub-nombre').value.trim(),
        descripcion: document.getElementById('sub-descripcion').value.trim() || '',
    };
    try {
        if (id) await api.updateSubcategory(id, payload);
        else await api.createSubcategory(payload);
        closeSubcategoryModal();
        showToast('Subcategoría guardada');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function deactivateSubcategoryFlow(id) {
    if (!confirm('¿Desactivar subcategoría?')) return;
    try {
        await api.deactivateSubcategory(id);
        showToast('Subcategoría desactivada', 'info');
        await loadAllData();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Settings ---
async function saveProfile(event) {
    event.preventDefault();
    if (!state.user) return;
    const payload = {
        nombres: document.getElementById('profile-nombres').value.trim(),
        apellidos: document.getElementById('profile-apellidos').value.trim(),
        fecha_nacimiento: document.getElementById('profile-fecha').value,
        genero: document.getElementById('profile-genero').value.trim(),
        correo: document.getElementById('profile-correo').value.trim(),
        usuario: document.getElementById('profile-usuario').value.trim(),
    };
    const pwd = document.getElementById('profile-contrasena').value;
    if (pwd) payload.contrasena = pwd;
    try {
        state.user = await api.updateUser(state.user.id, payload);
        updateUserDisplay();
        showToast('Perfil actualizado');
        Router.refreshActiveView();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function startMfaSetup() {
    try {
        const data = await api.mfaSetup();
        document.getElementById('mfa-setup-box')?.classList.remove('hidden');
        document.getElementById('mfa-secret').textContent = data.secret;
        document.getElementById('mfa-uri').textContent = data.otpauth_uri;
        showToast('Secreto MFA generado', 'info');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function confirmMfaSetup() {
    const code = document.getElementById('mfa-confirm-code').value.trim();
    try {
        state.user = await api.mfaConfirm(code);
        updateUserDisplay();
        showToast('MFA activado');
        Router.refreshActiveView();
    } catch (err) {
        showToast(err.message, 'error');
    }
}

async function deactivateOwnAccount() {
    if (!state.user) return;
    if (!confirm('¿Desactivar tu cuenta de acceso? Deberás cerrar sesión.')) return;
    try {
        await api.deactivateUser(state.user.id);
        await handleLogout(false);
        showToast('Cuenta desactivada', 'info');
    } catch (err) {
        showToast(err.message, 'error');
    }
}

// --- Boot ---
document.addEventListener('DOMContentLoaded', async () => {
    const bind = {
        switchTab: (id) => { toggleMobileMenu(false); Router.navigateTo(id); },
        switchAuthTab, handleLogin, handleRegister, handleLogout, handleMfaVerify, cancelMfa,
        openTransactionModal, closeTransactionModal, setFormType, setMedioPago, saveTransaction, deleteTransactionFlow,
        openBudgetModal, closeBudgetModal, saveBudget, deactivateBudgetFlow, reactivateBudgetFlow,
        openAccountModal, closeAccountModal, saveAccount, deactivateAccountFlow, reactivateAccountFlow,
        openCounterpartyModal, closeCounterpartyModal, saveCounterparty, deactivateCounterpartyFlow, reactivateCounterpartyFlow,
        saveTransfer, applyTransactionFilters, applyReportFilters, exportTransactionsFlow,
        reloadAccounts, reloadCounterparties, reloadBudgets,
        openCategoryModal, closeCategoryModal, saveCategory, deactivateCategoryFlow,
        openSubcategoryModal, closeSubcategoryModal, saveSubcategory, deactivateSubcategoryFlow,
        saveProfile, startMfaSetup, confirmMfaSetup, deactivateOwnAccount, loadAllData,
        toggleMobileMenu, showAuthScreen, closeAuthScreen, returnToLanding
    };
    Object.assign(window, bind);

    document.getElementById('trans-category')?.addEventListener('change', (e) => {
        populateSubcategorySelect(Number(e.target.value));
    });

    updateConnectionDisplay(await api.checkConnection());

    if (api.isAuthenticated()) {
        showApp(true);
        Router.init(state, utils);
        await loadAllData();
    } else {
        showApp(true);
        Router.init(state, utils);
        Router.navigateTo('landing');
    }

    setInterval(runConnectionCheck, 5000);
});
