export const TransfersView = {
    render() {
        return `
            <div class="space-y-6 animate-fade-in">
                <div class="glass-card w-full max-w-xl p-4 sm:p-6 rounded-2xl">
                    <h4 class="text-md font-semibold text-white mb-1">Transferencia entre cuentas</h4>
                    <p class="text-xs leading-relaxed text-slate-400 mb-6">Mueve dinero entre tus cuentas propias (misma moneda).</p>
                    <div id="transfer-hint" class="hidden mb-4 p-3 rounded-xl border border-amber-500/30 bg-amber-500/10 text-amber-300 text-xs">
                        Necesitas al menos 2 cuentas activas.
                    </div>
                    <form id="transfer-form" onsubmit="window.saveTransfer(event)" class="space-y-4">
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Desde</label>
                            <select id="transfer-from" required class="glass-input w-full px-3 py-2.5 rounded-xl text-sm"></select>
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Hacia</label>
                            <select id="transfer-to" required class="glass-input w-full px-3 py-2.5 rounded-xl text-sm"></select>
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Monto</label>
                            <input type="number" id="transfer-amount" step="0.01" min="0.01" required class="glass-input w-full px-3 py-2.5 rounded-xl text-sm">
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Fecha</label>
                            <input type="date" id="transfer-date" required class="glass-input w-full px-3 py-2.5 rounded-xl text-sm">
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Categoría</label>
                            <select id="transfer-category" required class="glass-input w-full px-3 py-2.5 rounded-xl text-sm"></select>
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Subcategoría</label>
                            <select id="transfer-subcategory" required class="glass-input w-full px-3 py-2.5 rounded-xl text-sm"></select>
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Descripción</label>
                            <input type="text" id="transfer-description" maxlength="255" value="Transferencia entre cuentas" class="glass-input w-full px-3 py-2.5 rounded-xl text-sm">
                        </div>
                        <button type="submit" id="transfer-submit" class="w-full py-2.5 bg-gradient-to-r from-indigo-500 to-purple-600 text-white rounded-xl text-sm font-semibold">
                            Transferir
                        </button>
                    </form>
                </div>
            </div>
        `;
    },

    init(state, utils) {
        const activeAccounts = (state.accounts || []).filter((a) => a.activo !== false);
        const hint = document.getElementById('transfer-hint');
        const submit = document.getElementById('transfer-submit');
        const from = document.getElementById('transfer-from');
        const to = document.getElementById('transfer-to');
        const date = document.getElementById('transfer-date');
        const cat = document.getElementById('transfer-category');
        const sub = document.getElementById('transfer-subcategory');

        if (date) date.value = utils.localDateInputValue();

        const fillAccounts = (select, list) => {
            if (!select) return;
            select.innerHTML = '';
            list.forEach((a) => {
                const opt = document.createElement('option');
                opt.value = a.id;
                opt.dataset.moneda = a.moneda;
                opt.textContent = `${a.banco} (${a.tipo}) · ${a.moneda} · ${utils.formatCurrency(a.saldo, a.moneda)}`;
                select.appendChild(opt);
            });
        };

        const syncToByCurrency = () => {
            if (!from || !to) return;
            const fromAcc = activeAccounts.find((a) => String(a.id) === String(from.value));
            const moneda = fromAcc?.moneda;
            const compatible = activeAccounts.filter(
                (a) => a.moneda === moneda && String(a.id) !== String(from.value)
            );
            fillAccounts(to, compatible);
            if (hint) {
                const msg = compatible.length
                    ? ''
                    : 'No hay otra cuenta activa con la misma moneda.';
                hint.textContent = msg || 'Necesitas al menos 2 cuentas activas con la misma moneda.';
                hint.classList.toggle('hidden', compatible.length > 0 && activeAccounts.length >= 2);
            }
            if (submit) submit.disabled = compatible.length === 0;
        };

        fillAccounts(from, activeAccounts);
        if (from) from.onchange = syncToByCurrency;
        syncToByCurrency();

        const needsHint = activeAccounts.length < 2;
        if (needsHint && hint) {
            hint.classList.remove('hidden');
            hint.textContent = 'Necesitas al menos 2 cuentas activas.';
        }
        if (submit && needsHint) submit.disabled = true;

        if (cat) {
            cat.innerHTML = '';
            const cats = (state.categories || []).filter((c) => c.activo !== false);
            cats.forEach((c) => {
                const opt = document.createElement('option');
                opt.value = c.id;
                opt.textContent = c.nombre;
                if (c.nombre === 'Transferencias') opt.selected = true;
                cat.appendChild(opt);
            });
            const fillSubs = () => {
                if (!sub) return;
                sub.innerHTML = '';
                const cid = Number(cat.value);
                const subs = utils.subcategoriesFor(cid);
                if (!subs.length) {
                    const opt = document.createElement('option');
                    opt.value = '';
                    opt.textContent = 'Sin subcategorías';
                    sub.appendChild(opt);
                    return;
                }
                subs.forEach((s) => {
                    const opt = document.createElement('option');
                    opt.value = s.id;
                    opt.textContent = s.nombre;
                    sub.appendChild(opt);
                });
            };
            cat.onchange = fillSubs;
            fillSubs();
        }
    },
};
