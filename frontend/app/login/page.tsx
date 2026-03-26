'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import { maskCNPJ } from '../utils/masks';

const FormInput = ({ id, label, type, placeholder, value, onChange }: any) => (
  <div className="space-y-1.5">
    <label htmlFor={id} className="text-slate-400 text-[10px] font-bold uppercase tracking-wider">
      {label}
    </label>
    <input
      type={type}
      id={id}
      required
      name={id}
      value={value}       
      onChange={onChange}   
      placeholder={placeholder}
      className="w-full bg-[#0f172a] border border-slate-700/50 p-4 rounded-xl text-white text-sm placeholder:text-slate-700 focus:border-blue-500/60 focus:ring-1 focus:ring-blue-500/30 transition-all duration-200 outline-none font-sans"
    />
  </div>
);

export default function Login() {
  const router = useRouter();
  const [isAuthenticating, setIsAuthenticating] = useState(false);
  
  // Estados para os campos do formulário
  const [cnpj, setCnpj] = useState("");
  const [password, setPassword] = useState("");

  const handleCnpjChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    // Aplica a máscara em tempo real enquanto o usuário digita
    const maskedValue = maskCNPJ(e.target.value);
    setCnpj(maskedValue);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIsAuthenticating(true);

    // Simula a verificação no Protheus/Supabase
    setTimeout(() => {
      router.push('/dashboard');
    }, 1200);
  };

  return (
    <div className="min-h-screen bg-[#0f172a] text-slate-300 font-sans selection:bg-blue-500/30">
      {/* Background sutil */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-blue-600/5 blur-[100px] rounded-full" />
        <div className="absolute bottom-0 left-0 w-[500px] h-[500px] bg-indigo-600/5 blur-[100px] rounded-full" />
      </div>

      <div className="relative flex flex-col items-center justify-center min-h-screen px-6 py-12">
        {/* Logo e Header */}
        <header className="flex flex-col items-center gap-4 mb-12 text-center">
          <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center shadow-lg shadow-blue-900/20">
            <span className="text-white font-bold text-2xl">P</span>
          </div>
          <div>
            <h1 className="text-2xl font-bold text-white tracking-tight">Portal do Fornecedor</h1>
            <p className="text-[10px] text-slate-500 uppercase tracking-widest font-semibold mt-1">Protheus Engine • v1.0</p>
          </div>
        </header>

        {/* Card de Login */}
        <main className="w-full max-w-md bg-[#1e293b] border border-slate-700/50 p-8 rounded-2xl shadow-xl shadow-black/30">
          <div className="mb-8">
            <h2 className="text-xl font-bold text-white tracking-tight">Acessar sua conta</h2>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <FormInput
              id="cnpj"
              label="CNPJ do Fornecedor"
              type="text"
              placeholder="00.000.000/0000-00"
              value={cnpj}              // Valor do estado
              onChange={handleCnpjChange} // Função que mascara
            />

            <FormInput
              id="password"
              label="Senha de Acesso"
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e: any) => setPassword(e.target.value)}
            />

            <div className="flex items-center justify-between gap-4">
              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="remember"
                  className="w-4 h-4 rounded border border-slate-700 bg-[#0f172a] text-blue-600 focus:ring-blue-500/30"
                />
                <label htmlFor="remember" className="text-xs text-slate-400 cursor-pointer">
                  Lembrar dados
                </label>
              </div>
              <button type="button" className="text-blue-400 hover:text-blue-300 text-xs font-semibold transition-all">
                Esqueci a senha
              </button>
            </div>

            <button
              type="submit"
              disabled={isAuthenticating}
              className="w-full h-[52px] bg-blue-600 hover:bg-blue-500 disabled:bg-blue-800 disabled:cursor-not-allowed text-white text-sm font-bold rounded-xl shadow-lg shadow-blue-900/20 transition-all duration-200 flex items-center justify-center gap-3"
            >
              {isAuthenticating ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/20 border-t-white rounded-full animate-spin" />
                  <span>AUTENTICANDO...</span>
                </>
              ) : (
                "ACESSAR PORTAL"
              )}
            </button>
          </form>
        </main>

        <footer className="mt-12 text-center">
          <p className="text-[10px] text-slate-600 font-medium tracking-widest uppercase">
            Acesso integrado via TOTVS Protheus ERP
          </p>
        </footer>
      </div>
    </div>
  );
}