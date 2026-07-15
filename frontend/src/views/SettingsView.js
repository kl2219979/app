export const SettingsView = {
    render() {
        return `
            <div class="space-y-8 animate-fade-in max-w-2xl">
                <section class="glass-card p-6 rounded-2xl space-y-4">
                    <h4 class="text-md font-semibold text-white">Perfil</h4>
                    <form id="profile-form" onsubmit="window.saveProfile(event)" class="space-y-3">
                        <div class="grid grid-cols-2 gap-3">
                            <div class="space-y-1.5">
                                <label class="text-xs font-semibold text-slate-400">Nombres</label>
                                <input type="text" id="profile-nombres" required class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                            </div>
                            <div class="space-y-1.5">
                                <label class="text-xs font-semibold text-slate-400">Apellidos</label>
                                <input type="text" id="profile-apellidos" required class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                            </div>
                        </div>
                        <div class="grid grid-cols-2 gap-3">
                            <div class="space-y-1.5">
                                <label class="text-xs font-semibold text-slate-400">Nacimiento</label>
                                <input type="date" id="profile-fecha" required class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                            </div>
                            <div class="space-y-1.5">
                                <label class="text-xs font-semibold text-slate-400">Género</label>
                                <input type="text" id="profile-genero" required class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                            </div>
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Correo</label>
                            <input type="email" id="profile-correo" required class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Usuario</label>
                            <input type="text" id="profile-usuario" required minlength="3" class="glass-input w-full px-3 py-2 rounded-xl text-sm">
                        </div>
                        <div class="space-y-1.5">
                            <label class="text-xs font-semibold text-slate-400">Nueva contraseña (opcional)</label>
                            <input type="password" id="profile-contrasena" minlength="8" class="glass-input w-full px-3 py-2 rounded-xl text-sm" placeholder="Dejar vacío para no cambiar">
                        </div>
                        <p id="profile-meta" class="text-[11px] text-slate-500"></p>
                        <button type="submit" class="px-4 py-2 bg-gradient-to-r from-indigo-500 to-purple-600 text-white rounded-xl text-sm font-semibold">Guardar perfil</button>
                    </form>
                </section>

                <section class="glass-card p-6 rounded-2xl space-y-4">
                    <h4 class="text-md font-semibold text-white">Autenticación MFA (TOTP)</h4>
                    <p id="mfa-status" class="text-xs text-slate-400"></p>
                    <div id="mfa-setup-box" class="hidden space-y-3">
                        <p class="text-xs text-slate-400">Escanea o copia el secreto en tu app Authenticator, luego confirma con un código.</p>
                        <p class="text-xs break-all"><span class="text-slate-500">Secret:</span> <code id="mfa-secret" class="text-indigo-300"></code></p>
                        <p class="text-xs break-all"><span class="text-slate-500">URI:</span> <code id="mfa-uri" class="text-slate-300"></code></p>
                        <div class="flex gap-2">
                            <input type="text" id="mfa-confirm-code" maxlength="8" placeholder="Código 6 dígitos" class="glass-input flex-1 px-3 py-2 rounded-xl text-sm">
                            <button type="button" onclick="window.confirmMfaSetup()" class="px-4 py-2 bg-emerald-600/80 hover:bg-emerald-600 text-white rounded-xl text-sm font-semibold">Confirmar</button>
                        </div>
                    </div>
                    <button type="button" id="btn-mfa-setup" onclick="window.startMfaSetup()" class="px-4 py-2 border border-indigo-500/30 text-indigo-400 rounded-xl text-sm font-semibold">
                        Configurar MFA
                    </button>
                </section>

                <section class="glass-card p-6 rounded-2xl space-y-3 border border-rose-500/20">
                    <h4 class="text-md font-semibold text-rose-300">Zona peligrosa</h4>
                    <p class="text-xs text-slate-400">Desactiva tu cuenta de acceso. Los datos financieros se conservan.</p>
                    <button type="button" onclick="window.deactivateOwnAccount()" class="px-4 py-2 border border-rose-500/40 text-rose-400 hover:bg-rose-500/10 rounded-xl text-sm font-semibold">
                        Desactivar mi cuenta
                    </button>
                </section>
            </div>
        `;
    },

    init(state) {
        const u = state.user;
        if (!u) return;
        document.getElementById('profile-nombres').value = u.nombres || '';
        document.getElementById('profile-apellidos').value = u.apellidos || '';
        document.getElementById('profile-fecha').value = String(u.fecha_nacimiento || '').slice(0, 10);
        document.getElementById('profile-genero').value = u.genero || '';
        document.getElementById('profile-correo').value = u.correo || '';
        document.getElementById('profile-usuario').value = u.usuario || '';
        const meta = document.getElementById('profile-meta');
        if (meta) meta.textContent = `Rol: ${u.rol} · ID: ${u.id}`;
        const status = document.getElementById('mfa-status');
        if (status) {
            status.textContent = u.mfa_enabled
                ? 'MFA activo.'
                : 'MFA desactivado. Obligatorio para operaciones de administrador.';
        }
        const btn = document.getElementById('btn-mfa-setup');
        if (btn && u.mfa_enabled) {
            btn.disabled = true;
            btn.classList.add('opacity-50');
            btn.textContent = 'MFA ya configurado';
        }
    },
};
