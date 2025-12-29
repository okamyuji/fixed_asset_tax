import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
    LayoutDashboard,
    Building2,
    Package,
    Calculator,
    LogOut
} from 'lucide-react';
import { useAuthStore } from '../stores/authStore';

interface LayoutProps {
    children: React.ReactNode;
}

export const Layout = ({ children }: LayoutProps) => {
    const navigate = useNavigate();
    const location = useLocation();
    const clearAuth = useAuthStore((state) => state.clearAuth);

    const handleLogout = () => {
        clearAuth();
        navigate('/login');
    };

    const navigation = [
        { name: 'ダッシュボード', href: '/', icon: LayoutDashboard },
        { name: '資産管理', href: '/properties', icon: Building2 },
        { name: '固定資産', href: '/fixed-assets', icon: Package },
        { name: '税額計算', href: '/calculations', icon: Calculator },
    ];

    const isActive = (href: string) => {
        if (href === '/') {
            return location.pathname === '/';
        }
        return location.pathname.startsWith(href);
    };

    return (
        <div className="flex h-screen bg-slate-50">
            {/* サイドバー */}
            <div className="w-64 bg-white border-r border-slate-200 flex flex-col shadow-sm">
                {/* ロゴ */}
                <div className="h-16 flex items-center px-6 border-b border-slate-200">
                    <div className="flex items-center gap-2">
                        <div className="w-8 h-8 bg-gradient-to-br from-primary-500 to-accent-500 rounded-lg flex items-center justify-center">
                            <Calculator className="w-5 h-5 text-white" />
                        </div>
                        <h1 className="text-lg font-semibold text-slate-900">
                            固定資産税
                        </h1>
                    </div>
                </div>

                {/* ナビゲーション */}
                <nav className="flex-1 px-3 py-4 space-y-1">
                    {navigation.map((item) => {
                        const Icon = item.icon;
                        const active = isActive(item.href);
                        return (
                            <Link
                                key={item.name}
                                to={item.href}
                                className={`flex items-center gap-3 px-3 py-2.5 text-sm font-medium rounded-xl transition-all duration-200 ${
                                    active
                                        ? 'bg-primary-50 text-primary-700 shadow-sm'
                                        : 'text-slate-700 hover:bg-slate-50 hover:text-slate-900'
                                }`}
                            >
                                <Icon className={`w-5 h-5 ${active ? 'text-primary-600' : 'text-slate-500'}`} />
                                {item.name}
                            </Link>
                        );
                    })}
                </nav>

                {/* ログアウト */}
                <div className="p-3 border-t border-slate-200">
                    <button
                        onClick={handleLogout}
                        className="w-full flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium text-slate-700 bg-slate-50 hover:bg-slate-100 rounded-xl transition-all duration-200"
                    >
                        <LogOut className="w-4 h-4" />
                        ログアウト
                    </button>
                </div>
            </div>

            {/* メインコンテンツ */}
            <div className="flex-1 flex flex-col overflow-hidden">
                {/* ヘッダー */}
                <header className="h-16 bg-white border-b border-slate-200 flex items-center px-8 shadow-sm">
                    <h2 className="text-xl font-semibold text-slate-900">
                        {navigation.find((item) => isActive(item.href))?.name || 'ダッシュボード'}
                    </h2>
                </header>

                {/* コンテンツエリア */}
                <main className="flex-1 overflow-y-auto p-8 animate-fade-in">
                    {children}
                </main>
            </div>
        </div>
    );
};
