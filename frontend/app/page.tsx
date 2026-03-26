import { redirect } from 'next/navigation';

export default function RootPage() {
  // No futuro, aqui checaremos o cookie de sessão do Supabase.
  // Por enquanto, mandamos para o login para construir o fluxo.
  redirect('/login');
}