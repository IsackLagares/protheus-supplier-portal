export const maskCNPJ = (value: string) => {
  // 1. Remove tudo o que não é número
  const digits = value.replace(/\D/g, "");

  // 2. Limita a 14 números
  const limited = digits.slice(0, 14);

  // 3. Aplica a formatação progressiva
  return limited
    .replace(/^(\d{2})(\d)/, "$1.$2")           // 00.0
    .replace(/^(\d{2})\.(\d{3})(\d)/, "$1.$2.$3") // 00.000.0
    .replace(/\.(\d{3})(\d)/, ".$1/$2")         // 00.000.000/0
    .replace(/(\d{4})(\d)/, "$1-$2");           // 00.000.000/0000-00
};