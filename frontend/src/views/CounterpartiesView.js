export const CounterpartiesView = {
    render() {
        return `
            <div class="space-y-6 animate-fade-in">
                <div class="glass-card p-6 rounded-2xl flex flex-col md:flex-row md:items-center justify-between gap-4">
                    <div>
                        <h4 class="text-md font-semibold text-white mb-1">Contrapartes</h4>
                        <p class="text-xs text-slate-400">Personas o entidades asociadas a tus movimientos.</p>
                    </div>
                    <div class="flex flex-wrap items-center gap-3">
                        <label class="flex items-center gap-2 text-xs text-slate-400">
                            <input type="checkbox" id="cp-include-inactive" class="rounded border-slate-600">
                            Mostrar inactivas
                        </label>
                        <button onclick="window.openCounterpartyModal()" class="flex items-center gap-2 px-4 py-2 border border-indigo-500/30 hover:border-indigo-500 bg-indigo-500/10 text-indigo-400 rounded-xl text-sm font-semibold">
                            <i data-lucide="plus" class="w-4 h-4"></i> Nueva
                        </button>
                    </div>
                </div>
                <div class="glass-card rounded-2xl overflow-hidden">
                    <table class="w-full text-left">
                        <thead>
                            <tr class="bg-slate-800/30 text-xs text-slate-400 uppercase tracking-wider">
                                <th class="py-3 px-6">Nombre</th>
                                <th class="py-3 px-6">Banco</th>
                                <th class="py-3 px-6">Cuenta</th>
                                <th class="py-3 px-6">Estado</th>
                                <th class="py-3 px-6 text-center">Acciones</th>
                            </tr>
                        </thead>
                        <tbody id="counterparties-tbody" class="divide-y divide-slate-800/40 text-sm"></tbody>
                    </table>
                    <div id="cp-empty" class="p-10 text-center text-slate-500 hidden">Sin contrapartes registradas.</div>
                </div>
            </div>
        `;
    },

    init(state, utils) {
        const toggle = document.getElementById('cp-include-inactive');
        if (toggle) {
            toggle.checked = Boolean(state.ui?.cpIncludeInactive);
            toggle.onchange = () => window.reloadCounterparties?.(toggle.checked);
        }
        this.renderTable(state, utils);
    },

    renderTable(state, utils) {
        const tbody = document.getElementById('counterparties-tbody');
        const empty = document.getElementById('cp-empty');
        if (!tbody) return;
        tbody.innerHTML = '';
        const list = state.counterparties || [];
        if (!list.length) {
            if (empty) empty.classList.remove('hidden');
            return;
        }
        if (empty) empty.classList.add('hidden');

        list.forEach((c) => {
            const active = c.activo !== false;
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="py-3 px-6 font-medium text-white">${utils.escapeHtml(c.nombre)}</td>
                <td class="py-3 px-6 text-slate-400">${utils.escapeHtml(c.banco || '—')}</td>
                <td class="py-3 px-6 text-slate-400">${utils.escapeHtml(c.numero_cuenta || '—')}</td>
                <td class="py-3 px-6">
                    <span class="text-[10px] font-bold px-2 py-0.5 rounded-full ${active ? 'bg-emerald-500/15 text-emerald-400' : 'bg-slate-500/20 text-slate-400'}">
                        ${active ? 'Activa' : 'Inactiva'}
                    </span>
                </td>
                <td class="py-3 px-6">
                    <div class="flex justify-center gap-2">
                        ${active ? `
                            <button onclick="window.openCounterpartyModal(${c.id})" class="p-2 text-indigo-400 hover:bg-slate-800 rounded-lg" title="Editar"><i data-lucide="pencil" class="w-4 h-4"></i></button>
                            <button onclick="window.deactivateCounterpartyFlow(${c.id})" class="p-2 text-rose-400 hover:bg-slate-800 rounded-lg" title="Desactivar"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                        ` : `
                            <button onclick="window.reactivateCounterpartyFlow(${c.id})" class="p-2 text-emerald-400 hover:bg-slate-800 rounded-lg" title="Reactivar"><i data-lucide="rotate-ccw" class="w-4 h-4"></i></button>
                        `}
                    </div>
                </td>
            `;
            tbody.appendChild(tr);
        });
        lucide.createIcons();
    },
};
