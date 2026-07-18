let categoryChartInstance = null;
let trendChartInstance = null;

function fmtDelta(utils, val) {
    const n = utils.toNumber(val);
    const sign = n > 0 ? '+' : '';
    return `${sign}${utils.formatCurrency(n)}`;
}

function deltaTone(val, { invert = false } = {}) {
    const n = Number(val);
    if (!Number.isFinite(n) || n === 0) {
        return { text: 'text-slate-300', chip: 'bg-slate-500/15 text-slate-400', icon: 'minus' };
    }
    const positive = invert ? n < 0 : n > 0;
    if (positive) {
        return { text: 'text-emerald-400', chip: 'bg-emerald-500/15 text-emerald-400', icon: 'trending-up' };
    }
    return { text: 'text-rose-400', chip: 'bg-rose-500/15 text-rose-400', icon: 'trending-down' };
}

function fmtPct(val) {
    if (val === null || val === undefined || val === '') return null;
    const n = Number(val);
    if (!Number.isFinite(n)) return null;
    const sign = n > 0 ? '+' : '';
    return `${sign}${n.toFixed(1)}%`;
}

function fmtRange(utils, from, to) {
    return `${utils.formatDate(from)} — ${utils.formatDate(to)}`;
}

export const DashboardView = {
    render() {
        return `
            <div class="space-y-8 animate-fade-in">
                <div class="glass-card p-4 rounded-2xl grid grid-cols-1 md:grid-cols-4 gap-3 items-end">
                    <div class="space-y-1">
                        <label class="text-[10px] font-semibold text-slate-500 uppercase">Cuenta</label>
                        <select id="report-account" class="glass-input w-full px-3 py-2 rounded-xl text-sm"><option value="">Todas</option></select>
                    </div>
                    <div class="space-y-1">
                        <label class="text-[10px] font-semibold text-slate-500 uppercase">Desde</label>
                        <input type="date" id="report-date-from" class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                    </div>
                    <div class="space-y-1">
                        <label class="text-[10px] font-semibold text-slate-500 uppercase">Hasta</label>
                        <input type="date" id="report-date-to" class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                    </div>
                    <button id="btn-apply-report" class="px-4 py-2 bg-indigo-500/20 border border-indigo-500/40 text-indigo-300 rounded-xl text-sm font-semibold">Actualizar reporte</button>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
                    <div class="glass-card p-5 rounded-2xl"><p class="text-xs text-slate-400 mb-2">Saldo neto</p><h3 id="stat-balance" class="text-2xl font-extrabold text-white">$0</h3></div>
                    <div class="glass-card p-5 rounded-2xl"><p class="text-xs text-slate-400 mb-2">Ingresos</p><h3 id="stat-income" class="text-2xl font-extrabold text-emerald-400">$0</h3></div>
                    <div class="glass-card p-5 rounded-2xl"><p class="text-xs text-slate-400 mb-2">Gastos</p><h3 id="stat-expense" class="text-2xl font-extrabold text-rose-400">$0</h3></div>
                    <div class="glass-card p-5 rounded-2xl"><p class="text-xs text-slate-400 mb-2">Transferencias</p><h3 id="stat-transfers" class="text-2xl font-extrabold text-indigo-300">$0</h3></div>
                    <div class="glass-card p-5 rounded-2xl"><p class="text-xs text-slate-400 mb-2">Presupuesto</p><h3 id="stat-budget-percent" class="text-2xl font-extrabold text-slate-200">0%</h3><div class="mt-2 w-full bg-slate-800 rounded-full h-1.5"><div id="stat-budget-bar" class="bg-indigo-500 h-1.5 rounded-full" style="width:0%"></div></div></div>
                </div>

                <div id="period-comparison" class="glass-card p-6 rounded-2xl hidden overflow-hidden relative"></div>

                <div class="grid grid-cols-1 lg:grid-cols-5 gap-6">
                    <div class="glass-card p-6 rounded-2xl lg:col-span-2">
                        <h4 class="text-md font-semibold text-white mb-1">Gastos por categoría</h4>
                        <div class="h-64 relative flex items-center justify-center">
                            <canvas id="categoryChart"></canvas>
                            <div id="no-chart-data" class="absolute inset-0 flex items-center justify-center text-xs text-slate-500 hidden">Sin datos</div>
                        </div>
                    </div>
                    <div class="glass-card p-6 rounded-2xl lg:col-span-3">
                        <h4 class="text-md font-semibold text-white mb-1">Flujo mensual</h4>
                        <div class="h-64 relative"><canvas id="trendChart"></canvas></div>
                    </div>
                </div>

                <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
                    <div class="glass-card p-5 rounded-2xl">
                        <h5 class="text-sm font-semibold text-white mb-3">Por cuenta</h5>
                        <ul id="list-by-account" class="space-y-2 text-xs text-slate-400"></ul>
                    </div>
                    <div class="glass-card p-5 rounded-2xl">
                        <h5 class="text-sm font-semibold text-white mb-3">Por medio de pago</h5>
                        <ul id="list-by-medio" class="space-y-2 text-xs text-slate-400"></ul>
                    </div>
                    <div class="glass-card p-5 rounded-2xl">
                        <h5 class="text-sm font-semibold text-white mb-3">Por contraparte</h5>
                        <ul id="list-by-counterparty" class="space-y-2 text-xs text-slate-400"></ul>
                    </div>
                </div>

                <div class="glass-card p-5 rounded-2xl">
                    <h5 class="text-sm font-semibold text-white mb-3">Subcategorías (gastos)</h5>
                    <ul id="list-by-subcat" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-x-8 gap-y-3 text-xs text-slate-400"></ul>
                </div>

                <div class="glass-card rounded-2xl overflow-hidden">
                    <div class="p-6 border-b border-slate-800/50 flex justify-between items-center">
                        <div>
                            <h4 class="text-md font-semibold text-white">Transacciones recientes</h4>
                            <p class="text-xs text-slate-400">Últimos movimientos activos.</p>
                        </div>
                        <button onclick="window.switchTab('transactions')" class="text-xs font-semibold text-indigo-400">Ver todas</button>
                    </div>
                    <table class="w-full text-left text-sm">
                        <thead>
                            <tr class="bg-slate-800/30 text-xs text-slate-400 uppercase">
                                <th class="py-3 px-6">Detalle</th>
                                <th class="py-3 px-6">Categoría</th>
                                <th class="py-3 px-6">Fecha</th>
                                <th class="py-3 px-6 text-right">Monto</th>
                            </tr>
                        </thead>
                        <tbody id="recent-transactions-tbody"></tbody>
                    </table>
                </div>
            </div>
        `;
    },

    init(state, utils) {
        this.setupReportFilters(state);
        this.updateStats(state, utils);
        this.renderBreakdowns(state, utils);
        this.renderRecentTransactions(state, utils);
        this.renderCharts(state, utils);
    },

    setupReportFilters(state) {
        const sel = document.getElementById('report-account');
        const f = state.reportFilters || {};
        if (sel) {
            sel.innerHTML = '<option value="">Todas</option>';
            (state.accounts || []).filter((a) => a.activo !== false).forEach((a) => {
                const opt = document.createElement('option');
                opt.value = a.id;
                opt.textContent = `${a.banco} (${a.moneda})`;
                sel.appendChild(opt);
            });
            if (f.account_id) sel.value = String(f.account_id);
        }
        const from = document.getElementById('report-date-from');
        const to = document.getElementById('report-date-to');
        if (from && f.date_from) from.value = f.date_from;
        if (to && f.date_to) to.value = f.date_to;
        document.getElementById('btn-apply-report').onclick = () => {
            window.applyReportFilters?.({
                account_id: document.getElementById('report-account')?.value || '',
                date_from: document.getElementById('report-date-from')?.value || '',
                date_to: document.getElementById('report-date-to')?.value || '',
            });
        };
    },

    updateStats(state, utils) {
        const report = state.report;
        const totalIncome = utils.toNumber(report?.total_ingresos);
        const totalExpense = utils.toNumber(report?.total_gastos);
        const net = utils.toNumber(report?.balance_neto);
        const transfers = utils.toNumber(report?.total_transferencias);

        const set = (id, val, cls) => {
            const el = document.getElementById(id);
            if (!el) return;
            el.textContent = utils.formatCurrency(val);
            if (cls) el.className = cls;
        };
        set('stat-balance', net, net < 0 ? 'text-2xl font-extrabold text-rose-400' : 'text-2xl font-extrabold text-white');
        set('stat-income', totalIncome);
        set('stat-expense', totalExpense);
        set('stat-transfers', transfers);

        let totalBudget = 0;
        let totalSpent = 0;
        (state.budgetStatus || []).forEach((b) => {
            totalBudget += utils.toNumber(b.limite);
            totalSpent += utils.toNumber(b.gastado);
        });
        const pctEl = document.getElementById('stat-budget-percent');
        const bar = document.getElementById('stat-budget-bar');
        if (pctEl && bar) {
            const pct = totalBudget > 0 ? Math.min(Math.round((totalSpent / totalBudget) * 100), 100) : 0;
            pctEl.textContent = `${pct}%`;
            bar.style.width = `${pct}%`;
        }

        const pc = report?.period_comparison;
        const box = document.getElementById('period-comparison');
        if (box && pc) {
            box.classList.remove('hidden');
            const incomeTone = deltaTone(pc.ingresos_delta);
            const expenseTone = deltaTone(pc.gastos_delta, { invert: true });
            const balanceTone = deltaTone(pc.balance_neto_delta);
            const incomePct = fmtPct(pc.ingresos_change_pct);
            const expensePct = fmtPct(pc.gastos_change_pct);

            box.innerHTML = `
                <div class="absolute -right-8 -top-8 w-40 h-40 bg-indigo-500/10 rounded-full blur-3xl pointer-events-none"></div>
                <div class="relative space-y-5">
                    <div class="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3">
                        <div>
                            <div class="flex items-center gap-2 mb-1">
                                <div class="p-1.5 rounded-lg bg-indigo-500/15 text-indigo-300">
                                    <i data-lucide="git-compare" class="w-4 h-4"></i>
                                </div>
                                <h4 class="text-sm font-semibold text-white tracking-tight">Comparativa de periodo</h4>
                            </div>
                            <p class="text-xs text-slate-500">Variación frente al periodo anterior de igual duración.</p>
                        </div>
                        <div class="flex flex-wrap gap-2 text-[11px]">
                            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                                <span class="w-1.5 h-1.5 rounded-full bg-indigo-400"></span>
                                Actual · ${fmtRange(utils, pc.current_from, pc.current_to)}
                            </span>
                            <span class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-slate-800/80 text-slate-400 border border-slate-700/60">
                                <span class="w-1.5 h-1.5 rounded-full bg-slate-500"></span>
                                Anterior · ${fmtRange(utils, pc.previous_from, pc.previous_to)}
                            </span>
                        </div>
                    </div>

                    <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                        <div class="rounded-xl border border-slate-800/80 bg-slate-950/40 p-4">
                            <div class="flex items-center justify-between mb-3">
                                <span class="text-[11px] font-medium uppercase tracking-wide text-slate-500">Ingresos</span>
                                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${incomeTone.chip}">
                                    <i data-lucide="${incomeTone.icon}" class="w-3 h-3"></i>
                                    ${incomePct || 'Δ'}
                                </span>
                            </div>
                            <p class="text-xl font-extrabold tracking-tight ${incomeTone.text}">${fmtDelta(utils, pc.ingresos_delta)}</p>
                            <p class="text-[11px] text-slate-500 mt-2">
                                ${utils.formatCurrency(pc.previous?.total_ingresos)} → ${utils.formatCurrency(pc.current?.total_ingresos)}
                            </p>
                        </div>

                        <div class="rounded-xl border border-slate-800/80 bg-slate-950/40 p-4">
                            <div class="flex items-center justify-between mb-3">
                                <span class="text-[11px] font-medium uppercase tracking-wide text-slate-500">Gastos</span>
                                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${expenseTone.chip}">
                                    <i data-lucide="${expenseTone.icon}" class="w-3 h-3"></i>
                                    ${expensePct || 'Δ'}
                                </span>
                            </div>
                            <p class="text-xl font-extrabold tracking-tight ${expenseTone.text}">${fmtDelta(utils, pc.gastos_delta)}</p>
                            <p class="text-[11px] text-slate-500 mt-2">
                                ${utils.formatCurrency(pc.previous?.total_gastos)} → ${utils.formatCurrency(pc.current?.total_gastos)}
                            </p>
                        </div>

                        <div class="rounded-xl border border-slate-800/80 bg-slate-950/40 p-4">
                            <div class="flex items-center justify-between mb-3">
                                <span class="text-[11px] font-medium uppercase tracking-wide text-slate-500">Balance neto</span>
                                <span class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-semibold ${balanceTone.chip}">
                                    <i data-lucide="${balanceTone.icon}" class="w-3 h-3"></i>
                                    Neto
                                </span>
                            </div>
                            <p class="text-xl font-extrabold tracking-tight ${balanceTone.text}">${fmtDelta(utils, pc.balance_neto_delta)}</p>
                            <p class="text-[11px] text-slate-500 mt-2">
                                ${utils.formatCurrency(pc.previous?.balance_neto)} → ${utils.formatCurrency(pc.current?.balance_neto)}
                            </p>
                        </div>
                    </div>
                </div>
            `;
            lucide.createIcons();
        } else if (box) {
            box.classList.add('hidden');
            box.innerHTML = '';
        }
    },

    renderBreakdowns(state, utils) {
        const report = state.report || {};
        const fill = (id, items, mapFn) => {
            const el = document.getElementById(id);
            if (!el) return;
            el.innerHTML = '';
            if (!items?.length) {
                el.innerHTML = '<li class="text-slate-600">Sin datos</li>';
                return;
            }
            items.forEach((item) => {
                const li = document.createElement('li');
                li.className = 'flex justify-between gap-2 border-b border-slate-800/40 pb-1';
                li.innerHTML = mapFn(item);
                el.appendChild(li);
            });
        };

        fill('list-by-account', report.by_account, (a) =>
            `<span>${utils.escapeHtml(a.banco)}</span><span class="text-slate-300">${utils.formatCurrency(a.saldo, a.moneda)}</span>`);
        fill('list-by-medio', report.by_medio_pago, (m) =>
            `<span>${utils.escapeHtml(m.medio_pago)}</span><span>I ${utils.formatCurrency(m.total_ingresos)} / G ${utils.formatCurrency(m.total_gastos)}</span>`);
        fill('list-by-counterparty', report.by_counterparty, (c) =>
            `<span>${utils.escapeHtml(c.nombre)}</span><span>G ${utils.formatCurrency(c.total_gastos)}</span>`);
        fill('list-by-subcat', report.by_subcategory_gastos, (s) =>
            `<span class="truncate mr-2" title="${utils.escapeHtml(s.category_nombre)} / ${utils.escapeHtml(s.nombre)}">${utils.escapeHtml(s.category_nombre)} / ${utils.escapeHtml(s.nombre)}</span><span class="text-slate-300 font-medium whitespace-nowrap">${utils.formatCurrency(s.total)}</span>`);
    },

    renderRecentTransactions(state, utils) {
        const tbody = document.getElementById('recent-transactions-tbody');
        if (!tbody) return;
        tbody.innerHTML = '';
        const recent = [...(state.transactions || [])]
            .sort((a, b) => String(b.fecha).localeCompare(String(a.fecha)) || (b.id - a.id))
            .slice(0, 5);
        if (!recent.length) {
            tbody.innerHTML = '<tr><td colspan="4" class="py-8 text-center text-slate-500">Sin movimientos</td></tr>';
            return;
        }
        recent.forEach((t) => {
            const cat = utils.categoryName(t.category_id);
            const style = utils.categoryStyle(cat);
            const isIncome = t.tipo === 'ingreso' || t.tipo === 'transferencia_entrada';
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td class="py-3 px-6 text-white">
                    <div class="flex items-center gap-2">
                        <div class="p-1.5 rounded-lg ${style.bg} ${style.text}"><i data-lucide="${style.icon}" class="w-3.5 h-3.5"></i></div>
                        ${utils.escapeHtml(t.descripcion || cat)}
                    </div>
                </td>
                <td class="py-3 px-6 text-slate-400">${utils.escapeHtml(cat)}</td>
                <td class="py-3 px-6 text-slate-400">${utils.formatDate(t.fecha)}</td>
                <td class="py-3 px-6 text-right ${isIncome ? 'text-emerald-400' : 'text-slate-300'} font-semibold">${isIncome ? '+' : '-'}${utils.formatCurrency(t.monto)}</td>
            `;
            tbody.appendChild(tr);
        });
        lucide.createIcons();
    },

    renderCharts(state, utils) {
        const categoryCanvas = document.getElementById('categoryChart');
        const noChartAlert = document.getElementById('no-chart-data');
        const trendCanvas = document.getElementById('trendChart');
        if (!categoryCanvas || !trendCanvas) return;

        const report = state.report;
        const gastos = report?.by_category_gastos || [];
        const labels = gastos.map((c) => c.nombre);
        const data = gastos.map((c) => utils.toNumber(c.total));
        const totalExpense = data.reduce((a, b) => a + b, 0);

        if (!totalExpense) {
            categoryCanvas.style.display = 'none';
            noChartAlert?.classList.remove('hidden');
        } else {
            categoryCanvas.style.display = 'block';
            noChartAlert?.classList.add('hidden');
            if (categoryChartInstance) categoryChartInstance.destroy();
            categoryChartInstance = new Chart(categoryCanvas, {
                type: 'doughnut',
                data: {
                    labels,
                    datasets: [{
                        data,
                        backgroundColor: labels.map((l) => utils.categoryStyle(l).color),
                        borderWidth: 0,
                    }],
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'right', labels: { color: '#94a3b8', font: { size: 11 } } },
                    },
                    cutout: '70%',
                },
            });
        }

        const months = report?.by_month || [];
        const labelMonths = months.map((m) => {
            const d = new Date(m.year, m.month - 1, 1);
            return d.toLocaleDateString('es-ES', { month: 'short', year: '2-digit' });
        });
        if (trendChartInstance) trendChartInstance.destroy();
        trendChartInstance = new Chart(trendCanvas, {
            type: 'bar',
            data: {
                labels: labelMonths.length ? labelMonths : ['—'],
                datasets: [
                    {
                        label: 'Ingresos',
                        data: months.map((m) => utils.toNumber(m.total_ingresos)),
                        backgroundColor: 'rgba(16, 185, 129, 0.85)',
                        borderRadius: 6,
                    },
                    {
                        label: 'Gastos',
                        data: months.map((m) => utils.toNumber(m.total_gastos)),
                        backgroundColor: 'rgba(244, 63, 94, 0.85)',
                        borderRadius: 6,
                    },
                ],
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: { legend: { labels: { color: '#94a3b8' } } },
                scales: {
                    x: { ticks: { color: '#64748b' }, grid: { display: false } },
                    y: { ticks: { color: '#64748b' }, grid: { color: 'rgba(255,255,255,0.05)' } },
                },
            },
        });
    },
};
