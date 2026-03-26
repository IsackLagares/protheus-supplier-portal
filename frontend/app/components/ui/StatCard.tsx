import React from 'react';

interface StatCardProps {
  title: string;
  value: string;
  status: string;
  statusColor: string;
}

export const StatCard = ({ title, value, status, statusColor }: StatCardProps) => {
  return (
    <div className="bg-[#1e293b] border border-slate-700/50 p-5 rounded-xl hover:border-blue-500/40 transition-all duration-200 shadow-lg shadow-black/20">
      <p className="text-slate-400 text-[10px] font-bold uppercase tracking-wider mb-1">
        {title}
      </p>
      <h3 className="text-white text-2xl font-bold tracking-tight">
        {value}
      </h3>
      <div className={`mt-3 inline-flex items-center px-2 py-0.5 rounded text-[10px] font-semibold border ${statusColor}`}>
        {status}
      </div>
    </div>
  );
};