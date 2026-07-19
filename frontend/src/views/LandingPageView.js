export const LandingPageView = {
    render() {
        return `
            <div class="min-h-screen min-h-dvh bg-[#0f172a] text-slate-100 flex flex-col relative w-full overflow-hidden">
                <div class="hidden sm:block absolute top-20 -left-48 w-96 h-96 rounded-full bg-violet-600/15 blur-3xl pointer-events-none"></div>
                <div class="hidden sm:block absolute top-40 -right-48 w-[30rem] h-[30rem] rounded-full bg-cyan-400/10 blur-3xl pointer-events-none"></div>

                <header class="px-3 sm:px-5 md:px-10 py-3 flex items-center justify-between gap-2 sm:gap-6 z-30 sticky top-0 border-b border-slate-800/70 bg-slate-950/85 backdrop-blur-xl">
                    <a href="#inicio" class="shrink-0" aria-label="LuCash, ir al inicio">
                        <img src="/logo.png" alt="LuCash" class="w-28 sm:w-36 md:w-44 h-9 sm:h-10 md:h-11 object-cover object-center">
                    </a>

                    <nav class="hidden lg:flex items-center gap-7 text-sm font-medium text-slate-400" aria-label="Navegación principal">
                        <a href="#inicio" class="hover:text-white transition-colors">Inicio</a>
                        <a href="#funcionalidades" class="hover:text-white transition-colors">Funcionalidades</a>
                        <a href="#como-funciona" class="hover:text-white transition-colors">Cómo funciona</a>
                        <a href="#seguridad" class="hover:text-white transition-colors">Seguridad</a>
                    </nav>

                    <div id="landing-auth-nav" class="flex shrink-0 items-center gap-1.5 sm:gap-2 md:gap-3"></div>
                </header>

                <main class="relative z-10">
                    <section id="inicio" class="max-w-7xl mx-auto px-4 sm:px-6 md:px-10 pt-10 sm:pt-16 md:pt-24 pb-12 sm:pb-20 grid grid-cols-1 lg:grid-cols-2 gap-8 sm:gap-14 lg:gap-10 items-center">
                        <div class="animate-fade-in">
                            <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-cyan-400/10 text-cyan-300 border border-cyan-300/20 text-xs font-semibold mb-7">
                                <span class="w-2 h-2 rounded-full bg-cyan-300 pulse-active"></span>
                                Tus finanzas, más simples y claras
                            </div>

                            <h1 class="text-3xl sm:text-5xl xl:text-6xl font-extrabold tracking-tight leading-[1.08] sm:leading-[1.05] text-white max-w-2xl">
                                Toma el control de tu
                                <span class="text-transparent bg-clip-text bg-gradient-to-r from-cyan-300 to-violet-400"> dinero</span>
                                sin complicarte.
                            </h1>

                            <p class="mt-6 text-base md:text-lg text-slate-400 max-w-xl leading-relaxed">
                                Organiza cuentas, registra movimientos, controla presupuestos y entiende en qué se va tu dinero desde un solo lugar.
                            </p>

                            <ul class="mt-8 space-y-4 text-sm text-slate-300">
                                <li class="flex items-center gap-3">
                                    <span class="shrink-0 w-9 h-9 rounded-xl bg-cyan-400/10 text-cyan-300 flex items-center justify-center"><i data-lucide="landmark" class="w-4 h-4"></i></span>
                                    Todas tus cuentas y saldos organizados
                                </li>
                                <li class="flex items-center gap-3">
                                    <span class="shrink-0 w-9 h-9 rounded-xl bg-violet-500/10 text-violet-300 flex items-center justify-center"><i data-lucide="chart-no-axes-combined" class="w-4 h-4"></i></span>
                                    Reportes claros para tomar mejores decisiones
                                </li>
                                <li class="flex items-center gap-3">
                                    <span class="shrink-0 w-9 h-9 rounded-xl bg-cyan-400/10 text-cyan-300 flex items-center justify-center"><i data-lucide="shield-check" class="w-4 h-4"></i></span>
                                    Información protegida y acceso seguro
                                </li>
                            </ul>

                            <div id="landing-hero-cta" class="mt-9 flex flex-col sm:flex-row gap-3"></div>

                            <div class="mt-10 grid grid-cols-3 gap-2 sm:gap-3 max-w-xl">
                                <div class="min-w-0 text-center text-[9px] sm:text-xs font-semibold text-slate-300">Todo en un solo lugar</div>
                                <div class="min-w-0 text-center text-[9px] sm:text-xs font-semibold text-slate-300">Información al instante</div>
                                <div class="min-w-0 text-center text-[9px] sm:text-xs font-semibold text-slate-300">Decide con claridad</div>
                            </div>
                        </div>

                        <div class="relative min-h-[350px] sm:min-h-[430px] md:min-h-[520px] flex items-center justify-center animate-fade-in" style="animation-delay: 120ms;">
                            <div class="absolute inset-8 rounded-[2.5rem] bg-gradient-to-br from-cyan-400/15 to-violet-500/20 blur-2xl"></div>

                            <div class="relative w-full max-w-[620px] rounded-3xl border border-slate-700/70 bg-slate-900/95 p-3 md:p-4 shadow-2xl shadow-black/40">
                                <div class="rounded-2xl overflow-hidden border border-slate-800 bg-slate-950">
                                    <div class="h-10 px-4 flex items-center justify-between border-b border-slate-800">
                                        <div class="flex gap-1.5"><span class="w-2.5 h-2.5 rounded-full bg-rose-400/70"></span><span class="w-2.5 h-2.5 rounded-full bg-amber-300/70"></span><span class="w-2.5 h-2.5 rounded-full bg-emerald-400/70"></span></div>
                                        <span class="text-[10px] text-slate-500">Panel LuCash</span>
                                    </div>
                                    <div class="p-3 sm:p-4 md:p-6">
                                        <div class="flex flex-col items-start gap-2 sm:flex-row sm:items-center sm:justify-between mb-5">
                                            <div><p class="text-[10px] text-slate-500 uppercase tracking-wider">Saldo neto</p><p class="text-xl md:text-2xl font-bold text-white mt-1">$ 8.420.000</p></div>
                                            <div class="px-2.5 py-1 rounded-full bg-emerald-400/10 text-emerald-300 text-[10px]">+12.4% este mes</div>
                                        </div>
                                        <div class="grid grid-cols-3 gap-2 md:gap-3 mb-5">
                                            <div class="min-w-0 rounded-xl bg-slate-900 border border-slate-800 p-2 sm:p-3"><span class="text-[8px] sm:text-[9px] text-slate-500">Ingresos</span><p class="text-[10px] sm:text-xs md:text-sm font-semibold text-cyan-300 mt-1">$ 4.8M</p></div>
                                            <div class="min-w-0 rounded-xl bg-slate-900 border border-slate-800 p-2 sm:p-3"><span class="text-[8px] sm:text-[9px] text-slate-500">Gastos</span><p class="text-[10px] sm:text-xs md:text-sm font-semibold text-violet-300 mt-1">$ 2.1M</p></div>
                                            <div class="min-w-0 rounded-xl bg-slate-900 border border-slate-800 p-2 sm:p-3"><span class="text-[8px] sm:text-[9px] text-slate-500">Presupuesto</span><p class="text-[9px] sm:text-xs md:text-sm font-semibold text-emerald-300 mt-1">68% gastado</p></div>
                                        </div>
                                        <div class="rounded-xl bg-slate-900 border border-slate-800 p-4">
                                            <div class="flex justify-between items-center mb-5"><span class="text-[10px] text-slate-400">Flujo mensual</span><span class="text-[9px] text-slate-600">Últimos 6 meses</span></div>
                                            <div class="h-28 flex items-end gap-2 md:gap-3">
                                                ${[42, 58, 48, 76, 64, 88, 54, 92, 70, 96, 78, 100].map((height, index) => `
                                                    <span class="flex-1 rounded-t-sm ${index % 2 ? 'bg-violet-500/70' : 'bg-cyan-400/70'}" style="height:${height}%"></span>
                                                `).join('')}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="landing-phone-mockup absolute bottom-0 left-2 md:-bottom-2 md:-left-5 w-36 sm:w-44 md:w-52 rounded-[2rem] border-[5px] sm:border-[6px] border-slate-800 bg-slate-950 p-3 shadow-2xl shadow-black/50">
                                <div class="w-16 h-1 rounded-full bg-slate-700 mx-auto mb-5"></div>
                                <p class="text-[9px] text-slate-500">Disponible</p>
                                <p class="text-lg font-bold text-white mt-1">$ 3.240.500</p>
                                <div class="mt-5 space-y-2">
                                    <div class="rounded-lg bg-slate-900 p-2 flex items-center gap-2"><span class="w-7 h-7 rounded-lg bg-cyan-400/10 text-cyan-300 flex items-center justify-center"><i data-lucide="shopping-cart" class="w-3 h-3"></i></span><div class="flex-1"><p class="text-[8px] text-white">Mercado</p><p class="text-[7px] text-slate-600">Hoy</p></div><span class="text-[8px] text-rose-300">-$84.000</span></div>
                                    <div class="rounded-lg bg-slate-900 p-2 flex items-center gap-2"><span class="w-7 h-7 rounded-lg bg-violet-500/10 text-violet-300 flex items-center justify-center"><i data-lucide="wallet" class="w-3 h-3"></i></span><div class="flex-1"><p class="text-[8px] text-white">Ingreso</p><p class="text-[7px] text-slate-600">Ayer</p></div><span class="text-[8px] text-emerald-300">+$320.000</span></div>
                                </div>
                            </div>
                        </div>
                    </section>

                    <section id="funcionalidades" class="max-w-7xl mx-auto px-4 sm:px-6 md:px-10 py-14 sm:py-20 md:py-28">
                        <div class="text-center max-w-3xl mx-auto mb-14">
                            <span class="text-xs font-semibold uppercase tracking-[0.25em] text-cyan-300">Todo en un solo lugar</span>
                            <h2 class="mt-4 text-3xl md:text-5xl font-extrabold text-white">¿Qué puedes hacer con LuCash?</h2>
                            <p class="mt-5 text-slate-400">Herramientas simples para entender tu dinero y mantener tus finanzas personales bajo control.</p>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                            ${[
                                ['landmark', 'Controla todas tus cuentas', 'Consulta saldos y organiza cuentas bancarias, digitales y efectivo.', 'accounts', 'cyan'],
                                ['receipt-text', 'Registra cada movimiento', 'Clasifica ingresos y gastos para saber exactamente a dónde va tu dinero.', 'transactions', 'violet'],
                                ['pie-chart', 'Planifica presupuestos', 'Define límites mensuales y revisa cuánto has consumido por categoría.', 'budgets', 'cyan'],
                                ['arrow-left-right', 'Transfiere con claridad', 'Mueve saldo entre tus propias cuentas y conserva el historial completo.', 'transfers', 'violet'],
                                ['chart-column-big', 'Decide con datos reales', 'Analiza tendencias, categorías, medios de pago y comparaciones de periodo.', 'dashboard', 'cyan'],
                                ['shield-check', 'Tu información siempre protegida', 'Accede con confianza y mantén tus datos financieros privados y bajo tu control.', 'settings', 'violet'],
                            ].map(([icon, title, copy, route, tone]) => `
                                <button type="button" onclick="window.landingFeatureClick('${route}')" class="group text-left p-5 sm:p-6 md:p-7 rounded-2xl bg-slate-900/60 border border-slate-800 hover:border-${tone}-400/40 hover:bg-slate-900 transition-all">
                                    <span class="w-12 h-12 rounded-xl bg-${tone}-400/10 text-${tone}-300 flex items-center justify-center mb-6 group-hover:scale-105 transition-transform"><i data-lucide="${icon}" class="w-5 h-5"></i></span>
                                    <h3 class="text-lg font-bold text-white">${title}</h3>
                                    <p class="mt-3 text-sm text-slate-400 leading-relaxed">${copy}</p>
                                    <span class="mt-6 inline-flex items-center gap-1 text-xs font-semibold text-${tone}-300">Conocer más <i data-lucide="arrow-up-right" class="w-3 h-3"></i></span>
                                </button>
                            `).join('')}
                        </div>
                    </section>

                    <section id="como-funciona" class="border-y border-slate-800/70 bg-slate-950/50">
                        <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-10 py-14 sm:py-20 grid grid-cols-1 lg:grid-cols-2 gap-10 sm:gap-14 items-center">
                            <div>
                                <span class="text-xs font-semibold uppercase tracking-[0.25em] text-violet-300">Empieza sin complicaciones</span>
                                <h2 class="mt-4 text-3xl md:text-4xl font-extrabold text-white">De tus movimientos a decisiones más inteligentes.</h2>
                                <p class="mt-5 text-slate-400 leading-relaxed">LuCash convierte el registro diario de tus finanzas en una visión clara de tu situación económica.</p>
                            </div>
                            <ol class="space-y-5">
                                <li class="flex gap-3 sm:gap-4 p-4 sm:p-5 rounded-2xl bg-slate-900/70 border border-slate-800"><span class="shrink-0 w-9 h-9 rounded-full bg-cyan-400 text-slate-950 font-bold flex items-center justify-center">1</span><div><h3 class="font-semibold text-white">Crea y organiza tus cuentas</h3><p class="mt-1 text-sm text-slate-500">Agrega tus cuentas con moneda y saldo inicial.</p></div></li>
                                <li class="flex gap-3 sm:gap-4 p-4 sm:p-5 rounded-2xl bg-slate-900/70 border border-slate-800"><span class="shrink-0 w-9 h-9 rounded-full bg-violet-500 text-white font-bold flex items-center justify-center">2</span><div><h3 class="font-semibold text-white">Registra lo que entra y sale</h3><p class="mt-1 text-sm text-slate-500">Clasifica cada movimiento y asócialo a una cuenta.</p></div></li>
                                <li class="flex gap-3 sm:gap-4 p-4 sm:p-5 rounded-2xl bg-slate-900/70 border border-slate-800"><span class="shrink-0 w-9 h-9 rounded-full bg-cyan-400 text-slate-950 font-bold flex items-center justify-center">3</span><div><h3 class="font-semibold text-white">Revisa y ajusta</h3><p class="mt-1 text-sm text-slate-500">Usa reportes y presupuestos para mejorar tus decisiones.</p></div></li>
                            </ol>
                        </div>
                    </section>

                    <section id="seguridad" class="max-w-5xl mx-auto px-4 sm:px-6 py-14 sm:py-20 md:py-28 text-center">
                        <div class="rounded-3xl border border-violet-400/20 bg-gradient-to-br from-violet-500/10 to-cyan-400/10 px-4 sm:px-6 py-10 sm:py-12 md:px-16 md:py-16">
                            <span class="mx-auto w-14 h-14 rounded-2xl bg-violet-500/15 text-violet-300 flex items-center justify-center"><i data-lucide="shield-check" class="w-7 h-7"></i></span>
                            <h2 class="mt-6 text-3xl md:text-4xl font-extrabold text-white">Tu información financiera merece protección.</h2>
                            <p class="mt-4 text-slate-400 max-w-2xl mx-auto">Tus datos permanecen privados y vinculados únicamente a tu cuenta, para que administres tu dinero con tranquilidad.</p>
                            <div id="landing-bottom-cta" class="mt-8 flex justify-center"></div>
                        </div>
                    </section>
                </main>

                <footer class="relative z-10 border-t border-slate-800/70 bg-slate-950/70">
                    <div class="max-w-7xl mx-auto px-6 md:px-10 py-8 flex flex-col md:flex-row items-center justify-between gap-5">
                        <img src="/logo.png" alt="LuCash" class="w-32 h-9 object-cover object-center">
                        <p class="text-xs text-slate-500">&copy; ${new Date().getFullYear()} LuCash. Control financiero personal.</p>
                    </div>
                </footer>
            </div>
        `;
    },

    init(state, utils) {
        const isAuth = !!(state && state.user);
        const navContainer = document.getElementById('landing-auth-nav');
        const ctaContainer = document.getElementById('landing-hero-cta');
        const bottomCta = document.getElementById('landing-bottom-cta');

        if (isAuth) {
            if (navContainer) {
                navContainer.innerHTML = `
                    <button type="button" onclick="window.switchTab('dashboard')" class="px-4 py-2 rounded-xl bg-cyan-400 text-slate-950 text-sm font-bold hover:bg-cyan-300 transition-colors">Ir al panel</button>
                `;
            }
            if (ctaContainer) {
                ctaContainer.innerHTML = `
                    <button type="button" onclick="window.switchTab('dashboard')" class="w-full sm:w-auto px-6 py-3 rounded-xl bg-cyan-400 text-slate-950 text-sm font-bold hover:bg-cyan-300 transition-colors">Ir al panel de control</button>
                `;
            }
            if (bottomCta) {
                bottomCta.innerHTML = `<button type="button" onclick="window.switchTab('dashboard')" class="px-6 py-3 rounded-xl bg-violet-500 text-white text-sm font-bold hover:bg-violet-400 transition-colors">Abrir mi panel</button>`;
            }
        } else {
            if (navContainer) {
                navContainer.innerHTML = `
                    <button type="button" onclick="window.showAuthScreen('login')" class="inline-flex px-2.5 sm:px-4 py-2 rounded-xl border border-slate-700 text-slate-200 text-xs sm:text-sm font-semibold hover:bg-slate-800 transition-colors"><span class="sm:hidden">Entrar</span><span class="hidden sm:inline">Iniciar sesión</span></button>
                    <button type="button" onclick="window.showAuthScreen('register')" class="px-2.5 sm:px-4 py-2 rounded-xl bg-cyan-400 text-slate-950 text-xs sm:text-sm font-bold hover:bg-cyan-300 transition-colors"><span class="sm:hidden">Registro</span><span class="hidden sm:inline">Registrarse</span></button>
                `;
            }
            if (ctaContainer) {
                ctaContainer.innerHTML = `
                    <button type="button" onclick="window.showAuthScreen('register')" class="w-full sm:w-auto px-6 py-3 rounded-xl bg-cyan-400 text-slate-950 text-sm font-bold hover:bg-cyan-300 transition-colors shadow-lg shadow-cyan-950/30">Crear cuenta gratis</button>
                    <button type="button" onclick="window.showAuthScreen('login')" class="w-full sm:w-auto px-6 py-3 rounded-xl border border-slate-700 text-white text-sm font-semibold hover:bg-slate-800 transition-colors">Ya tengo cuenta</button>
                `;
            }
            if (bottomCta) {
                bottomCta.innerHTML = `<button type="button" onclick="window.showAuthScreen('register')" class="px-6 py-3 rounded-xl bg-violet-500 text-white text-sm font-bold hover:bg-violet-400 transition-colors">Crear mi cuenta</button>`;
            }
        }

        window.landingFeatureClick = (tab) => {
            if (isAuth) {
                window.switchTab(tab);
            } else {
                window.showAuthScreen('login');
            }
        };
    }
};
