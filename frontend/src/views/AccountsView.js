export const AccountsView = {
    render() {
        return `
            <div class="space-y-6 animate-fade-in">
                <div class="glass-card p-4 sm:p-6 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h4 class="text-md font-semibold text-white mb-1">Cuentas</h4>
                        <p class="text-xs text-slate-400">Saldo, moneda y estado. El saldo solo cambia con movimientos.</p>
                    </div>
                    <div class="flex flex-col items-stretch gap-3 sm:flex-row sm:flex-wrap sm:items-center">
                        <label class="flex items-center gap-2 text-xs text-slate-400">
                            <input type="checkbox" id="accounts-include-inactive" class="rounded border-slate-600">
                            Mostrar inactivas
                        </label>
                        <button onclick="window.openAccountModal()" class="flex items-center justify-center gap-2 px-4 py-2 border border-indigo-500/30 hover:border-indigo-500 bg-indigo-500/10 text-indigo-400 rounded-xl text-sm font-semibold">
                            <i data-lucide="plus" class="w-4 h-4"></i> Nueva cuenta
                        </button>
                    </div>
                </div>
                <div id="accounts-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-6"></div>
            </div>
        `;
    },

    init(state, utils) {
        const toggle = document.getElementById('accounts-include-inactive');
        if (toggle) {
            toggle.checked = Boolean(state.ui?.accountsIncludeInactive);
            toggle.onchange = () => window.reloadAccounts?.(toggle.checked);
        }
        this.renderGrid(state, utils);
    },

    renderGrid(state, utils) {
        const grid = document.getElementById('accounts-grid');
        if (!grid) return;
        grid.innerHTML = '';

        const list = state.accounts || [];
        if (!list.length) {
            grid.innerHTML = `<div class="glass-card p-8 sm:p-10 rounded-2xl text-center text-slate-500 col-span-full">
                <p class="text-slate-400 font-semibold mb-1">Sin cuentas</p>
                <p class="text-xs">Crea una cuenta para registrar movimientos con medio “cuenta”.</p>
            </div>`;
            lucide.createIcons();
            return;
        }

        list.forEach((a) => {
            const active = a.activo !== false;
            const card = document.createElement('div');
            card.className = `glass-card p-4 sm:p-6 rounded-2xl border ${active ? 'border-slate-800/80' : 'border-slate-700/40 opacity-70'}`;
            card.innerHTML = `
                <div class="flex justify-between items-start mb-4">
                    <div>
                        <h4 class="font-bold text-white">${utils.escapeHtml(a.banco)}</h4>
                        <p class="text-xs text-slate-400">${utils.escapeHtml(a.tipo)} · ${utils.escapeHtml(a.moneda)}</p>
                    </div>
                    <span class="text-[10px] font-bold px-2 py-0.5 rounded-full ${active ? 'bg-emerald-500/15 text-emerald-400' : 'bg-slate-500/20 text-slate-400'}">
                        ${active ? 'Activa' : 'Inactiva'}
                    </span>
                </div>
                <p class="break-words text-xl sm:text-2xl font-extrabold text-white mb-4">${utils.formatCurrency(a.saldo, a.moneda)}</p>
                <div class="grid grid-cols-2 gap-2 pt-3 border-t border-slate-800/50">
                    ${active ? `
                        <button onclick="window.openAccountModal(${a.id})" class="text-xs font-bold text-indigo-400 hover:text-indigo-300 px-2 py-1">Editar</button>
                        <button onclick="window.deactivateAccountFlow(${a.id})" class="text-xs font-bold text-rose-400 hover:text-rose-300 px-2 py-1">Desactivar</button>
                    ` : `
                        <button onclick="window.reactivateAccountFlow(${a.id})" class="col-span-2 text-xs font-bold text-emerald-400 hover:text-emerald-300 px-2 py-1">Reactivar</button>
                    `}
                </div>
            `;
            grid.appendChild(card);
        });
        lucide.createIcons();
    },
};
