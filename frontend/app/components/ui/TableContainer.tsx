interface TableContainerProps {
  title: string;
  children: React.ReactNode;
  action?: React.ReactNode; // Para o botão "Ver Histórico" ou "Novo"
}

export const TableContainer = ({ title, children, action }: TableContainerProps) => (
  <div className="bg-[#1e293b] border border-slate-700/50 rounded-xl overflow-hidden shadow-xl shadow-black/20">
    <div className="px-6 py-4 border-b border-slate-700 flex justify-between items-center bg-slate-800/30">
      <h3 className="text-sm font-bold text-white">{title}</h3>
      {action}
    </div>
    <div className="overflow-x-auto">
      {children}
    </div>
  </div>
);