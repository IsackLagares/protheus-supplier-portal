'use client';

import React, { useState } from 'react';
import { Header } from '@/app/components/ui/Header';
import { StatCard } from '@/app/components/ui/StatCard';
import { TableContainer } from '@/app/components/ui/TableContainer';
import { InviteModal } from '@/app/components/painel-admin/InviteModal';

export default function AdminPanel() {
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Dados mockados para a tabela (isso virá do Postgres depois)
  const fornecedores = [
    { nome: 'Tech Supplies Ltda', cnpj: '12.345.678/0001-99', email: 'contato@tech.com', status: 'Ativo', cor: 'text-emerald-400' },
    { nome: 'Global Logística SA', cnpj: '98.765.432/0001-10', email: 'admin@global.com', status: 'Pendente', cor: 'text-orange-400' },
  ];

  return (
    <div className="min-h-screen bg-[#0f172a] text-slate-300 font-sans selection:bg-blue-500/30">
      {/* Background Decorativo */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-blue-600/5 blur-[100px] rounded-full" />
      </div>

      <div className="relative max-w-7xl mx-auto px-6 py-8">
        <Header 
          title="Painel Administrativo" 
          subtitle="Controle de Acessos • Interno" 
          isAdmin 
          onActionClick={() => setIsModalOpen(true)}
        />

        {/* KPIs de Gestão */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatCard title="Total Cadastrados" value="124" status="Base Postgres" statusColor="bg-blue-500/5 text-blue-400 border-blue-500/20" />
          <StatCard title="Acessos Ativos" value="89" status="logados 24h" statusColor="bg-emerald-500/5 text-emerald-400 border-emerald-500/20" />
          <StatCard title="Pendentes" value="32" status="aguardando senha" statusColor="bg-orange-500/5 text-orange-400 border-orange-500/20" />
          <StatCard title="Bloqueados" value="03" status="acesso revogado" statusColor="bg-rose-500/5 text-rose-400 border-rose-500/20" />
        </div>

        {/* Tabela de Fornecedores */}
        <TableContainer title="Listagem de Fornecedores Habilitados">
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-900/20 text-slate-500 text-[10px] uppercase font-bold tracking-widest border-b border-slate-700/50">
                <th className="px-6 py-4">Razão Social / CNPJ</th>
                <th className="px-6 py-4 text-center">E-mail de Login</th>
                <th className="px-6 py-4 text-center">Status</th>
                <th className="px-6 py-4 text-right">Ações</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/30">
              {fornecedores.map((fornecedor, i) => (
                <tr key={i} className="group hover:bg-slate-700/20 transition-colors">
                  <td className="px-6 py-4">
                    <p className="text-white text-sm font-medium">{fornecedor.nome}</p>
                    <p className="text-[10px] text-slate-500 font-mono">{fornecedor.cnpj}</p>
                  </td>
                  <td className="px-6 py-4 text-slate-400 text-center text-xs">{fornecedor.email}</td>
                  <td className="px-6 py-4 text-center">
                    <span className={`text-[10px] font-bold uppercase ${fornecedor.cor}`}>{fornecedor.status}</span>
                  </td>
                  <td className="px-6 py-4 text-right">
                    <button className="text-blue-400 hover:text-blue-300 text-[10px] font-bold tracking-tighter mr-4">EDITAR</button>
                    <button className="text-rose-500 hover:text-rose-400 text-[10px] font-bold tracking-tighter">BLOQUEAR</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
      </div>

      {/* Modal de Convite Controlado pelo Estado */}
      <InviteModal 
        isOpen={isModalOpen} 
        onClose={() => setIsModalOpen(false)} 
      />
    </div>
  );
}