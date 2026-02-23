import React from 'react';
import { LayoutGrid, Users, ClipboardList, Package, Settings, Bell, TrendingUp } from 'lucide-react';
import { Screen } from '../types';
import { cn } from '../lib/utils';

interface LayoutProps {
  children: React.ReactNode;
  currentScreen: Screen;
  onNavigate: (screen: Screen) => void;
  title?: string;
  showBack?: boolean;
  onBack?: () => void;
  rightElement?: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({
  children,
  currentScreen,
  onNavigate,
  title,
  showBack,
  onBack,
  rightElement
}) => {
  const navItems = [
    { id: 'dashboard', label: 'Home', icon: LayoutGrid },
    { id: 'customers', label: 'Clients', icon: Users },
    { id: 'dispatch', label: 'Jobs', icon: ClipboardList },
    { id: 'inventory', label: 'Stock', icon: Package },
    { id: 'insights', label: 'Insights', icon: TrendingUp },
  ];

  if (currentScreen === 'login') return <>{children}</>;

  return (
    <div className="flex flex-col h-screen bg-[#f5f7f8] text-slate-900 font-sans max-w-[430px] mx-auto shadow-2xl relative overflow-hidden">
      {/* Header */}
      <header className="sticky top-0 z-30 bg-white/80 backdrop-blur-md border-b border-slate-100 px-4 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          {showBack && (
            <button onClick={onBack} className="p-2 -ml-2 hover:bg-slate-100 rounded-full transition-colors">
              <span className="material-symbols-outlined text-slate-700">arrow_back_ios</span>
            </button>
          )}
          <h1 className="text-xl font-bold tracking-tight">{title || 'RO Manager'}</h1>
        </div>
        <div className="flex items-center gap-2">
          {rightElement || (
            <button 
              onClick={() => onNavigate('notifications')}
              className="relative flex size-10 items-center justify-center rounded-full bg-white border border-slate-200 shadow-sm text-slate-600"
            >
              <Bell size={20} />
              <span className="absolute top-2 right-2 size-2 bg-[#007fff] rounded-full border-2 border-white"></span>
            </button>
          )}
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-y-auto pb-24">
        {children}
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 w-full max-w-[430px] bg-white/90 backdrop-blur-lg border-t border-slate-100 pb-8 pt-2 px-6 flex justify-between items-center z-40">
        {navItems.map((item) => {
          const isActive = currentScreen === item.id || 
                          (item.id === 'dashboard' && currentScreen === 'notifications') ||
                          (item.id === 'customers' && currentScreen === 'customer-profile') ||
                          (item.id === 'inventory' && currentScreen === 'suppliers');
          
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id as Screen)}
              className={cn(
                "flex flex-col items-center gap-1 transition-colors",
                isActive ? "text-[#007fff]" : "text-slate-400"
              )}
            >
              <item.icon size={24} strokeWidth={isActive ? 2.5 : 2} />
              <span className="text-[10px] font-bold">{item.label}</span>
            </button>
          );
        })}
      </nav>
    </div>
  );
};
