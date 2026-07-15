export const CatalogView = {
    render() {
        return `
            <div class="space-y-8 animate-fade-in">
                <div class="glass-card p-4 rounded-xl border border-amber-500/20 bg-amber-500/5 text-amber-200 text-xs">
                    Solo administradores con MFA activo pueden modificar el catálogo.
                </div>

                <section class="space-y-4">
                    <div class="flex items-center justify-between">
                        <h4 class="text-md font-semibold text-white">Categorías</h4>
                        <button onclick="window.openCategoryModal()" class="text-xs font-bold text-indigo-400 hover:text-indigo-300">+ Nueva categoría</button>
                    </div>
                    <div class="glass-card rounded-2xl overflow-hidden">
                        <table class="w-full text-left text-sm">
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
                    </div>
                </section>

                <section class="space-y-4">
                    <div class="flex items-center justify-between">
                        <h4 class="text-md font-semibold text-white">Subcategorías</h4>
                        <button onclick="window.openSubcategoryModal()" class="text-xs font-bold text-indigo-400 hover:text-indigo-300">+ Nueva subcategoría</button>
                    </div>
                    <div class="glass-card rounded-2xl overflow-hidden">
                        <table class="w-full text-left text-sm">
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
        if (!tbody) return;
        tbody.innerHTML = '';
        (state.categories || []).forEach((c) => {
            const active = c.activo !== false;
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
        });
        lucide.createIcons();
    },

    renderSubcategories(state, utils) {
        const tbody = document.getElementById('catalog-subcategories-tbody');
        if (!tbody) return;
        tbody.innerHTML = '';
        (state.subcategories || []).forEach((s) => {
            const active = s.activo !== false;
            const tr = document.createElement('tr');
            tr.className = 'border-b border-slate-800/30';
            tr.innerHTML = `
                <td class="py-3 px-6 text-white font-medium">${utils.escapeHtml(s.nombre)}</td>
                <td class="py-3 px-6 text-slate-400">${utils.escapeHtml(utils.categoryName(s.category_id))}</td>
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
        });
        lucide.createIcons();
    },
};
