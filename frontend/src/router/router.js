import { DashboardView } from '../views/DashboardView.js';
import { TransactionsView } from '../views/TransactionsView.js';
import { BudgetsView } from '../views/BudgetsView.js';
import { AccountsView } from '../views/AccountsView.js';
import { CounterpartiesView } from '../views/CounterpartiesView.js';
import { TransfersView } from '../views/TransfersView.js';
import { CatalogView } from '../views/CatalogView.js';
import { SettingsView } from '../views/SettingsView.js';
import { LandingPageView } from '../views/LandingPageView.js';

const routes = {
    dashboard: DashboardView,
    transactions: TransactionsView,
    transfers: TransfersView,
    accounts: AccountsView,
    counterparties: CounterpartiesView,
    budgets: BudgetsView,
    catalog: CatalogView,
    settings: SettingsView,
    landing: LandingPageView,
};

const headers = {
    dashboard: ['Panel de Control', 'Resumen, comparativas y desgloses del reporte.'],
    transactions: ['Transacciones', 'Filtros en servidor, export y movimientos.'],
    transfers: ['Transferencias', 'Mover saldo entre tus cuentas propias.'],
    accounts: ['Cuentas', 'Saldos, moneda y activación de cuentas.'],
    counterparties: ['Contrapartes', 'Contactos externos vinculados a movimientos.'],
    budgets: ['Presupuestos', 'Límites mensuales y consumo del periodo.'],
    catalog: ['Catálogo', 'Categorías y subcategorías (admin + MFA).'],
    settings: ['Ajustes', 'Perfil, MFA y desactivación de cuenta.'],
    landing: ['LuCash', 'Descubre el control total de tus finanzas.'],
};

export const Router = {
    activeRoute: 'dashboard',
    state: null,
    utils: null,

    init(appState, appUtils) {
        this.state = appState;
        this.utils = appUtils;
        this.updateNavVisibility();
        this.navigateTo('dashboard');
    },

    updateNavVisibility() {
        const catalogNav = document.getElementById('nav-catalog');
        const user = this.state?.user;
        const showCatalog = user?.rol === 'admin' && user?.mfa_enabled;
        if (catalogNav) catalogNav.classList.toggle('hidden', !showCatalog);
    },

    navigateTo(routeId, { allowAuthenticatedLanding = false } = {}) {
        if (routeId === 'catalog') {
            const user = this.state?.user;
            if (!(user?.rol === 'admin' && user?.mfa_enabled)) {
                routeId = 'dashboard';
            }
        }
        if (!routes[routeId]) return;

        // Route Guard for private routes
        if (routeId !== 'landing' && !this.state?.user) {
            routeId = 'landing';
        }

        // Route Guard for public routes (e.g. landing)
        if (routeId === 'landing' && this.state?.user && !allowAuthenticatedLanding) {
            routeId = 'dashboard';
        }

        this.activeRoute = routeId;

        const sidebar = document.getElementById('app-sidebar');
        const main = document.getElementById('app-main');
        const header = document.getElementById('app-header');
        const viewport = document.getElementById('router-viewport');

        if (routeId === 'landing') {
            sidebar?.classList.add('hidden');
            sidebar?.classList.remove('flex');
            main?.classList.remove('md:ml-64');
            header?.classList.add('hidden');
            header?.classList.remove('flex');
            viewport?.classList.remove('p-3', 'p-4', 'sm:p-4', 'md:p-8');
            viewport?.classList.add('p-0');
        } else {
            sidebar?.classList.remove('hidden');
            sidebar?.classList.add('flex');
            main?.classList.add('md:ml-64');
            header?.classList.remove('hidden');
            header?.classList.add('flex');
            viewport?.classList.remove('p-0');
            viewport?.classList.add('p-3', 'sm:p-4', 'md:p-8');
        }

        if (viewport) viewport.innerHTML = routes[routeId].render();
        routes[routeId].init(this.state, this.utils);

        document.querySelectorAll('.nav-link').forEach((el) => el.classList.remove('active'));
        document.getElementById(`nav-${routeId}`)?.classList.add('active');

        let [title, subtitle] = headers[routeId] || ['', ''];
        if (routeId === 'dashboard' && this.state?.user) {
            const rawName = this.state.user.nombres || this.state.user.usuario || 'usuario';
            const firstName = String(rawName).trim().split(/\s+/)[0];
            title = `Hola, ${firstName}`;
            subtitle = '';
        }
        const titleEl = document.getElementById('page-title');
        const subtitleEl = document.getElementById('page-subtitle');
        if (titleEl) titleEl.textContent = title;
        if (subtitleEl) subtitleEl.textContent = subtitle;

        lucide.createIcons();
    },

    refreshActiveView() {
        if (!this.state || !this.utils) return;
        this.updateNavVisibility();
        const viewport = document.getElementById('router-viewport');
        if (viewport && routes[this.activeRoute]) {
            viewport.innerHTML = routes[this.activeRoute].render();
            routes[this.activeRoute].init(this.state, this.utils);
            lucide.createIcons();
        }
    },
};
