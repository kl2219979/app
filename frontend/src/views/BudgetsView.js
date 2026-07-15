export const BudgetsView = {
    render() {
        return `
            <div class="space-y-6 animate-fade-in">
                <div class="glass-card p-6 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h4 class="text-md font-semibold text-white mb-1">Presupuestos mensuales</h4>
                        <p class="text-xs text-slate-400">Consumo del mes calendario actual.</p>
                    </div>
                    <div class="flex flex-wrap items-center gap-3">
                        <label class="flex items-center gap-2 text-xs text-slate-400">
                            <input type="checkbox" id="budgets-include-inactive" class="rounded border-slate-600">
                            Mostrar inactivos
                        </label>
                        <button onclick="window.openBudgetModal()" class="flex items-center gap-2 px-4 py-2 border border-indigo-500/30 bg-indigo-500/10 text-indigo-400 rounded-xl text-sm font-semibold">
                            <i data-lucide="sliders" class="w-4 h-4"></i> Ajustar límites
                        </button>
                    </div>
                </div>
                <div id="budgets-grid" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6"></div>
            </div>
        `;
    },

    init(state, utils) {
        const toggle = document.getElementById('budgets-include-inactive');
        if (toggle) {
            toggle.checked = Boolean(state.ui?.budgetsIncludeInactive);
            toggle.onchange = () => window.reloadBudgets?.(toggle.checked);
        }
        this.renderBudgetsGrid(state, utils);
    },

    renderBudgetsGrid(state, utils) {
        const grid = document.getElementById('budgets-grid');
        if (!grid) return;
        grid.innerHTML = '';

        const statusByCat = {};
        (state.budgetStatus || []).forEach((b) => {
            statusByCat[b.category_id] = b;
        });

        const includeInactive = Boolean(state.ui?.budgetsIncludeInactive);
        let cards = [];

        if (includeInactive) {
            cards = (state.budgets || []).map((b) => {
                const st = statusByCat[b.category_id];
                return {
                    budget_id: b.id,
                    category_id: b.category_id,
                    category_nombre: utils.categoryName(b.category_id),
                    limite: b.limite,
                    moneda: b.moneda,
                    gastado: st?.gastado ?? 0,
                    restante: st?.restante ?? b.limite,
                    pct_usado: st?.pct_usado ?? 0,
                    excedido: st?.excedido ?? false,
                    activo: b.activo !== false,
                };
            });
        } else {
            cards = (state.budgetStatus || []).map((b) => ({ ...b, activo: true }));
        }

        if (!cards.length) {
            grid.innerHTML = `<div class="glass-card p-10 rounded-2xl text-center text-slate-500 col-span-full">
                <p class="text-slate-400 font-semibold mb-1">Sin presupuestos</p>
                <p class="text-xs">Crea un límite por categoría.</p>
            </div>`;
            lucide.createIcons();
            return;
        }

        cards.forEach((b) => {
            const spent = utils.toNumber(b.gastado);
            const limit = utils.toNumber(b.limite);
            const percent = utils.toNumber(b.pct_usado);
            const isExceeded = Boolean(b.excedido);
            const active = b.activo !== false;
            const style = utils.categoryStyle(b.category_nombre);
            const currency = b.moneda || 'COP';
            let bar = 'bg-indigo-500';
            if (percent > 100 || isExceeded) bar = 'bg-rose-500 animate-pulse';
            else if (percent > 80) bar = 'bg-amber-500';

            const card = document.createElement('div');
            card.className = `glass-card p-6 rounded-2xl flex flex-col justify-between border ${isExceeded ? 'border-rose-500/30' : 'border-slate-800/80'} ${active ? '' : 'opacity-60'}`;
            card.innerHTML = `
                <div>
                    <div class="flex justify-between items-start mb-4">
                        <div class="flex items-center gap-3">
                            <div class="p-2.5 rounded-xl ${style.bg} ${style.text}"><i data-lucide="${style.icon}" class="w-5 h-5"></i></div>
                            <div>
                                <h4 class="font-bold text-white">${utils.escapeHtml(b.category_nombre)}</h4>
                                <span class="text-xs text-slate-400">Límite: ${utils.formatCurrency(limit, currency)}</span>
                            </div>
                        </div>
                        ${!active ? '<span class="text-[10px] text-slate-400">Inactivo</span>' : ''}
                        ${isExceeded && active ? '<span class="text-[10px] font-bold text-rose-400">Excedido</span>' : ''}
                    </div>
                    <div class="space-y-2 mt-4">
                        <div class="flex justify-between text-xs font-semibold">
                            <span class="text-slate-400">Consumido</span>
                            <span class="${isExceeded ? 'text-rose-400' : 'text-slate-200'}">${utils.formatCurrency(spent, currency)}</span>
                        </div>
                        <div class="w-full bg-slate-800 rounded-full h-2 overflow-hidden">
                            <div class="${bar} h-2 rounded-full" style="width: ${Math.min(percent, 100)}%"></div>
                        </div>
                        <div class="text-[11px] text-slate-500">${Math.round(percent)}% · Restante ${utils.formatCurrency(b.restante, currency)}</div>
                    </div>
                </div>
                <div class="mt-6 pt-4 border-t border-slate-800/50 flex justify-end gap-3">
                    ${active ? `
                        <button onclick="window.openBudgetModal(${b.category_id})" class="text-xs font-bold text-indigo-400">Ajustar</button>
                        <button onclick="window.deactivateBudgetFlow(${b.budget_id})" class="text-xs font-bold text-rose-400">Desactivar</button>
                    ` : `
                        <button onclick="window.reactivateBudgetFlow(${b.budget_id})" class="text-xs font-bold text-emerald-400">Reactivar</button>
                    `}
                </div>
            `;
            grid.appendChild(card);
        });
        lucide.createIcons();
    },
};
