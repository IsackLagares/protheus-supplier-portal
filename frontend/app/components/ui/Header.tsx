'use client';

import React from 'react';
import { useRouter } from 'next/navigation';
import { LogOut } from 'lucide-react'; 

interface HeaderProps {
  title: string;
  subtitle: string;
  userName?: string;
  userDetail?: string;
  onActionClick?: () => void;
  isAdmin?: boolean;
}

export const Header = ({ title, subtitle, userName, userDetail, onActionClick, isAdmin }: HeaderProps) => {
  const router = useRouter();
  
  const handleLogout = () => {
    // Aqui no futuro limparia cookies/localStorage do Supabase
    router.push('/login');
  };

  const initials = userName ? userName.substring(0, 2).toUpperCase() : '??';

  return (
    <header className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-10">
      <div className="flex items-center gap-4">
        <div className="w-10 h-10 bg-blue-600 rounded-lg flex items-center justify-center shadow-lg shadow-blue-900/20">
          <span className="text-white font-bold text-xl">P</span>
        </div>
        <div>
          <h1 className="text-xl font-bold text-white tracking-tight">{title}</h1>
          <p className="text-[10px] text-slate-500 uppercase tracking-widest font-semibold">{subtitle}</p>
        </div>
      </div>
      
      <div className="flex items-center gap-4">
        {userName && (
          <div className="flex items-center gap-3">
            {/* Badge do Utilizador */}
            <div className="flex items-center gap-3 bg-slate-800/50 border border-slate-700 p-1.5 pr-4 rounded-xl">
              <div className="w-8 h-8 bg-slate-700 rounded-lg flex items-center justify-center font-bold text-slate-300 text-xs">
                {initials}
              </div>
              <div>
                <p className="text-xs font-bold text-white leading-none">{userName}</p>
                <p className="text-[9px] text-slate-500 font-mono mt-1 tracking-tighter">{userDetail}</p>
              </div>
            </div>

            {/* Botão de Logout Discreto */}
            <button 
              onClick={handleLogout}
              className="p-2.5 bg-slate-800/50 border border-slate-700 rounded-xl text-slate-500 hover:text-rose-400 hover:border-rose-500/30 transition-all group"
              title="Sair do Portal"
            >
              <LogOut size={16} className="group-hover:scale-110 transition-transform" />
            </button>
          </div>
        )}

        {isAdmin && (
          <button 
            onClick={onActionClick}
            className="bg-blue-600 hover:bg-blue-500 text-white text-[10px] font-bold py-2.5 px-6 rounded-lg transition-all shadow-lg shadow-blue-900/20 uppercase tracking-wider"
          >
            + Novo Convite
          </button>
        )}
      </div>
    </header>
  );
};