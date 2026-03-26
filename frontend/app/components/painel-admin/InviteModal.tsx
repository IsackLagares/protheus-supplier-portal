'use client';

import React, { useState } from "react";
import { maskCNPJ } from "@/app/utils/masks";
import { Check, Send, Loader2 } from "lucide-react"; // Ícones para o feedback

interface InviteModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const InviteModal = ({ isOpen, onClose }: InviteModalProps) => {
  const [cnpjConvite, setCnpjConvite] = useState("");
  const [status, setStatus] = useState<'idle' | 'sending' | 'success'>('idle');

  const handleCnpjChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setCnpjConvite(maskCNPJ(e.target.value));
  };

  // Lógica de envio com feedback visual
  const handleSendInvite = async () => {
    if (!cnpjConvite) return;

    setStatus('sending');

    setTimeout(() => {
      setStatus('success');

      setTimeout(() => {
        onClose();
        setStatus('idle');
        setCnpjConvite("");
      }, 2000);
    }, 1500);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop (Fundo escurecido) */}
      <div 
        className="absolute inset-0 bg-black/60 backdrop-blur-sm transition-opacity"
        onClick={status === 'idle' ? onClose : undefined} // Impede fechar enquanto envia
      />

      {/* Conteúdo do Modal */}
      <div className="relative w-full max-w-md bg-[#1e293b] border border-slate-700 rounded-2xl shadow-2xl p-8 animate-in fade-in zoom-in duration-200">
        <div className="mb-6 text-center md:text-left">
          <h2 className="text-xl font-bold text-white tracking-tight">Convidar Fornecedor</h2>
          <p className="text-xs text-slate-500 mt-1">O fornecedor receberá um e-mail com as instruções.</p>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-widest mb-1.5 ml-1">CNPJ do Fornecedor</label>
            <input 
              type="text" 
              value={cnpjConvite}
              onChange={handleCnpjChange}
              disabled={status !== 'idle'}
              placeholder="00.000.000/0000-00"
              maxLength={18} 
              className="w-full bg-[#0f172a] border border-slate-700 rounded-lg py-2.5 px-4 text-white text-sm focus:border-blue-500/50 focus:ring-1 focus:ring-blue-500/50 outline-none transition-all placeholder:text-slate-700 font-mono disabled:opacity-50"
            />  
          </div>

          <div>
            <label className="block text-[10px] font-bold text-slate-500 uppercase tracking-widest mb-1.5 ml-1">E-mail de Login</label>
            <input 
              type="email" 
              disabled={status !== 'idle'}
              placeholder="contato@fornecedor.com"
              className="w-full bg-[#0f172a] border border-slate-700 rounded-lg py-2.5 px-4 text-white text-sm focus:border-blue-500/50 focus:ring-1 focus:ring-blue-500/50 outline-none transition-all placeholder:text-slate-700 disabled:opacity-50"
            />
          </div>
        </div>

        <div className="mt-8 flex gap-3">
          {status === 'idle' && (
            <button 
              onClick={onClose}
              className="flex-1 px-4 py-2.5 rounded-lg border border-slate-700 text-slate-400 text-xs font-bold hover:bg-slate-800 transition-all uppercase tracking-wider"
            >
              Cancelar
            </button>
          )}
          
          <button 
            onClick={handleSendInvite}
            disabled={status !== 'idle'}
            className={`
              flex-1 px-4 py-2.5 rounded-lg text-xs font-bold transition-all shadow-lg uppercase tracking-wider flex items-center justify-center gap-2
              ${status === 'idle' ? 'bg-blue-600 hover:bg-blue-500 text-white shadow-blue-900/20' : ''}
              ${status === 'sending' ? 'bg-slate-700 text-slate-400 cursor-wait' : ''}
              ${status === 'success' ? 'bg-emerald-500 text-white shadow-emerald-900/20 w-full' : ''}
            `}
          >
            {status === 'idle' && (
              <>
                <Send size={14} />
                Enviar Convite
              </>
            )}

            {status === 'sending' && (
              <>
                <Loader2 size={14} className="animate-spin" />
                Processando...
              </>
            )}

            {status === 'success' && (
              <>
                <Check size={16} />
                Sucesso!
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};