import React from 'react';
import { Header } from '@/app/components/ui/Header';
import { StatCard } from '@/app/components/ui/StatCard';
import { TableContainer } from '@/app/components/ui/TableContainer';

export default function Dashboard() {
  // Dados simulados da tabela
  const notasFiscais = [
    { id: '#001847', em: '03/03/2026', ven: '02/04/2026', val: '18.900' },
    { id: '#001821', em: '18/02/2026', ven: '20/03/2026', val: '5.300' },
    { id: '#001798', em: '10/02/2026', ven: '12/03/2026', val: '24.000' },
    { id: '#001762', em: '25/01/2026', ven: '24/02/2026', val: '38.700' },
  ];

  return (
    <div className="min-h-screen bg-[#0f172a] text-slate-300 font-sans selection:bg-blue-500/30">
      
      {/* 1. Background com os gradientes sutis que você definiu */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-blue-600/5 blur-[100px] rounded-full" />
        <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-indigo-600/5 blur-[100px] rounded-full" />
      </div>

      <div className="relative max-w-7xl mx-auto px-6 py-8">
        
        {/* 2. Header Refatorado */}
        <Header 
            title="Portal do Fornecedor" 
            subtitle="Protheus Engine • v1.0" 
            userName="Tech Supplies Ltda"
            userDetail="12.345.678/0001-99"
          />  

        {/* 3. Título da Seção com a linha lateral */}
        <div className="mb-6 flex items-center gap-3">
          <h2 className="text-2xl font-bold text-white tracking-tight">Posição Financeira</h2>
          <div className="h-px flex-1 bg-slate-800" />
        </div>

        {/* 4. Grid de StatCards usando o componente reutilizável */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatCard 
            title="A Receber" 
            value="R$ 48.200" 
            status="3 pendentes" 
            statusColor="bg-orange-500/5 text-orange-400 border-orange-500/20" 
          />
          <StatCard 
            title="Pago (30d)" 
            value="R$ 112.450" 
            status="liquidado" 
            statusColor="bg-emerald-500/5 text-emerald-400 border-emerald-500/20" 
          />
          <StatCard 
            title="Vencido" 
            value="R$ 5.300" 
            status="1 título" 
            statusColor="bg-rose-500/5 text-rose-400 border-rose-500/20" 
          />
          <StatCard 
            title="NFs Aberto" 
            value="07" 
            status="SE2 Ativo" 
            statusColor="bg-blue-500/5 text-blue-400 border-blue-500/20" 
          />
        </div>

        {/* 5. Tabela usando o TableContainer refatorado */}
        <TableContainer 
          title="Notas Fiscais de Entrada"
          action={
            <button className="text-blue-400 hover:text-blue-300 text-[11px] font-bold transition-all px-3 py-1.5 rounded-md hover:bg-blue-500/10">
              VER HISTÓRICO COMPLETO
            </button>
          }
        >
          <table className="w-full text-left">
            <thead>
              <tr className="bg-slate-900/20 text-slate-500 text-[10px] uppercase font-bold tracking-widest border-b border-slate-700/50">
                <th className="px-6 py-4">Nº Documento</th>
                <th className="px-6 py-4 text-center">Emissão</th>
                <th className="px-6 py-4 text-center">Vencimento</th>
                <th className="px-6 py-4 text-right">Valor Total</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-700/30">
              {notasFiscais.map((row, i) => (
                <tr key={i} className="group hover:bg-slate-700/20 transition-colors">
                  <td className="px-6 py-4 text-white font-mono text-sm font-medium">{row.id}</td>
                  <td className="px-6 py-4 text-slate-400 text-center text-xs">{row.em}</td>
                  <td className="px-6 py-4 text-slate-400 text-center text-xs">{row.ven}</td>
                  <td className="px-6 py-4 text-right">
                    <span className="text-slate-100 font-bold text-sm">R$ {row.val}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
        
        {/* Footer */}
        <footer className="mt-8 text-center">
          <p className="text-[10px] text-slate-600 font-medium tracking-widest uppercase">
            Dados integrados via TOTVS Protheus ERP
          </p>
        </footer>
      </div>
    </div>
  );
}