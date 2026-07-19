export const CatalogView = {
    render() {
        return `
            <div class="space-y-8 animate-fade-in">
                <div class="glass-card p-4 rounded-xl border border-amber-500/20 bg-amber-500/5 text-amber-200 text-xs">
                    Solo administradores con MFA activo pueden modificar el catálogo.
                </div>

                <section class="space-y-4">
                    <div class="flex flex-wrap items-center justify-between gap-3">
                        <h4 class="text-md font-semibold text-white">Categorías</h4>
                        <button onclick="window.openCategoryModal()" class="px-3 text-xs font-bold text-indigo-400 hover:text-indigo-300">+ Nueva categoría</button>
                    </div>
                    <div class="glass-card rounded-2xl overflow-hidden">
                        <table class="desktop-table w-full text-left text-sm">
                            <thead>
                                <tr class="bg-slate-800/30 text-xs text-slate-400 uppercase">
                                    <th class="py-3 px-6">Nombre</th>
                                    <th class="py-3 px-6">Descripción</th>
                                    <th class="py-3 px-6">Estado</th>
                                    <th class="py-3 px-6 text-center">Acciones</th>
                                </tr>
                            </thead>
                            <tbody id="catalog-categories-tbody"></tbody>
                        </table>
                        <div id="catalog-categories-cards" class="mobile-card-list p-3"></div>
                    </div>
                </section>

                <section class="space-y-4">
                    <div class="flex flex-wrap items-center justify-between gap-3">
                        <h4 class="text-md font-semibold text-white">Subcategorías</h4>
                        <button onclick="window.openSubcategoryModal()" class="px-3 text-xs font-bold text-indigo-400 hover:text-indigo-300">+ Nueva subcategoría</button>
                    </div>
                    <div class="glass-card rounded-2xl overflow-hidden">
                        <table class="desktop-table w-full text-left text-sm">
                            <thead>
                                <tr class="bg-slate-800/30 text-xs text-slate-400 uppercase">
                                    <th class="py-3 px-6">Nombre</th>
                                    <th class="py-3 px-6">Categoría</th>
                                    <th class="py-3 px-6">Estado</th>
                                    <th class="py-3 px-6 text-center">Acciones</th>
                                </tr>
                            </thead>
                            <tbody id="catalog-subcategories-tbody"></tbody>
                        </table>
                        <div id="catalog-subcategories-cards" class="mobile-card-list p-3"></div>
                    </div>
                </section>
            </div>
        `;
    },

    init(state, utils) {
        this.renderCategories(state, utils);
        this.renderSubcategories(state, utils);
    },

    renderCategories(state, utils) {
        const tbody = document.getElementById('catalog-categories-tbody');
        const cards = document.getElementById('catalog-categories-cards');
        if (!tbody || !cards) return;
        tbody.innerHTML = '';
        cards.innerHTML = '';
        (state.categories || []).forEach((c) => {
            const active = c.activo !== false;
            const actions = active ? `
                <button onclick="window.openCategoryModal(${c.id})" class="inline-flex items-center justify-center gap-2 px-3 py-2 text-indigo-300 border border-indigo-500/20 bg-indigo-500/10 rounded-lg"><i data-lucide="pencil" class="w-4 h-4"></i><span class="text-xs font-semibold">Editar</span></button>
                <button onclick="window.deactivateCategoryFlow(${c.id})" class="inline-flex items-center justify-center gap-2 px-3 py-2 text-rose-300 border border-rose-500/20 bg-rose-500/10 rounded-lg"><i data-lucide="trash-2" class="w-4 h-4"></i><span class="text-xs font-semibold">Desactivar</span></button>
            ` : '<span class="col-span-2 py-2 text-center text-xs text-slate-500">Sin acciones disponibles</span>';
            const tr = document.createElement('tr');
            tr.className = 'border-b border-slate-800/30';
            tr.innerHTML = `
                <td class="py-3 px-6 text-white font-medium">${utils.escapeHtml(c.nombre)}</td>
                <td class="py-3 px-6 text-slate-400">${utils.escapeHtml(c.descripcion || '—')}</td>
                <td class="py-3 px-6 text-slate-400">${active ? 'Activa' : 'Inactiva'}</td>
                <td class="py-3 px-6">
                    <div class="flex justify-center gap-2">
                        ${active ? `
                            <button onclick="window.openCategoryModal(${c.id})" class="p-2 text-indigo-400 hover:bg-slate-800 rounded-lg"><i data-lucide="pencil" class="w-4 h-4"></i></button>
                            <button onclick="window.deactivateCategoryFlow(${c.id})" class="p-2 text-rose-400 hover:bg-slate-800 rounded-lg"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                        ` : '<span class="text-xs text-slate-500">—</span>'}
                    </div>
                </td>
            `;
            tbody.appendChild(tr);

            const card = document.createElement('article');
            card.className = 'mobile-data-card';
            card.innerHTML = `
                <div class="flex min-w-0 items-start justify-between gap-3">
                    <h5 class="min-w-0 truncate text-sm font-semibold text-white">${utils.escapeHtml(c.nombre)}</h5>
                    <span class="shrink-0 text-[10px] font-bold px-2 py-1 rounded-full ${active ? 'bg-emerald-500/15 text-emerald-400' : 'bg-slate-500/20 text-slate-400'}">${active ? 'Activa' : 'Inactiva'}</span>
                </div>
                <p class="mt-3 text-xs leading-relaxed text-slate-400">${utils.escapeHtml(c.descripcion || 'Sin descripción')}</p>
                <div class="mt-4 grid grid-cols-2 gap-2">${actions}</div>
            `;
            cards.appendChild(card);
        });
        lucide.createIcons();
    },

    renderSubcategories(state, utils) {
        const tbody = document.getElementById('catalog-subcategories-tbody');
        const cards = document.getElementById('catalog-subcategories-cards');
        if (!tbody || !cards) return;
        tbody.innerHTML = '';
        cards.innerHTML = '';
        (state.subcategories || []).forEach((s) => {
            const active = s.activo !== false;
            const categoryName = utils.categoryName(s.category_id);
            const actions = active ? `
                <button onclick="window.openSubcategoryModal(${s.id})" class="inline-flex items-center justify-center gap-2 px-3 py-2 text-indigo-300 border border-indigo-500/20 bg-indigo-500/10 rounded-lg"><i data-lucide="pencil" class="w-4 h-4"></i><span class="text-xs font-semibold">Editar</span></button>
                <button onclick="window.deactivateSubcategoryFlow(${s.id})" class="inline-flex items-center justify-center gap-2 px-3 py-2 text-rose-300 border border-rose-500/20 bg-rose-500/10 rounded-lg"><i data-lucide="trash-2" class="w-4 h-4"></i><span class="text-xs font-semibold">Desactivar</span></button>
            ` : '<span class="col-span-2 py-2 text-center text-xs text-slate-500">Sin acciones disponibles</span>';
            const tr = document.createElement('tr');
            tr.className = 'border-b border-slate-800/30';
            tr.innerHTML = `
                <td class="py-3 px-6 text-white font-medium">${utils.escapeHtml(s.nombre)}</td>
                <td class="py-3 px-6 text-slate-400">${utils.escapeHtml(categoryName)}</td>
                <td class="py-3 px-6 text-slate-400">${active ? 'Activa' : 'Inactiva'}</td>
                <td class="py-3 px-6">
                    <div class="flex justify-center gap-2">
                        ${active ? `
                            <button onclick="window.openSubcategoryModal(${s.id})" class="p-2 text-indigo-400 hover:bg-slate-800 rounded-lg"><i data-lucide="pencil" class="w-4 h-4"></i></button>
                            <button onclick="window.deactivateSubcategoryFlow(${s.id})" class="p-2 text-rose-400 hover:bg-slate-800 rounded-lg"><i data-lucide="trash-2" class="w-4 h-4"></i></button>
                        ` : '<span class="text-xs text-slate-500">—</span>'}
                    </div>
                </td>
            `;
            tbody.appendChild(tr);

            const card = document.createElement('article');
            card.className = 'mobile-data-card';
            card.innerHTML = `
                <div class="flex min-w-0 items-start justify-between gap-3">
                    <div class="min-w-0">
                        <h5 class="truncate text-sm font-semibold text-white">${utils.escapeHtml(s.nombre)}</h5>
                        <p class="mt-1 truncate text-xs text-slate-400">${utils.escapeHtml(categoryName)}</p>
                    </div>
                    <span class="shrink-0 text-[10px] font-bold px-2 py-1 rounded-full ${active ? 'bg-emerald-500/15 text-emerald-400' : 'bg-slate-500/20 text-slate-400'}">${active ? 'Activa' : 'Inactiva'}</span>
                </div>
                <div class="mt-4 grid grid-cols-2 gap-2">${actions}</div>
            `;
            cards.appendChild(card);
        });
        lucide.createIcons();
    },
};
