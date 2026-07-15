export const TransactionsView = {
    render() {
        return `
            <div class="space-y-6 animate-fade-in">
                <div class="glass-card p-6 rounded-2xl space-y-4">
                    <div class="flex flex-wrap items-center justify-between gap-3">
                        <h4 class="text-sm font-semibold text-white">Filtros (servidor)</h4>
                        <div class="flex gap-2">
                            <button type="button" onclick="window.exportTransactionsFlow('csv')" class="text-xs px-3 py-1.5 border border-slate-700 rounded-lg text-slate-300 hover:text-white">Export CSV</button>
                            <button type="button" onclick="window.exportTransactionsFlow('json')" class="text-xs px-3 py-1.5 border border-slate-700 rounded-lg text-slate-300 hover:text-white">Export JSON</button>
                        </div>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-4 gap-3">
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Tipo</label>
                            <select id="filter-type" class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                                <option value="">Todos</option>
                                <option value="gasto">Gasto</option>
                                <option value="ingreso">Ingreso</option>
                                <option value="transferencia_salida">Transferencia salida</option>
                                <option value="transferencia_entrada">Transferencia entrada</option>
                            </select>
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Cuenta</label>
                            <select id="filter-account" class="glass-input w-full px-3 py-2 rounded-xl text-sm"><option value="">Todas</option></select>
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Categoría</label>
                            <select id="filter-category" class="glass-input w-full px-3 py-2 rounded-xl text-sm"><option value="">Todas</option></select>
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Contraparte</label>
                            <select id="filter-contraparte" class="glass-input w-full px-3 py-2 rounded-xl text-sm"><option value="">Todas</option></select>
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Medio</label>
                            <select id="filter-medio" class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                                <option value="">Todos</option>
                                <option value="cuenta">Cuenta</option>
                                <option value="efectivo">Efectivo</option>
                            </select>
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Desde</label>
                            <input type="date" id="filter-date-from" class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Hasta</label>
                            <input type="date" id="filter-date-to" class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                        </div>
                        <div class="space-y-1">
                            <label class="text-[10px] font-semibold text-slate-500 uppercase">Buscar</label>
                            <input type="text" id="filter-search" placeholder="Concepto..." class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                        </div>
                    </div>
                    <div class="flex gap-2">
                        <button id="btn-apply-filters" class="px-4 py-2 bg-indigo-500/20 border border-indigo-500/40 text-indigo-300 rounded-xl text-sm font-semibold">Aplicar</button>
                        <button id="btn-reset-filters" class="px-4 py-2 border border-slate-700 text-slate-300 rounded-xl text-sm">Limpiar</button>
                    </div>
                </div>

                <div class="glass-card rounded-2xl overflow-hidden">
                    <div class="overflow-x-auto">
                        <table class="w-full text-left border-collapse">
                            <thead>
                                <tr class="bg-slate-800/30 text-xs text-slate-400 uppercase tracking-wider">
                                    <th class="py-4 px-6 font-semibold">Detalle</th>
                                    <th class="py-4 px-6 font-semibold">Tipo</th>
                                    <th class="py-4 px-6 font-semibold">Categoría</th>
                                    <th class="py-4 px-6 font-semibold">Fecha</th>
                                    <th class="py-4 px-6 font-semibold text-right">Monto</th>
                                    <th class="py-4 px-6 font-semibold text-center">Acciones</th>
                                </tr>
                            </thead>
                            <tbody id="all-transactions-tbody" class="divide-y divide-slate-800/40 text-sm"></tbody>
                        </table>
                    </div>
                    <div id="no-transactions-alert" class="p-12 text-center text-slate-500 hidden">
                        <h5 class="text-slate-400 font-semibold mb-1">Sin registros</h5>
                        <p class="text-xs">Ajusta filtros o crea una transacción.</p>
                    </div>
                </div>
            </div>
        `;
    },

    init(state, utils) {
        this.fillFilterSelects(state);
        this.restoreFilters(state);
        this.setupListeners(state, utils);
        this.renderTable(state, utils);
    },

    fillFilterSelects(state) {
        const fill = (id, items, labelFn) => {
            const el = document.getElementById(id);
            if (!el) return;
            const current = el.value;
            el.innerHTML = '<option value="">Todas</option>';
            items.forEach((item) => {
                const opt = document.createElement('option');
                opt.value = item.id;
                opt.textContent = labelFn(item);
                el.appendChild(opt);
            });
            if (current) el.value = current;
        };
        fill('filter-account', state.accounts || [], (a) => `${a.banco} (${a.moneda})`);
        fill('filter-category', state.categories || [], (c) => c.nombre);
        fill('filter-contraparte', (state.counterparties || []).filter((c) => c.activo !== false), (c) => c.nombre);
    },

    restoreFilters(state) {
        const f = state.txFilters || {};
        const set = (id, val) => {
            const el = document.getElementById(id);
            if (el && val !== undefined && val !== null) el.value = val;
        };
        set('filter-type', f.tipo || '');
        set('filter-account', f.account_id || '');
        set('filter-category', f.category_id || '');
        set('filter-contraparte', f.contraparte_id || '');
        set('filter-medio', f.medio_pago || '');
        set('filter-date-from', f.date_from || '');
        set('filter-date-to', f.date_to || '');
        set('filter-search', f.search || '');
    },

    collectFilters() {
        return {
            tipo: document.getElementById('filter-type')?.value || '',
            account_id: document.getElementById('filter-account')?.value || '',
            category_id: document.getElementById('filter-category')?.value || '',
            contraparte_id: document.getElementById('filter-contraparte')?.value || '',
            medio_pago: document.getElementById('filter-medio')?.value || '',
            date_from: document.getElementById('filter-date-from')?.value || '',
            date_to: document.getElementById('filter-date-to')?.value || '',
            search: document.getElementById('filter-search')?.value || '',
        };
    },

    setupListeners(state, utils) {
        // onclick replaces prior handlers (refreshActiveView remounts DOM often,
        // but guard against accidental double-bind if init is called twice on same nodes)
        const applyBtn = document.getElementById('btn-apply-filters');
        const resetBtn = document.getElementById('btn-reset-filters');
        const searchInput = document.getElementById('filter-search');
        if (applyBtn) {
            applyBtn.onclick = () => window.applyTransactionFilters?.(this.collectFilters());
        }
        if (resetBtn) {
            resetBtn.onclick = () => window.applyTransactionFilters?.({});
        }
        if (searchInput) {
            searchInput.oninput = () => this.renderTable(state, utils);
        }
    },

    renderTable(state, utils) {
        const tbody = document.getElementById('all-transactions-tbody');
        const alertEl = document.getElementById('no-transactions-alert');
        if (!tbody) return;
        tbody.innerHTML = '';

        const search = (document.getElementById('filter-search')?.value || '').toLowerCase().trim();
        let rows = [...(state.transactions || [])];
        if (search) {
            rows = rows.filter((t) => {
                const cat = utils.categoryName(t.category_id).toLowerCase();
                const desc = (t.descripcion || '').toLowerCase();
                return desc.includes(search) || cat.includes(search);
            });
        }

        if (!rows.length) {
            if (alertEl) alertEl.classList.remove('hidden');
            return;
        }
        if (alertEl) alertEl.classList.add('hidden');

        rows.forEach((t) => {
            const catName = utils.categoryName(t.category_id);
            const style = utils.categoryStyle(catName);
            const isIncome = t.tipo === 'ingreso' || t.tipo === 'transferencia_entrada';
            const isTransfer = String(t.tipo || '').startsWith('transferencia');
            const amountClass = isIncome ? 'text-emerald-400 font-bold text-right' : 'text-slate-200 font-bold text-right';
            const amountFormatted = `${isIncome ? '+' : '-'}${utils.formatCurrency(t.monto)}`;
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="py-4 px-6 font-semibold text-white max-w-sm truncate">
                    <div class="flex items-center gap-3">
                        <div class="p-2 rounded-lg ${style.bg} ${style.text}"><i data-lucide="${style.icon}" class="w-4 h-4"></i></div>
                        <div>
                            <span>${utils.escapeHtml(t.descripcion || catName)}</span>
                            ${t.grupo_transferencia ? `<p class="text-[10px] text-slate-500">grupo ${utils.escapeHtml(String(t.grupo_transferencia).slice(0, 8))}…</p>` : ''}
                        </div>
                    </div>
                </td>
                <td class="py-4 px-6 text-slate-400 text-xs">${utils.escapeHtml(t.tipo)}</td>
                <td class="py-4 px-6 text-slate-300">${utils.escapeHtml(catName)}</td>
                <td class="py-4 px-6 text-slate-400">${utils.formatDate(t.fecha)}</td>
                <td class="py-4 px-6 ${amountClass}">${amountFormatted}</td>
                <td class="py-4 px-6">
                    <div class="flex justify-center gap-2">
                        ${!isTransfer ? `<button onclick="window.openTransactionModal('${t.id}')" class="p-2 text-indigo-400 hover:bg-slate-800 rounded-lg"><i data-lucide="pencil" class="w-4 h-4"></i></button>` : ''}
                        <button onclick="window.deleteTransactionFlow('${t.id}')" class="p-2 text-rose-400 hover:bg-slate-800 rounded-lg"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                    </div>
                </td>
            `;
            tbody.appendChild(tr);
        });
        lucide.createIcons();
    },
};
