export const LandingPageView = {
    render() {
        return `
            <div class="min-h-screen bg-[#0f172a] text-slate-100 flex flex-col relative w-full">
                <!-- Header / Nav -->
                <header class="glass-panel px-4 md:px-8 py-4 flex items-center justify-between z-10 sticky top-0 border-b border-slate-800/50">
                    <div class="flex items-center gap-3">
                        <div class="p-2 bg-gradient-to-tr from-indigo-500 to-purple-600 rounded-lg shadow-lg shadow-indigo-500/20">
                            <i data-lucide="wallet-cards" class="w-5 h-5 text-white"></i>
                        </div>
                        <h1 class="text-lg md:text-xl font-bold text-white tracking-tight">FinanzasFlow</h1>
                    </div>
                    <div id="landing-auth-nav" class="flex items-center gap-2 md:gap-3">
                        <!-- Dynamic buttons injected via JS based on auth state -->
                    </div>
                </header>

                <!-- Hero Section -->
                <section class="flex-1 flex flex-col items-center justify-center p-6 md:p-8 text-center mt-8 md:mt-16 relative z-10">
                    <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 text-xs md:text-sm font-semibold mb-8 animate-fade-in shadow-[0_0_15px_rgba(99,102,241,0.2)]">
                        <span class="w-2 h-2 rounded-full bg-indigo-500 pulse-active"></span>
                        Gestión Financiera Inteligente
                    </div>
                    
                    <h2 class="text-4xl md:text-5xl lg:text-7xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-white via-indigo-200 to-indigo-400 mb-6 max-w-4xl leading-[1.1] animate-fade-in" style="animation-delay: 100ms;">
                        El control total de tus finanzas en un solo lugar.
                    </h2>
                    
                    <p class="text-base md:text-lg lg:text-xl text-slate-400 max-w-2xl mb-10 animate-fade-in leading-relaxed" style="animation-delay: 200ms;">
                        Registra transacciones, establece presupuestos mensuales y mantén tus cuentas equilibradas con nuestra plataforma profesional.
                    </p>
                    
                    <div id="landing-hero-cta" class="flex flex-col sm:flex-row w-full sm:w-auto gap-4 animate-fade-in" style="animation-delay: 300ms;">
                        <!-- CTA buttons -->
                    </div>
                </section>

                <!-- Features Section -->
                <section class="p-6 md:p-8 lg:p-16 max-w-7xl mx-auto w-full grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-8 relative z-10 mb-12">
                    <!-- Accounts -->
                    <div onclick="window.landingFeatureClick('accounts')" class="glass-card p-6 md:p-8 rounded-2xl cursor-pointer group">
                        <div class="w-12 h-12 rounded-xl bg-blue-500/10 text-blue-400 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                            <i data-lucide="landmark" class="w-6 h-6"></i>
                        </div>
                        <h3 class="text-xl font-bold text-white mb-3">Cuentas Claras</h3>
                        <p class="text-sm text-slate-400 leading-relaxed">Gestiona múltiples cuentas bancarias, efectivo y billeteras digitales. Conoce tu balance neto e ingresos al instante.</p>
                    </div>
                    
                    <!-- Budgets -->
                    <div onclick="window.landingFeatureClick('budgets')" class="glass-card p-6 md:p-8 rounded-2xl cursor-pointer group">
                        <div class="w-12 h-12 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                            <i data-lucide="pie-chart" class="w-6 h-6"></i>
                        </div>
                        <h3 class="text-xl font-bold text-white mb-3">Presupuestos</h3>
                        <p class="text-sm text-slate-400 leading-relaxed">Establece límites mensuales por categoría y visualiza de forma gráfica tu progreso para optimizar el ahorro.</p>
                    </div>
                    
                    <!-- Transactions -->
                    <div onclick="window.landingFeatureClick('transactions')" class="glass-card p-6 md:p-8 rounded-2xl cursor-pointer group">
                        <div class="w-12 h-12 rounded-xl bg-purple-500/10 text-purple-400 flex items-center justify-center mb-6 group-hover:scale-110 transition-transform duration-300">
                            <i data-lucide="receipt" class="w-6 h-6"></i>
                        </div>
                        <h3 class="text-xl font-bold text-white mb-3">Transacciones</h3>
                        <p class="text-sm text-slate-400 leading-relaxed">Registra ingresos y gastos con precisión. Exporta tus datos y mantén organizadas todas tus contrapartes.</p>
                    </div>
                </section>

                <!-- Footer -->
                <footer class="mt-auto border-t border-slate-800/50 py-8 text-center text-xs md:text-sm text-slate-500 z-10 relative bg-slate-900/50">
                    <p>&copy; ${new Date().getFullYear()} FinanzasFlow. Todos los derechos reservados.</p>
                </footer>
            </div>
        `;
    },

    init(state, utils) {
        const isAuth = !!(state && state.user);
        const navContainer = document.getElementById('landing-auth-nav');
        const ctaContainer = document.getElementById('landing-hero-cta');

        if (isAuth) {
            
            if (ctaContainer) {
                ctaContainer.innerHTML = `
                    <button onclick="window.switchTab('dashboard')" class="w-full sm:w-auto px-8 py-3.5 bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-400 hover:to-purple-500 text-white rounded-xl text-base font-bold transition-all shadow-[0_0_20px_rgba(99,102,241,0.3)] hover:shadow-[0_0_30px_rgba(99,102,241,0.5)] transform hover:-translate-y-1">Ir al Panel de Control</button>
                `;
            }
        } else {
            
            if (ctaContainer) {
                ctaContainer.innerHTML = `
                    <button onclick="window.showAuthScreen('register')" class="w-full sm:w-auto px-8 py-3.5 bg-gradient-to-r from-indigo-500 to-purple-600 hover:from-indigo-400 hover:to-purple-500 text-white rounded-xl text-base font-bold transition-all shadow-[0_0_20px_rgba(99,102,241,0.3)] hover:shadow-[0_0_30px_rgba(99,102,241,0.5)] transform hover:-translate-y-1">Comenzar Gratis</button>
                    <button onclick="window.showAuthScreen('login')" class="w-full sm:w-auto px-8 py-3.5 bg-slate-800/80 hover:bg-slate-700 text-white rounded-xl text-base font-bold transition-colors border border-slate-700 backdrop-blur-sm">Ya tengo cuenta</button>
                `;
            }
        }

        // Global handler for feature cards
        window.landingFeatureClick = (tab) => {
            if (isAuth) {
                window.switchTab(tab);
            } else {
                window.showAuthScreen('login');
            }
        };
    }
};
